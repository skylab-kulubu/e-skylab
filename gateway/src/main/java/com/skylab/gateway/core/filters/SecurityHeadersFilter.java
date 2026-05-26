package com.skylab.gateway.core.filters;

import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class SecurityHeadersFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        exchange.getResponse().beforeCommit(() -> {
            var headers = exchange.getResponse().getHeaders();
            headers.set("X-Content-Type-Options", "nosniff");
            headers.set("X-Frame-Options", "DENY");
            headers.set("X-XSS-Protection", "1; mode=block");
            headers.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload");
            headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
            headers.set("Permissions-Policy", "geolocation=(), microphone=(), camera=(), payment=()");
            headers.set("Content-Security-Policy",
                    "default-src 'self'; " +
                            "script-src 'self' 'unsafe-inline'; " +
                            "style-src 'self' 'unsafe-inline'; " +
                            "img-src 'self' data: https:; " +
                            "connect-src 'self'");
            return Mono.empty();
        });
        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }
}