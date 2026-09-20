package com.skylab.passkey;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PasskeyOfferAuthenticatorTest {

    @Test
    void skipsAccountCenterLogin() {
        assertTrue(PasskeyOfferAuthenticator.skipForRequest("account-center", null));
    }

    @Test
    void skipsApplicationInitiatedActions() {
        assertTrue(PasskeyOfferAuthenticator.skipForRequest("another-client", "UPDATE_PASSWORD"));
    }

    @Test
    void keepsExistingLoginBehaviorForOtherClients() {
        assertFalse(PasskeyOfferAuthenticator.skipForRequest("skyapp", null));
    }
}

