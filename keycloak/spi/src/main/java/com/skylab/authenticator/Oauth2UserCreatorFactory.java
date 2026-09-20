package com.skylab.authenticator;

import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.List;

public final class Oauth2UserCreatorFactory implements AuthenticatorFactory {

    public static final String PROVIDER_ID = "oauth2-user-creator";
    public static final String API_URL_PROPERTY = "superSkyLabApiUrl";

    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .version(HttpClient.Version.HTTP_1_1)
            .connectTimeout(Duration.ofSeconds(3))
            .build();

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public String getDisplayType() {
        return "OAuth2 Core User Creator";
    }

    @Override
    public String getHelpText() {
        return "Creates the corresponding Core/LDAP user during brokered login.";
    }

    @Override
    public boolean isConfigurable() {
        return true;
    }

    @Override
    public String getReferenceCategory() {
        return "oauth2";
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return new AuthenticationExecutionModel.Requirement[] {
                AuthenticationExecutionModel.Requirement.REQUIRED,
                AuthenticationExecutionModel.Requirement.DISABLED
        };
    }

    @Override
    public boolean isUserSetupAllowed() {
        return false;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return List.of(new ProviderConfigProperty(
                API_URL_PROPERTY,
                "Core OAuth2 registration URL",
                "Full URL of the internal OAuth2 registration endpoint.",
                ProviderConfigProperty.STRING_TYPE,
                null
        ));
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return new Oauth2UserCreator(HTTP_CLIENT);
    }

    @Override
    public void init(Config.Scope config) {
        // no-op
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // no-op
    }

    @Override
    public void close() {
        // no-op
    }
}

