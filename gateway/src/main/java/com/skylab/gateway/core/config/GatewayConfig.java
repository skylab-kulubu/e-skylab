package com.skylab.gateway.core.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import reactor.core.publisher.Mono;

@Configuration
public class GatewayConfig {


    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
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

                .route("eventTypes", r -> r.path("/api/eventTypes/**")
                        .uri("lb://super-skylab"))

                .route("images", r -> r.path("/api/images/**")
                        .uri("lb://super-skylab"))

                .route("qrCodes", r -> r.path("/api/qrCodes/**")
                        .uri("lb://super-skylab"))

                .route("seasons", r -> r.path("/api/seasons/**")
                        .uri("lb://super-skylab"))

                .route("sessions", r -> r.path("/api/sessions/**")
                        .uri("lb://super-skylab"))

                .build();


    }

    private String modifyOpenApiServers(String body) {
        if (body != null && body.contains("\"servers\"")) {
            return body.replaceAll(
                    "\"servers\"\\s*:\\s*\\[[^\\]]*\\]",
                    "\"servers\":[{\"url\":\"http://localhost:8081\",\"description\":\"Gateway Server\"}]"
            );
        }
        return body;
    }


}
