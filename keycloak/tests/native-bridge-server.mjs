import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import { readFileSync } from "node:fs";
import { createServer } from "node:https";

const redemptionPath = "/internal/v1/native-handoff/redeem";
const maximumBodyBytes = 256;
const expectedClientFingerprint = required("NATIVE_BRIDGE_CLIENT_SHA256");
const hmacSecret = decodeSecret(required("NATIVE_BRIDGE_HMAC_SECRET"));
const authTime = parsePositiveInteger(required("NATIVE_BRIDGE_AUTH_TIME"));
const port = parsePositiveInteger(process.env.NATIVE_BRIDGE_PORT ?? "8443");
const consumedCodes = new Set();
const seenNonces = new Map();

const identities = new Map([
  ["A".repeat(43), {
    sub: "11111111-1111-4111-8111-111111111111",
    sid: "native-session-enabled",
    auth_time: authTime,
  }],
  ["U".repeat(43), {
    sub: "33333333-3333-4333-8333-333333333333",
    sid: "native-session-unknown",
    auth_time: authTime,
  }],
  ["D".repeat(43), {
    sub: "22222222-2222-4222-8222-222222222222",
    sid: "native-session-disabled",
    auth_time: authTime,
  }],
]);

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function parsePositiveInteger(value) {
  if (!/^[1-9][0-9]*$/.test(value)) {
    throw new Error("Expected a positive integer.");
  }
  return Number.parseInt(value, 10);
}

function decodeSecret(value) {
  if (!/^[A-Za-z0-9+/_-]+={0,2}$/.test(value)) {
    throw new Error("Native bridge HMAC secret is not base64.");
  }
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const decoded = Buffer.from(normalized, "base64");
  if (decoded.byteLength < 32) {
    throw new Error("Native bridge HMAC secret is too short.");
  }
  return decoded;
}

function headerValues(request, wantedName) {
  const values = [];
  for (let index = 0; index < request.rawHeaders.length; index += 2) {
    if (request.rawHeaders[index].toLowerCase() === wantedName) {
      values.push(request.rawHeaders[index + 1]);
    }
  }
  return values;
}

function decodeCanonicalBase64Url(value, minimumBytes, maximumBytes) {
  if (!/^[A-Za-z0-9_-]+$/.test(value)) {
    return null;
  }
  const decoded = Buffer.from(value.replaceAll("-", "+").replaceAll("_", "/"), "base64");
  if (decoded.byteLength < minimumBytes || decoded.byteLength > maximumBytes ||
      decoded.toString("base64url") !== value) {
    return null;
  }
  return decoded;
}

function reject(response, reason, status = 400) {
  process.stderr.write(`Native bridge fixture rejected a request: ${reason}.\n`);
  response.writeHead(status, {
    "content-type": "application/json",
    "cache-control": "no-store",
  });
  response.end('{"error":"invalid_request"}');
}

function equalText(left, right) {
  const leftBytes = Buffer.from(left);
  const rightBytes = Buffer.from(right);
  return leftBytes.byteLength === rightBytes.byteLength && timingSafeEqual(leftBytes, rightBytes);
}

function verifyClientCertificate(request) {
  const certificate = request.socket.getPeerCertificate(true);
  if (!certificate?.raw) {
    return false;
  }
  const fingerprint = createHash("sha256").update(certificate.raw).digest("hex");
  return /^[a-f0-9]{64}$/.test(expectedClientFingerprint) &&
    equalText(fingerprint, expectedClientFingerprint);
}

function verifySignedRequest(request, body) {
  const timestampHeaders = headerValues(request, "x-sky-timestamp");
  const nonceHeaders = headerValues(request, "x-sky-nonce");
  const signatureHeaders = headerValues(request, "x-sky-signature");
  if (timestampHeaders.length !== 1 || nonceHeaders.length !== 1 || signatureHeaders.length !== 1) {
    return false;
  }

  const timestamp = timestampHeaders[0];
  const nonce = nonceHeaders[0];
  const signature = signatureHeaders[0];
  if (!/^[0-9]{10}$/.test(timestamp) ||
      Math.abs(Math.floor(Date.now() / 1000) - Number.parseInt(timestamp, 10)) > 30 ||
      decodeCanonicalBase64Url(nonce, 16, 64) === null ||
      decodeCanonicalBase64Url(signature, 32, 32) === null) {
    return false;
  }

  const now = Date.now();
  for (const [candidate, expiry] of seenNonces) {
    if (expiry <= now) {
      seenNonces.delete(candidate);
    }
  }
  const nonceDigest = createHash("sha256").update(nonce).digest("hex");
  if (seenNonces.has(nonceDigest)) {
    return false;
  }

  const bodyDigest = createHash("sha256").update(body).digest("base64url");
  const payload = `v1\nPOST\n${redemptionPath}\n${timestamp}\n${nonce}\n${bodyDigest}`;
  const expected = createHmac("sha256", hmacSecret).update(payload).digest("base64url");
  if (!equalText(signature, expected)) {
    return false;
  }

  seenNonces.set(nonceDigest, now + 60_000);
  return true;
}

const server = createServer({
  key: readFileSync(required("NATIVE_BRIDGE_TLS_KEY_FILE")),
  cert: readFileSync(required("NATIVE_BRIDGE_TLS_CERT_FILE")),
  ca: readFileSync(required("NATIVE_BRIDGE_CA_CERT_FILE")),
  requestCert: true,
  rejectUnauthorized: true,
  minVersion: "TLSv1.2",
}, (request, response) => {
  if (request.method !== "POST" || request.url !== redemptionPath ||
      request.headers["content-type"] !== "application/json" ||
      !verifyClientCertificate(request)) {
    reject(response, "request metadata or client certificate");
    return;
  }

  const chunks = [];
  let bodyBytes = 0;
  request.on("data", (chunk) => {
    bodyBytes += chunk.byteLength;
    if (bodyBytes > maximumBodyBytes) {
      request.destroy();
      return;
    }
    chunks.push(chunk);
  });
  request.on("end", () => {
    if (bodyBytes > maximumBodyBytes) {
      return;
    }
    const body = Buffer.concat(chunks);
    const match = /^\{"code":"([A-Za-z0-9_-]{43})"\}$/.exec(body.toString("utf8"));
    if (!match || !verifySignedRequest(request, body)) {
      reject(response, "body or request signature");
      return;
    }

    const code = match[1];
    const identity = identities.get(code);
    if (!identity || consumedCodes.has(code)) {
      reject(response, "unknown or consumed bridge code");
      return;
    }
    consumedCodes.add(code);
    process.stdout.write("Native bridge fixture redeemed a request.\n");

    response.writeHead(200, {
      "content-type": "application/json",
      "cache-control": "no-store",
    });
    response.end(JSON.stringify(identity));
  });
});

server.listen(port, "0.0.0.0", () => {
  process.stdout.write("Native bridge fixture is ready.\n");
});
