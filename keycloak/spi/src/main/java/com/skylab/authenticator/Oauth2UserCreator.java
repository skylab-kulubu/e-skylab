package com.skylab.authenticator;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

final class Oauth2UserCreator implements Authenticator {

    private static final Logger LOG = Logger.getLogger(Oauth2UserCreator.class);
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final int MAX_RETRIES = 3;
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(5);

    private final HttpClient httpClient;

    Oauth2UserCreator(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        Object brokerObject = context.getAuthenticationSession().getAuthNote("BROKERED_CONTEXT");
        if (brokerObject == null) {
            LOG.error("Brokered context is missing during OAuth2 user creation");
            context.failure(AuthenticationFlowError.INTERNAL_ERROR);
            return;
        }

        try {
            Map<String, Object> broker = OBJECT_MAPPER.readValue(
                    brokerObject.toString(),
                    new TypeReference<>() { }
            );
            String email = requiredString(broker, "email");
            String username = requiredString(broker, "modelUsername");
            String firstName = optionalString(broker, "firstName", "Unknown");
            String lastName = optionalString(broker, "lastName", "Unknown");

            if (context.getAuthenticatorConfig() == null) {
                throw new IllegalStateException("Authenticator configuration is missing");
            }
            String apiUrl = context.getAuthenticatorConfig().getConfig()
                    .get(Oauth2UserCreatorFactory.API_URL_PROPERTY);
            if (apiUrl == null || apiUrl.isBlank()) {
                throw new IllegalStateException("Core OAuth2 registration URL is missing");
            }

            Map<String, Object> response = callApiWithRetry(apiUrl, username, firstName, lastName, email);
            Object skyNumber = response.get("ldapSkyNumber");
            if (skyNumber instanceof String value && !value.isBlank()) {
                context.getAuthenticationSession().setUserSessionNote("employeeNumber", value);
            }

            UserModel user = context.getSession().users().getUserByEmail(context.getRealm(), email);
            if (user == null) {
                user = context.getSession().users().getUserByUsername(context.getRealm(), username);
            }
            if (user == null) {
                throw new IllegalStateException("Provisioned user is not visible in Keycloak");
            }

            context.setUser(user);
            context.success();
        } catch (Exception exception) {
            LOG.error("OAuth2 user creation failed", exception);
            context.failure(
                    AuthenticationFlowError.INTERNAL_ERROR,
                    context.form()
                            .setError("Hesap hazırlanamadı. Lütfen daha sonra tekrar dene.")
                            .createErrorPage(Response.Status.INTERNAL_SERVER_ERROR)
            );
        }
    }

    private Map<String, Object> callApiWithRetry(
            String apiUrl,
            String username,
            String firstName,
            String lastName,
            String email
    ) throws Exception {
        Exception lastException = null;

        for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
            try {
                Map<String, String> body = new HashMap<>();
                body.put("username", username);
                body.put("firstName", firstName);
                body.put("lastName", lastName);
                body.put("email", email);

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(apiUrl))
                        .timeout(REQUEST_TIMEOUT)
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(OBJECT_MAPPER.writeValueAsString(body)))
                        .build();
                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

                if (response.statusCode() >= 200 && response.statusCode() < 300) {
                    return OBJECT_MAPPER.readValue(response.body(), new TypeReference<>() { });
                }
                if (response.statusCode() == 400
                        && response.body() != null
                        && response.body().contains("LDAP username already exists")) {
                    return Map.of();
                }
                throw new IllegalStateException("Core registration returned HTTP " + response.statusCode());
            } catch (Exception exception) {
                lastException = exception;
                LOG.warnf("Core registration attempt %d/%d failed", attempt, MAX_RETRIES);
            }
        }

        throw new IllegalStateException("Core registration failed after retries", lastException);
    }

    private static String requiredString(Map<String, Object> values, String key) {
        Object value = values.get(key);
        if (!(value instanceof String text) || text.isBlank()) {
            throw new IllegalArgumentException(key + " is required");
        }
        return text;
    }

    private static String optionalString(Map<String, Object> values, String key, String fallback) {
        Object value = values.get(key);
        return value instanceof String text && !text.isBlank() ? text : fallback;
    }

    @Override
    public boolean requiresUser() {
        return false;
    }

    @Override
    public boolean configuredFor(KeycloakSession session, RealmModel realm, UserModel user) {
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {
        // no-op
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // no-op
    }

    @Override
    public void close() {
        // no-op
    }
}

