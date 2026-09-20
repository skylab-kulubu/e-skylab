package com.skylab.passkey;

import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

import java.time.Duration;

final class PasskeyOfferAuthenticator implements Authenticator {

    static final String ACCOUNT_CENTER_CLIENT_ID = "account-center";
    static final String KC_ACTION_NOTE = "kc_action";
    static final String ATTR_DISMISSED_AT = "passkey_offer_dismissed_at";
    static final long REASK_INTERVAL_MILLIS = Duration.ofDays(30).toMillis();

    private static final Logger LOG = Logger.getLogger(PasskeyOfferAuthenticator.class);
    private static final String FORM_TEMPLATE = "passkey-offer.ftl";
    private static final String CHOICE_PARAM = "passkey-choice";
    private static final String REQUIRED_ACTION_WEBAUTHN_REGISTER_PASSWORDLESS =
            "webauthn-register-passwordless";
    private static final String CREDENTIAL_TYPE_WEBAUTHN_PASSWORDLESS =
            "webauthn-passwordless";

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        String clientId = context.getAuthenticationSession().getClient().getClientId();
        String kcAction = context.getAuthenticationSession().getClientNote(KC_ACTION_NOTE);
        if (skipForRequest(clientId, kcAction)) {
            context.success();
            return;
        }

        UserModel user = context.getUser();
        if (user == null || shouldSkip(user)) {
            context.success();
            return;
        }

        Response challenge = context.form().createForm(FORM_TEMPLATE);
        context.challenge(challenge);
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        UserModel user = context.getUser();
        if (user == null) {
            LOG.warn("Passkey offer action did not have an authenticated user");
            context.success();
            return;
        }

        MultivaluedMap<String, String> form = context.getHttpRequest().getDecodedFormParameters();
        if ("yes".equalsIgnoreCase(form.getFirst(CHOICE_PARAM))) {
            user.removeAttribute(ATTR_DISMISSED_AT);
            user.addRequiredAction(REQUIRED_ACTION_WEBAUTHN_REGISTER_PASSWORDLESS);
        } else {
            user.setSingleAttribute(ATTR_DISMISSED_AT, String.valueOf(System.currentTimeMillis()));
        }
        context.success();
    }

    static boolean skipForRequest(String clientId, String kcAction) {
        return ACCOUNT_CENTER_CLIENT_ID.equals(clientId) || (kcAction != null && !kcAction.isBlank());
    }

    private boolean shouldSkip(UserModel user) {
        if (user.credentialManager()
                .getStoredCredentialsByTypeStream(CREDENTIAL_TYPE_WEBAUTHN_PASSWORDLESS)
                .findAny()
                .isPresent()) {
            return true;
        }

        String dismissedAt = user.getFirstAttribute(ATTR_DISMISSED_AT);
        if (dismissedAt == null || dismissedAt.isBlank()) {
            return false;
        }
        try {
            return System.currentTimeMillis() - Long.parseLong(dismissedAt) < REASK_INTERVAL_MILLIS;
        } catch (NumberFormatException ignored) {
            return false;
        }
    }

    @Override
    public boolean requiresUser() {
        return true;
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
    public void close() {
        // no-op
    }
}

