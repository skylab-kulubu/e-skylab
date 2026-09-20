package com.skylab.nativehandoff;

import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.Test;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.events.EventBuilder;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.ClientModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.UserProvider;
import org.keycloak.services.managers.AuthenticationManager;
import org.keycloak.services.messages.Messages;
import org.keycloak.sessions.AuthenticationSessionModel;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.junit.jupiter.api.Assertions.assertNull;

class NativeHandoffAuthenticatorTest {

    @Test
    void isNotExposedAsAUserSelectableCredentialCategory() {
        NativeHandoffAuthenticatorFactory factory = new NativeHandoffAuthenticatorFactory();

        assertNull(factory.getReferenceCategory());
        assertArrayEquals(
                new AuthenticationExecutionModel.Requirement[] {
                        AuthenticationExecutionModel.Requirement.REQUIRED,
                        AuthenticationExecutionModel.Requirement.ALTERNATIVE,
                        AuthenticationExecutionModel.Requirement.DISABLED
                },
                factory.getRequirementChoices());
    }

    @Test
    void leavesNormalBrowserLoginUntouchedWhenNoHintExists() throws Exception {
        Fixture fixture = new Fixture();
        when(fixture.authenticationSession.getClientNote(NativeHandoffAuthenticator.HINT_NOTE))
                .thenReturn(null);

        fixture.authenticator.authenticate(fixture.context);

        verify(fixture.context).attempted();
        verify(fixture.context, never()).success();
        verify(fixture.redeemer, never()).redeem(org.mockito.ArgumentMatchers.anyString());
    }

    @Test
    void redeemsOnceSelectsOnlyTheSubjectAndPreservesAuthTime() throws Exception {
        Fixture fixture = new Fixture();
        String code = "A".repeat(43);
        UserModel user = mock(UserModel.class);
        when(fixture.authenticationSession.getClientNote(NativeHandoffAuthenticator.HINT_NOTE))
                .thenReturn(code);
        when(fixture.client.getClientId()).thenReturn("account-center");
        when(fixture.redeemer.redeem(code)).thenReturn(
                new NativeBridgeIdentity("user-id", "native-session", 1789904700));
        when(fixture.users.getUserById(fixture.realm, "user-id")).thenReturn(user);
        when(user.isEnabled()).thenReturn(true);

        fixture.authenticator.authenticate(fixture.context);

        verify(fixture.authenticationSession).removeClientNote(NativeHandoffAuthenticator.HINT_NOTE);
        verify(fixture.users).getUserById(fixture.realm, "user-id");
        verify(fixture.context).setUser(user);
        verify(fixture.authenticationSession).setClientNote(
                AuthenticationManager.AUTH_TIME_BROKER,
                "1789904700");
        verify(fixture.authenticationSession).setUserSessionNote(
                AuthenticationManager.AUTH_TIME,
                "1789904700");
        verify(fixture.context).success();
    }

    @Test
    void aPresentButInvalidOrUnknownHandoffNeverFallsBackToPassword() throws Exception {
        Fixture invalidCode = new Fixture();
        when(invalidCode.authenticationSession.getClientNote(NativeHandoffAuthenticator.HINT_NOTE))
                .thenReturn("invalid");
        when(invalidCode.client.getClientId()).thenReturn("account-center");

        invalidCode.authenticator.authenticate(invalidCode.context);

        verify(invalidCode.authenticationSession).removeClientNote(NativeHandoffAuthenticator.HINT_NOTE);
        verify(invalidCode.context).failureChallenge(
                AuthenticationFlowError.INVALID_CREDENTIALS,
                invalidCode.failureResponse);
        verify(invalidCode.context).setAuthenticationSelections(List.of());
        verify(invalidCode.context, never()).attempted();

        Fixture unknownUser = new Fixture();
        String code = "U".repeat(43);
        when(unknownUser.authenticationSession.getClientNote(NativeHandoffAuthenticator.HINT_NOTE))
                .thenReturn(code);
        when(unknownUser.client.getClientId()).thenReturn("account-center");
        when(unknownUser.redeemer.redeem(code)).thenReturn(
                new NativeBridgeIdentity("unknown-user", "native-session", 1789904700));
        when(unknownUser.users.getUserById(unknownUser.realm, "unknown-user")).thenReturn(null);

        unknownUser.authenticator.authenticate(unknownUser.context);

        verify(unknownUser.context).failureChallenge(
                AuthenticationFlowError.INVALID_CREDENTIALS,
                unknownUser.failureResponse);
        verify(unknownUser.context).setAuthenticationSelections(List.of());
        verify(unknownUser.context, never()).attempted();
        verify(unknownUser.context, never()).success();
    }

    private static final class Fixture {
        private final AuthenticationFlowContext context = mock(AuthenticationFlowContext.class);
        private final AuthenticationSessionModel authenticationSession = mock(AuthenticationSessionModel.class);
        private final ClientModel client = mock(ClientModel.class);
        private final KeycloakSession session = mock(KeycloakSession.class);
        private final UserProvider users = mock(UserProvider.class);
        private final RealmModel realm = mock(RealmModel.class);
        private final EventBuilder event = mock(EventBuilder.class);
        private final LoginFormsProvider form = mock(LoginFormsProvider.class);
        private final Response failureResponse = mock(Response.class);
        private final NativeBridgeRedeemer redeemer = mock(NativeBridgeRedeemer.class);
        private final NativeHandoffAuthenticator authenticator =
                new NativeHandoffAuthenticator(() -> redeemer);

        private Fixture() {
            when(context.getAuthenticationSession()).thenReturn(authenticationSession);
            when(authenticationSession.getClient()).thenReturn(client);
            when(context.getSession()).thenReturn(session);
            when(session.users()).thenReturn(users);
            when(context.getRealm()).thenReturn(realm);
            when(context.getEvent()).thenReturn(event);
            when(context.form()).thenReturn(form);
            when(form.setError(Messages.INVALID_USER)).thenReturn(form);
            when(form.createErrorPage(Response.Status.BAD_REQUEST)).thenReturn(failureResponse);
        }
    }
}
