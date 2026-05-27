package com.skylab.gateway.core.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.reactive.observation.DefaultServerRequestObservationConvention;
import org.springframework.http.server.reactive.observation.ServerRequestObservationContext;


@Configuration
public class ObservabilityConfig {

    @Bean
    public DefaultServerRequestObservationConvention gatewaySpanNamingConvention() {
        return new DefaultServerRequestObservationConvention() {
            @Override
            public String getContextualName(ServerRequestObservationContext context) {
                String method = context.getCarrier().getMethod().name();
                String path = normalizePath(context.getCarrier().getURI().getPath());
                return method + " " + path;
            }


            private String normalizePath(String path) {
                if (path == null || path.isEmpty()) {
                    return "/";
                }
                path = path.replaceAll(
                        "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
                        "{id}");
                path = path.replaceAll("/\\d+(/|$)", "/{id}$1");
                return path;
            }
        };
    }
}
