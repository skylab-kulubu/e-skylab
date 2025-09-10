package com.skylab.gateway.core.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayConfig {


    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("users", r -> r.path("/api/users/**")
                        .uri("lb://super-skylab"))


                .route("events", r -> r.path("/api/events/**")
                        .uri("lb://super-skylab"))
                .build();


    }
}
