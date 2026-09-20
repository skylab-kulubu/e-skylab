package com.skylab.nativehandoff;

import com.fasterxml.jackson.databind.JsonNode;
import org.keycloak.util.JsonSerialization;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.SecureRandom;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Clock;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class NativeBridgeClient implements NativeBridgeRedeemer {

    static final String REDEMPTION_PATH = "/internal/v1/native-handoff/redeem";
    static final String URL_ENV = "SKY_NATIVE_BRIDGE_REDEEM_URL";
    static final String HMAC_SECRET_ENV = "SKY_NATIVE_BRIDGE_HMAC_SECRET";
    static final String CLIENT_CERT_ENV = "SKY_NATIVE_BRIDGE_TLS_CERT_FILE";
    static final String CLIENT_KEY_ENV = "SKY_NATIVE_BRIDGE_TLS_KEY_FILE";
    static final String CA_CERT_ENV = "SKY_NATIVE_BRIDGE_CA_CERT_FILE";
    static final String TIMEOUT_ENV = "SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS";

    private static final Pattern OPAQUE_CODE = Pattern.compile("^[A-Za-z0-9_-]{43}$");
    private static final Pattern PKCS8_PRIVATE_KEY = Pattern.compile(
            "^\\s*-----BEGIN PRIVATE KEY-----\\s*(.*?)\\s*-----END PRIVATE KEY-----\\s*$",
            Pattern.DOTALL);
    private static final int MAX_RESPONSE_BYTES = 1_024;
    private static final int NONCE_BYTES = 24;

    private final URI endpoint;
    private final byte[] hmacSecret;
    private final Duration timeout;
    private final HttpClient httpClient;
    private final Clock clock;
    private final SecureRandom random;

    private NativeBridgeClient(
            URI endpoint,
            byte[] hmacSecret,
            Duration timeout,
            HttpClient httpClient,
            Clock clock,
            SecureRandom random) {
        this.endpoint = endpoint;
        this.hmacSecret = hmacSecret.clone();
        this.timeout = timeout;
        this.httpClient = httpClient;
        this.clock = clock;
        this.random = random;
    }

    static NativeBridgeClient fromEnvironment() {
        return fromEnvironment(System.getenv());
    }

    static NativeBridgeClient fromEnvironment(Map<String, String> environment) {
        URI endpoint = parseEndpoint(required(environment, URL_ENV));
        byte[] secret = decodeSecret(required(environment, HMAC_SECRET_ENV));
        Path clientCertificate = absoluteReadableFile(
                required(environment, CLIENT_CERT_ENV),
                CLIENT_CERT_ENV);
        Path clientKey = absoluteReadableFile(
                required(environment, CLIENT_KEY_ENV),
                CLIENT_KEY_ENV);
        Path caCertificate = absoluteReadableFile(
                required(environment, CA_CERT_ENV),
                CA_CERT_ENV);
        Duration timeout = Duration.ofMillis(parseTimeout(environment.get(TIMEOUT_ENV)));
        SSLContext sslContext = createSslContext(clientCertificate, clientKey, caCertificate);
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(timeout)
                .followRedirects(HttpClient.Redirect.NEVER)
                .sslContext(sslContext)
                .build();
        return new NativeBridgeClient(
                endpoint,
                secret,
                timeout,
                httpClient,
                Clock.systemUTC(),
                new SecureRandom());
    }

    @Override
    public NativeBridgeIdentity redeem(String bridgeCode) throws Exception {
        if (!OPAQUE_CODE.matcher(bridgeCode).matches()) {
            throw new IllegalArgumentException("Invalid native bridge code.");
        }

        String body = "{\"code\":\"" + bridgeCode + "\"}";
        String timestamp = String.valueOf(clock.instant().getEpochSecond());
        byte[] nonceBytes = new byte[NONCE_BYTES];
        random.nextBytes(nonceBytes);
        String nonce = Base64.getUrlEncoder().withoutPadding().encodeToString(nonceBytes);
        String signature = sign(hmacSecret, body, timestamp, nonce);

        HttpRequest request = HttpRequest.newBuilder(endpoint)
                .timeout(timeout)
                .header("Accept", "application/json")
                .header("Content-Type", "application/json")
                .header("X-Sky-Timestamp", timestamp)
                .header("X-Sky-Nonce", nonce)
                .header("X-Sky-Signature", signature)
                .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                .build();
        HttpResponse<InputStream> response = httpClient.send(
                request,
                HttpResponse.BodyHandlers.ofInputStream());
        try (InputStream responseBody = response.body()) {
            byte[] bytes = responseBody.readNBytes(MAX_RESPONSE_BYTES + 1);
            if (bytes.length > MAX_RESPONSE_BYTES || response.statusCode() != 200) {
                throw new IOException("Native bridge redemption was rejected.");
            }
            String contentType = response.headers().firstValue("content-type").orElse("");
            if (!contentType.toLowerCase().startsWith("application/json")) {
                throw new IOException("Native bridge returned an invalid media type.");
            }
            return parseResponse(new String(bytes, StandardCharsets.UTF_8), clock.instant().getEpochSecond());
        }
    }

    static String sign(byte[] secret, String body, String timestamp, String nonce) {
        try {
            String bodyDigest = Base64.getUrlEncoder().withoutPadding().encodeToString(
                    MessageDigest.getInstance("SHA-256").digest(body.getBytes(StandardCharsets.UTF_8)));
            String payload = "v1\nPOST\n" + REDEMPTION_PATH + "\n" + timestamp + "\n" + nonce + "\n" + bodyDigest;
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(
                    mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Native bridge request signing failed.", exception);
        }
    }

    static NativeBridgeIdentity parseResponse(String responseBody, long nowEpochSeconds)
            throws IOException {
        JsonNode root = JsonSerialization.mapper.readTree(responseBody);
        if (!root.isObject() || root.size() != 3 ||
                !root.has("sub") || !root.has("sid") || !root.has("auth_time")) {
            throw new IOException("Native bridge returned an invalid response.");
        }
        JsonNode subjectNode = root.get("sub");
        JsonNode sessionNode = root.get("sid");
        JsonNode authTimeNode = root.get("auth_time");
        if (!subjectNode.isTextual() || !sessionNode.isTextual() || !authTimeNode.isIntegralNumber()) {
            throw new IOException("Native bridge returned invalid claim types.");
        }
        String subject = subjectNode.textValue();
        String sessionId = sessionNode.textValue();
        long authenticatedAt = authTimeNode.longValue();
        if (subject.isBlank() || subject.length() > 255 ||
                sessionId.isBlank() || sessionId.length() > 255 ||
                authenticatedAt <= 0 || authenticatedAt > Integer.MAX_VALUE ||
                authenticatedAt > nowEpochSeconds + 30) {
            throw new IOException("Native bridge returned invalid claim values.");
        }
        return new NativeBridgeIdentity(subject, sessionId, (int) authenticatedAt);
    }

    static URI parseEndpoint(String value) {
        final URI endpoint;
        try {
            endpoint = URI.create(value);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(URL_ENV + " must be a valid HTTPS URL.", exception);
        }
        if (!"https".equals(endpoint.getScheme()) || endpoint.getHost() == null ||
                endpoint.getUserInfo() != null || endpoint.getQuery() != null ||
                endpoint.getFragment() != null || !REDEMPTION_PATH.equals(endpoint.getPath())) {
            throw new IllegalStateException(
                    URL_ENV + " must be an exact credential-free HTTPS redemption URL.");
        }
        return endpoint;
    }

    private static String required(Map<String, String> environment, String name) {
        String value = environment.get(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Missing required environment variable: " + name);
        }
        return value.trim();
    }

    private static byte[] decodeSecret(String value) {
        if (!value.matches("^[A-Za-z0-9+/_-]+={0,2}$")) {
            throw new IllegalStateException(HMAC_SECRET_ENV + " must be base64 encoded.");
        }
        String normalized = value.replace('-', '+').replace('_', '/');
        normalized += "=".repeat((4 - normalized.length() % 4) % 4);
        final byte[] decoded;
        try {
            decoded = Base64.getDecoder().decode(normalized);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(HMAC_SECRET_ENV + " must be base64 encoded.", exception);
        }
        if (decoded.length < 32) {
            throw new IllegalStateException(HMAC_SECRET_ENV + " must decode to at least 32 bytes.");
        }
        return decoded;
    }

    private static long parseTimeout(String value) {
        String effective = value == null || value.isBlank() ? "1500" : value.trim();
        try {
            long parsed = Long.parseLong(effective);
            if (parsed < 100 || parsed > 5_000) {
                throw new NumberFormatException();
            }
            return parsed;
        } catch (NumberFormatException exception) {
            throw new IllegalStateException(TIMEOUT_ENV + " must be an integer from 100 through 5000.");
        }
    }

    private static Path absoluteReadableFile(String value, String name) {
        Path path = Path.of(value);
        if (!path.isAbsolute() || !Files.isRegularFile(path) || !Files.isReadable(path)) {
            throw new IllegalStateException(name + " must point to a readable absolute file.");
        }
        return path;
    }

    private static SSLContext createSslContext(
            Path clientCertificateFile,
            Path clientKeyFile,
            Path caCertificateFile) {
        try {
            List<X509Certificate> clientCertificates = readCertificates(clientCertificateFile);
            List<X509Certificate> caCertificates = readCertificates(caCertificateFile);
            PrivateKey privateKey = readPrivateKey(
                    clientKeyFile,
                    clientCertificates.getFirst().getPublicKey().getAlgorithm());

            char[] password = new char[0];
            KeyStore clientKeys = KeyStore.getInstance("PKCS12");
            clientKeys.load(null, password);
            clientKeys.setKeyEntry(
                    "native-bridge-client",
                    privateKey,
                    password,
                    clientCertificates.toArray(Certificate[]::new));
            KeyManagerFactory keyManagers = KeyManagerFactory.getInstance(
                    KeyManagerFactory.getDefaultAlgorithm());
            keyManagers.init(clientKeys, password);

            KeyStore trustedRoots = KeyStore.getInstance(KeyStore.getDefaultType());
            trustedRoots.load(null, null);
            for (int index = 0; index < caCertificates.size(); index++) {
                trustedRoots.setCertificateEntry("native-bridge-ca-" + index, caCertificates.get(index));
            }
            TrustManagerFactory trustManagers = TrustManagerFactory.getInstance(
                    TrustManagerFactory.getDefaultAlgorithm());
            trustManagers.init(trustedRoots);

            SSLContext sslContext = SSLContext.getInstance("TLS");
            sslContext.init(keyManagers.getKeyManagers(), trustManagers.getTrustManagers(), null);
            return sslContext;
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "Native bridge mTLS files are invalid or the private key does not match the certificate.",
                    exception);
        }
    }

    private static List<X509Certificate> readCertificates(Path path) throws Exception {
        CertificateFactory factory = CertificateFactory.getInstance("X.509");
        Collection<? extends Certificate> parsed;
        try (InputStream input = Files.newInputStream(path)) {
            parsed = factory.generateCertificates(input);
        }
        List<X509Certificate> certificates = new ArrayList<>();
        for (Certificate certificate : parsed) {
            if (certificate instanceof X509Certificate x509Certificate) {
                certificates.add(x509Certificate);
            }
        }
        if (certificates.isEmpty()) {
            throw new IllegalArgumentException("Certificate file is empty.");
        }
        return certificates;
    }

    private static PrivateKey readPrivateKey(Path path, String algorithm) throws Exception {
        String pem = Files.readString(path, StandardCharsets.US_ASCII);
        Matcher matcher = PKCS8_PRIVATE_KEY.matcher(pem);
        if (!matcher.matches()) {
            throw new IllegalArgumentException("Client key must be an unencrypted PKCS#8 PEM private key.");
        }
        byte[] encoded = Base64.getMimeDecoder().decode(matcher.group(1));
        return KeyFactory.getInstance(algorithm).generatePrivate(new PKCS8EncodedKeySpec(encoded));
    }
}
