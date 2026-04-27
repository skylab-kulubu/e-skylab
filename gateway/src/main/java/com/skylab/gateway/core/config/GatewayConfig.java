package com.skylab.gateway.core.config;

import com.skylab.gateway.core.properties.AppGatewayProperties;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import reactor.core.publisher.Mono;

@Configuration
public class GatewayConfig {

    private final AppGatewayProperties appGatewayProperties;

    public GatewayConfig(AppGatewayProperties appGatewayProperties) {
        this.appGatewayProperties = appGatewayProperties;
    }


    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()

                .route("openapi-super-skylab", r -> r
                        .path("/v3/api-docs/super-skylab")
                        .filters(f -> f
                                .rewritePath("/v3/api-docs/super-skylab", "/v3/api-docs")
                                .modifyResponseBody(String.class, String.class,
                                        (exchange, body) -> Mono.just(modifyOpenApiServers(body)))
                        )
                        .uri("lb://super-skylab"))

                .route("openapi-DOTNETAPI", r -> r
                        .path("/v3/api-docs/DOTNETAPI")
                        .filters(f -> f
                                .rewritePath(
                                        "/v3/api-docs/DOTNETAPI",
                                        "/swagger/v1/swagger.json"
                                )
                                .modifyResponseBody(String.class, String.class,
                                        (exchange, body) -> Mono.just(modifyOpenApiServers(body))
                                )
                        )
                        .uri("lb://DOTNETAPI")
                )

                .route("users", r -> r.path("/api/users/**")
                        .uri("lb://super-skylab"))

                .route("announcements", r -> r.path("/api/announcements/**")
                        .uri("lb://super-skylab"))

                .route("auth", r -> r.path("/api/auth/**")
                        .uri("lb://super-skylab"))

                .route("competitions", r -> r.path("/api/competitions/**")
                        .uri("lb://super-skylab"))

                .route("competitors", r -> r.path("/api/competitors/**")
                        .uri("lb://super-skylab"))

                .route("events", r -> r.path("/api/events/**")
                        .uri("lb://super-skylab"))

                .route("groups", r -> r.path("/api/groups/**")
                        .uri("lb://super-skylab"))

                .route("event-types", r -> r.path("/api/event-types/**")
                        .uri("lb://super-skylab"))

                .route("media", r -> r.path("/api/media/**")
                        .uri("lb://super-skylab"))

                .route("qrCodes", r -> r.path("/api/qrCodes/**")
                        .uri("lb://super-skylab"))

                .route("seasons", r -> r.path("/api/seasons/**")
                        .uri("lb://super-skylab"))

                .route("sessions", r -> r.path("/api/sessions/**")
                        .uri("lb://super-skylab"))

                .route("forms", r -> r.path("/api/forms/**")
                        .uri("lb://DOTNETAPI"))

                .route("admin-forms", r -> r.path("/api/admin/forms/**")
                        .uri("lb://DOTNETAPI"))

                .route("feedbacks", r -> r.path("/api/feedbacks/**")
                        .uri("lb://DOTNETAPI"))

                .build();


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
