package com.skylab.nativehandoff;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class NativeBridgeClientTest {

    @Test
    void signsTheExactAccountCenterContract() {
        byte[] secret = new byte[32];
        Arrays.fill(secret, (byte) 1);
        String body = "{\"code\":\"" + "A".repeat(43) + "\"}";

        String signature = NativeBridgeClient.sign(
                secret,
                body,
                "1789904700",
                "AQEBAQEBAQEBAQEBAQEBAQ");

        assertEquals("oWvPN0lW8hVdboAa21JbT0PMCTzcZQ2FfF3-kjvhawU", signature);
        assertEquals(32, secret.length);
        assertEquals(54, body.getBytes(StandardCharsets.UTF_8).length);
    }

    @Test
    void acceptsOnlyTheMinimalBoundedRedemptionResponse() throws Exception {
        NativeBridgeIdentity identity = NativeBridgeClient.parseResponse(
                "{\"sub\":\"user-id\",\"sid\":\"native-session\",\"auth_time\":1789904700}",
                1789904701L);

        assertEquals("user-id", identity.subject());
        assertEquals("native-session", identity.sessionId());
        assertEquals(1789904700, identity.authenticatedAt());

        assertThrows(IOException.class, () -> NativeBridgeClient.parseResponse(
                "{\"sub\":\"user-id\",\"sid\":\"native-session\",\"auth_time\":1789904700,\"email\":\"leak@example.invalid\"}",
                1789904701L));
        assertThrows(IOException.class, () -> NativeBridgeClient.parseResponse(
                "{\"sub\":\"user-id\",\"sid\":\"native-session\",\"auth_time\":1789904800}",
                1789904701L));
    }

    @Test
    void acceptsOnlyTheExactInternalHttpsEndpoint() {
        assertEquals(
                "native-bridge",
                NativeBridgeClient.parseEndpoint(
                        "https://native-bridge/internal/v1/native-handoff/redeem").getHost());
        assertThrows(IllegalStateException.class, () -> NativeBridgeClient.parseEndpoint(
                "http://native-bridge/internal/v1/native-handoff/redeem"));
        assertThrows(IllegalStateException.class, () -> NativeBridgeClient.parseEndpoint(
                "https://native-bridge/internal/v1/native-handoff/redeem?code=leak"));
        assertThrows(IllegalStateException.class, () -> NativeBridgeClient.parseEndpoint(
                "https://native-bridge/other"));
    }
}
