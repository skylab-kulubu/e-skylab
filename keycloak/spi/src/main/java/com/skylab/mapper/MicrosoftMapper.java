package com.skylab.mapper;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jboss.logging.Logger;
import org.keycloak.broker.provider.AbstractIdentityProviderMapper;
import org.keycloak.broker.provider.BrokeredIdentityContext;
import org.keycloak.models.IdentityProviderMapperModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.provider.ProviderConfigProperty;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;

public final class MicrosoftMapper extends AbstractIdentityProviderMapper {

    public static final String PROVIDER_ID = "microsoft-department-mapper";
    private static final Logger LOG = Logger.getLogger(MicrosoftMapper.class);
    private static final String GRAPH_API_URL = "https://graph.microsoft.com/v1.0/me?$select=department";
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    @Override
    public String[] getCompatibleProviders() {
        return new String[] {"microsoft"};
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public String getDisplayCategory() {
        return "Attribute Importer";
    }

    @Override
    public String getDisplayType() {
        return "Microsoft Graph Department Fetcher";
    }

    @Override
    public String getHelpText() {
        return "Reads department from Microsoft Graph during first login and stores it as a user attribute.";
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return List.of();
    }

    @Override
    public void importNewUser(
            KeycloakSession session,
            RealmModel realm,
            UserModel user,
            IdentityProviderMapperModel mapperModel,
            BrokeredIdentityContext context
    ) {
        fetchAndSetDepartment(context, user);
    }

    @Override
    public void preprocessFederatedIdentity(
            KeycloakSession session,
            RealmModel realm,
            IdentityProviderMapperModel mapperModel,
            BrokeredIdentityContext context
    ) {
        context.setEmail(null);
    }

    @Override
    public void updateBrokeredUser(
            KeycloakSession session,
            RealmModel realm,
            UserModel user,
            IdentityProviderMapperModel mapperModel,
            BrokeredIdentityContext context
    ) {
        String existingDepartment = user.getFirstAttribute("department");
        if (existingDepartment == null || existingDepartment.isBlank()) {
            fetchAndSetDepartment(context, user);
        }
    }

    private void fetchAndSetDepartment(BrokeredIdentityContext context, UserModel user) {
        Object tokenValue = context.getContextData().get("FEDERATED_ACCESS_TOKEN");
        if (!(tokenValue instanceof String token) || token.isBlank()) {
            LOG.warn("Microsoft access token is unavailable; department was not synchronized");
            return;
        }

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(GRAPH_API_URL))
                    .timeout(Duration.ofSeconds(5))
                    .header("Authorization", "Bearer " + token)
                    .header("Accept", "application/json")
                    .GET()
                    .build();
            HttpResponse<String> response = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                LOG.warnf("Microsoft Graph department request returned HTTP %d", response.statusCode());
                return;
            }

            JsonNode departmentNode = OBJECT_MAPPER.readTree(response.body()).get("department");
            if (departmentNode != null && !departmentNode.isNull() && !departmentNode.asText().isBlank()) {
                user.setSingleAttribute("department", departmentNode.asText());
            }
        } catch (Exception exception) {
            LOG.warn("Microsoft Graph department synchronization failed", exception);
        }
    }
}

