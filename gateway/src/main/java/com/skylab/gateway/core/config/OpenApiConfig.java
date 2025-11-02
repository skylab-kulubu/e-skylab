package com.skylab.gateway.core.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.OAuthFlow;
import io.swagger.v3.oas.models.security.OAuthFlows;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Value("${keycloak.auth-server-url:http://localhost:8080}")
    private String authServerUrl;

    @Bean
    public OpenAPI customOpenAPI() {
        String keycloakUrl = authServerUrl + "/realms/e-skylab/protocol/openid-connect";

        return new OpenAPI()
                .info(new io.swagger.v3.oas.models.info.Info()
                        .title("Gateway API")
                        .version("1.0")
                        .description("API Gateway with OAuth2 Authentication"))
                .servers(java.util.List.of(
                        new io.swagger.v3.oas.models.servers.Server()
                                .url("http://localhost:8081")
                                .description("Gateway Server")
                ))
                .components(new Components()
                        .addSecuritySchemes("oauth2", new SecurityScheme()
                                .type(SecurityScheme.Type.OAUTH2)
                                .description("OAuth2 Authorization Code Flow with PKCE")
                                .flows(new OAuthFlows()
                                        .authorizationCode(new OAuthFlow()
                                                .authorizationUrl("http://keycloak:8080/realms/e-skylab/protocol/openid-connect/auth")
                                                .tokenUrl("http://keycloak:8080/realms/e-skylab/protocol/openid-connect/token")
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