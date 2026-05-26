package com.skylab.gateway.core.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.skylab.gateway.core.properties.AppGatewayProperties;
import com.skylab.gateway.core.properties.KeycloakProperties;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import reactor.core.publisher.Mono;

@Configuration
public class GatewayConfig {

    private static final String SUPER_SKYLAB_CB = "super-skylab-cb";
    private static final String DOTNET_CB        = "dotnet-cb";

    private static final String SUPER_SKYLAB_URI = "lb://super-skylab";
    private static final String DOTNET_URI        = "lb://DOTNETAPI";

    private static final String SKYMAIL_CB = "skymail-cb";
    private static final String SKYMAIL_URI = "lb://skymail";

    private final AppGatewayProperties appGatewayProperties;
    private final KeycloakProperties keycloakProperties;
    private final ObjectMapper objectMapper;

    public GatewayConfig(AppGatewayProperties appGatewayProperties,
                         KeycloakProperties keycloakProperties,
                         ObjectMapper objectMapper) {
        this.appGatewayProperties = appGatewayProperties;
        this.keycloakProperties = keycloakProperties;
        this.objectMapper = objectMapper;
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()

                // ── OpenAPI docs ────────────────────────────────────────────
                .route("openapi-super-skylab", r -> r
                        .path("/v3/api-docs/super-skylab")
                        .filters(f -> f
                                .rewritePath("/v3/api-docs/super-skylab", "/v3/api-docs")
                                .modifyResponseBody(String.class, String.class,
                                        (exchange, body) -> Mono.just(modifyOpenApiServers(body)))
                                .circuitBreaker(c -> c
                                        .setName(SUPER_SKYLAB_CB)
                                        .setFallbackUri("forward:/fallback/super-skylab"))
                        )
                        .uri(SUPER_SKYLAB_URI))

                .route("openapi-dotnet", r -> r
                        .path("/v3/api-docs/DOTNETAPI")
                        .filters(f -> f
                                .rewritePath("/v3/api-docs/DOTNETAPI", "/swagger/v1/swagger.json")
                                .modifyResponseBody(String.class, String.class,
                                        (exchange, body) -> Mono.just(
                                                injectOAuth2Security(modifyOpenApiServers(body))))
                                        .circuitBreaker(c -> c
                                                .setName(DOTNET_CB)
                                                .setFallbackUri("forward:/fallback/dotnet"))
                        )
                        .uri(DOTNET_URI))


                .route("openapi-skymail", r -> r
                        .path("/v3/api-docs/skymail")
                        .filters(f -> f
                                .rewritePath("/v3/api-docs/skymail", "/docs/openapi.json")
                                .modifyResponseBody(String.class, String.class,
                                        (exchange, body) -> Mono.just(
                                                injectOAuth2Security(modifyOpenApiServers(body))))
                                .circuitBreaker(c -> c
                                        .setName(SKYMAIL_CB)
                                        .setFallbackUri("forward:/fallback/skymail")))
                        .uri(SKYMAIL_URI))

                // ── super-skylab routes ──────────────────────────────────────
                .route("users", r -> r.path("/api/users/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("announcements", r -> r.path("/api/announcements/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("auth", r -> r.path("/api/auth/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("competitions", r -> r.path("/api/competitions/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("competitors", r -> r.path("/api/competitors/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("events", r -> r.path("/api/events/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("groups", r -> r.path("/api/groups/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("event-types", r -> r.path("/api/event-types/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("media", r -> r.path("/api/media/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("qr-codes", r -> r.path("/api/qr-codes/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("seasons", r -> r.path("/api/seasons/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("sessions", r -> r.path("/api/sessions/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("certificates", r -> r.path("/api/certificates/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("event-days", r -> r.path("/api/event-days/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("tickets", r -> r.path("/api/tickets/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                .route("content", r -> r.path("/api/content/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(SUPER_SKYLAB_CB)
                                .setFallbackUri("forward:/fallback/super-skylab")))
                        .uri(SUPER_SKYLAB_URI))

                // ── DOTNETAPI routes ─────────────────────────────────────────
                .route("forms", r -> r.path("/api/forms/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(DOTNET_CB)
                                .setFallbackUri("forward:/fallback/dotnet")))
                        .uri(DOTNET_URI))

                .route("admin-forms", r -> r.path("/api/admin/forms/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(DOTNET_CB)
                                .setFallbackUri("forward:/fallback/dotnet")))
                        .uri(DOTNET_URI))

                .route("feedbacks", r -> r.path("/api/feedbacks/**")
                        .filters(f -> f.circuitBreaker(c -> c
                                .setName(DOTNET_CB)
                                .setFallbackUri("forward:/fallback/dotnet")))
                        .uri(DOTNET_URI))


                // SKYMAIL routes
                .route("skymail", r -> r.path("/api/skymail/**")
                        .filters(f -> f
                                .rewritePath("/api/skymail/(?<segment>.*)", "/${segment}")
                                .circuitBreaker(c -> c
                                        .setName(SKYMAIL_CB)
                                        .setFallbackUri("forward:/fallback/skymail")))
                        .uri(SKYMAIL_URI))


                .build();
    }



    private String injectOAuth2Security(String body) {
        if (body == null) return null;
        try {
            ObjectNode root = (ObjectNode) objectMapper.readTree(body);

            String authUrl  = keycloakProperties.getExternalUrl()
                    + "/realms/" + keycloakProperties.getRealm()
                    + "/protocol/openid-connect/auth";
            String tokenUrl = keycloakProperties.getExternalUrl()
                    + "/realms/" + keycloakProperties.getRealm()
                    + "/protocol/openid-connect/token";

            if (root.has("swagger")) {
                ObjectNode def = objectMapper.createObjectNode();
                def.put("type", "oauth2");
                def.put("flow", "accessCode");
                def.put("authorizationUrl", authUrl);
                def.put("tokenUrl", tokenUrl);
                ObjectNode scopes = objectMapper.createObjectNode();
                def.set("scopes", scopes);

                ObjectNode secDefs = root.has("securityDefinitions")
                        ? (ObjectNode) root.get("securityDefinitions")
                        : objectMapper.createObjectNode();
                secDefs.set("oauth2", def);
                root.set("securityDefinitions", secDefs);
            } else {
                ObjectNode flow = objectMapper.createObjectNode();
                flow.put("authorizationUrl", authUrl);
                flow.put("tokenUrl", tokenUrl);
                ObjectNode scopes = objectMapper.createObjectNode();
                flow.set("scopes", scopes);

                ObjectNode flows = objectMapper.createObjectNode();
                flows.set("authorizationCode", flow);

                ObjectNode scheme = objectMapper.createObjectNode();
                scheme.put("type", "oauth2");
                scheme.put("description", "OAuth2 Authorization Code Flow with PKCE");
                scheme.set("flows", flows);

                ObjectNode components = root.has("components")
                        ? (ObjectNode) root.get("components")
                        : objectMapper.createObjectNode();
                ObjectNode secSchemes = components.has("securitySchemes")
                        ? (ObjectNode) components.get("securitySchemes")
                        : objectMapper.createObjectNode();
                secSchemes.set("oauth2", scheme);
                components.set("securitySchemes", secSchemes);
                root.set("components", components);
            }

            ArrayNode security = objectMapper.createArrayNode();
            ObjectNode req = objectMapper.createObjectNode();
            req.set("oauth2", objectMapper.createArrayNode());
            security.add(req);
            root.set("security", security);

            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            return body;
        }
    }



    private String modifyOpenApiServers(String body) {
        if (body != null && body.contains("\"servers\"")) {
            String gatewayUrl = appGatewayProperties.getExternalUrl();
            return body.replaceAll(
                    "\"servers\"\\s*:\\s*\\[[^\\]]*\\]",
                    "\"servers\":[{\"url\":\"" + gatewayUrl + "\",\"description\":\"Gateway Server\"}]"
            );
        }
        return body;
    }
}
