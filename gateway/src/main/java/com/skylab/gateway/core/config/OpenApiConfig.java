package com.skylab.gateway.core.config;

import com.skylab.gateway.core.properties.AppGatewayProperties;
import com.skylab.gateway.core.properties.KeycloakProperties;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.OAuthFlow;
import io.swagger.v3.oas.models.security.OAuthFlows;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    private final KeycloakProperties keycloakProperties;
    private final AppGatewayProperties gatewayProperties;

    public OpenApiConfig(KeycloakProperties keycloakProperties, AppGatewayProperties gatewayProperties) {
        this.keycloakProperties = keycloakProperties;
        this.gatewayProperties = gatewayProperties;
    }

    @Bean
    public OpenAPI customOpenAPI() {
        String authUrl = keycloakProperties.getExternalUrl() + "/realms/" + keycloakProperties.getRealm() + "/protocol/openid-connect/auth";
        String tokenUrl = keycloakProperties.getExternalUrl() + "/realms/" + keycloakProperties.getRealm() + "/protocol/openid-connect/token";

        return new OpenAPI()
                .info(new io.swagger.v3.oas.models.info.Info()
                        .title("Gateway API")
                        .version("1.0")
                        .description("API Gateway with OAuth2 Authentication"))
                .servers(List.of(
                        new io.swagger.v3.oas.models.servers.Server()
                                .url(gatewayProperties.getExternalUrl())
                                .description("Gateway Server")
                ))
                .components(new Components()
                        .addSecuritySchemes("oauth2", new SecurityScheme()
                                .type(SecurityScheme.Type.OAUTH2)
                                .description("OAuth2 Authorization Code Flow with PKCE")
                                .flows(new OAuthFlows()
                                        .authorizationCode(new OAuthFlow()
                                                .authorizationUrl(authUrl)
                                                .tokenUrl(tokenUrl)
                                                .scopes(new io.swagger.v3.oas.models.security.Scopes()
                                                        .addString("openid", "OpenID Connect")
                                                        .addString("profile", "Profile information")
                                                        .addString("email", "Email address")
                                                )
                                        )
                                )
                        )
                )
                .addSecurityItem(new SecurityRequirement().addList("oauth2"));
    }
}