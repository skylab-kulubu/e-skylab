package com.skylab.nativehandoff;

import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

import java.util.List;

public final class NativeHandoffAuthenticatorFactory implements AuthenticatorFactory {

    public static final String PROVIDER_ID = "sky-native-handoff";

    private volatile NativeBridgeRedeemer redeemer;

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public String getDisplayType() {
        return "SKY Native Handoff";
    }

    @Override
    public String getHelpText() {
        return "Redeems a one-time native handoff over the protected Account Center bridge.";
    }

    @Override
    public String getReferenceCategory() {
        // This is a silent routing authenticator, not a user-selectable credential.
        // Returning a category makes Keycloak's ALTERNATIVE selection resolver
        // substitute another credential execution before authenticate() is called.
        return null;
    }

    @Override
    public boolean isConfigurable() {
        return false;
    }

    @Override
    public boolean isUserSetupAllowed() {
        return false;
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return new AuthenticationExecutionModel.Requirement[] {
                AuthenticationExecutionModel.Requirement.REQUIRED,
                AuthenticationExecutionModel.Requirement.ALTERNATIVE,
                AuthenticationExecutionModel.Requirement.DISABLED
        };
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return List.of();
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return new NativeHandoffAuthenticator(this::redeemer);
    }

    private NativeBridgeRedeemer redeemer() {
        NativeBridgeRedeemer current = redeemer;
        if (current != null) {
            return current;
        }
        synchronized (this) {
            if (redeemer == null) {
                redeemer = NativeBridgeClient.fromEnvironment();
            }
            return redeemer;
        }
    }

    @Override
    public void init(Config.Scope config) {
        // Runtime secrets are loaded lazily. Keycloak's optimized image build must not need them.
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // no-op
    }

    @Override
    public void close() {
        redeemer = null;
    }
}
