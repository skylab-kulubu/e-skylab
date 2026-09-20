package com.skylab.passkey;

import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.Test;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.http.HttpRequest;
import org.keycloak.models.UserModel;
import org.keycloak.sessions.AuthenticationSessionModel;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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

    @Test
    void addsRegistrationOnlyToTheCurrentAuthenticationSession() {
        Fixture fixture = new Fixture("yes");

        fixture.authenticator.action(fixture.context);

        verify(fixture.authenticationSession)
                .addRequiredAction("webauthn-register-passwordless");
        verify(fixture.user, never()).addRequiredAction(anyString());
        verify(fixture.user).removeAttribute(PasskeyOfferAuthenticator.ATTR_DISMISSED_AT);
        verify(fixture.context).success();
    }

    @Test
    void dismissesTheOfferOnlyWhenTheUserExplicitlyChoosesThirtyDays() {
        Fixture fixture = new Fixture("no");

        fixture.authenticator.action(fixture.context);

        verify(fixture.user)
                .setSingleAttribute(
                        eq(PasskeyOfferAuthenticator.ATTR_DISMISSED_AT),
                        anyString());
        verify(fixture.authenticationSession, never()).addRequiredAction(anyString());
        verify(fixture.context).success();
    }

    @Test
    void rejectsMissingOrForgedChoicesWithoutStartingOrDismissingPasskeys() {
        Fixture fixture = new Fixture("unexpected");

        fixture.authenticator.action(fixture.context);

        verify(fixture.authenticationSession, never()).addRequiredAction(anyString());
        verify(fixture.user, never()).setSingleAttribute(anyString(), anyString());
        verify(fixture.context).challenge(fixture.challenge);
        verify(fixture.context, never()).success();
    }

    private static final class Fixture {
        private final PasskeyOfferAuthenticator authenticator = new PasskeyOfferAuthenticator();
        private final AuthenticationFlowContext context = mock(AuthenticationFlowContext.class);
        private final AuthenticationSessionModel authenticationSession = mock(AuthenticationSessionModel.class);
        private final UserModel user = mock(UserModel.class);
        private final HttpRequest request = mock(HttpRequest.class);
        private final LoginFormsProvider form = mock(LoginFormsProvider.class);
        private final Response challenge = mock(Response.class);

        private Fixture(String choice) {
            MultivaluedHashMap<String, String> parameters = new MultivaluedHashMap<>();
            parameters.putSingle("passkey-choice", choice);
            when(context.getUser()).thenReturn(user);
            when(context.getAuthenticationSession()).thenReturn(authenticationSession);
            when(context.getHttpRequest()).thenReturn(request);
            when(request.getDecodedFormParameters()).thenReturn(parameters);
            when(context.form()).thenReturn(form);
            when(form.setError(anyString())).thenReturn(form);
            when(form.createForm("passkey-offer.ftl")).thenReturn(challenge);
        }
    }
}
