package com.skylab.nativehandoff;

import jakarta.ws.rs.core.Response;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.authentication.Authenticator;
import org.keycloak.events.Errors;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.protocol.oidc.endpoints.AuthorizationEndpoint;
import org.keycloak.services.managers.AuthenticationManager;
import org.keycloak.services.messages.Messages;

import java.util.List;
import java.util.function.Supplier;
import java.util.regex.Pattern;

final class NativeHandoffAuthenticator implements Authenticator {

    static final String ACCOUNT_CENTER_CLIENT_ID = "account-center";
    static final String PARAMETER_NAME = "sky_native_handoff";
    static final String HINT_NOTE =
            AuthorizationEndpoint.LOGIN_SESSION_NOTE_ADDITIONAL_REQ_PARAMS_PREFIX + PARAMETER_NAME;

    private static final Pattern OPAQUE_CODE = Pattern.compile("^[A-Za-z0-9_-]{43}$");

    private final Supplier<NativeBridgeRedeemer> redeemer;

    NativeHandoffAuthenticator(Supplier<NativeBridgeRedeemer> redeemer) {
        this.redeemer = redeemer;
    }

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        String bridgeCode = context.getAuthenticationSession().getClientNote(HINT_NOTE);
        if (bridgeCode == null) {
            context.attempted();
            return;
        }

        context.getAuthenticationSession().removeClientNote(HINT_NOTE);
        try {
            String clientId = context.getAuthenticationSession().getClient().getClientId();
            if (!ACCOUNT_CENTER_CLIENT_ID.equals(clientId) ||
                    !OPAQUE_CODE.matcher(bridgeCode).matches()) {
                fail(context);
                return;
            }

            NativeBridgeIdentity identity = redeemer.get().redeem(bridgeCode);
            UserModel user = context.getSession().users().getUserById(
                    context.getRealm(),
                    identity.subject());
            if (user == null || !user.isEnabled()) {
                fail(context);
                return;
            }

            String authTime = String.valueOf(identity.authenticatedAt());
            context.setUser(user);
            context.getEvent().user(user);
            context.getAuthenticationSession().setClientNote(
                    AuthenticationManager.AUTH_TIME_BROKER,
                    authTime);
            context.getAuthenticationSession().setUserSessionNote(
                    AuthenticationManager.AUTH_TIME,
                    authTime);
            context.success();
        } catch (Exception ignored) {
            fail(context);
        }
    }

    private static void fail(AuthenticationFlowContext context) {
        context.clearUser();
        context.setAuthenticationSelections(List.of());
        context.getEvent().error(Errors.INVALID_USER_CREDENTIALS);
        Response challenge = context.form()
                .setError(Messages.INVALID_USER)
                .createErrorPage(Response.Status.BAD_REQUEST);
        context.failureChallenge(AuthenticationFlowError.INVALID_CREDENTIALS, challenge);
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        fail(context);
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
    public void close() {
        // no-op
    }
}
