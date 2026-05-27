package com.skylab.gateway.core.filters;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.cloud.gateway.filter.ratelimit.RedisRateLimiter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import static net.logstash.logback.argument.StructuredArguments.kv;

@Slf4j
@Component
public class RateLimitGlobalFilter implements GlobalFilter, Ordered {

    private static final String ROUTE_ID = "global";

    private final RedisRateLimiter rateLimiter;
    private final KeyResolver keyResolver;

    public RateLimitGlobalFilter(RedisRateLimiter rateLimiter, KeyResolver keyResolver) {
        this.rateLimiter = rateLimiter;
        this.keyResolver = keyResolver;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return keyResolver.resolve(exchange)
                .flatMap(key -> {
                    log.debug("rate-limit-check", kv("key", key), kv("path", exchange.getRequest().getPath().value()));
                    return rateLimiter.isAllowed(ROUTE_ID, key)
                            .doOnNext(response -> {
                                if (!response.isAllowed()) {
                                    log.warn("rate-limit-exceeded",
                                            kv("key", key),
                                            kv("path", exchange.getRequest().getPath().value()));
                                }
                            });
                })
                .flatMap(response -> {
                    if (response.isAllowed()) {
                        return chain.filter(exchange);
                    }
                    exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
                    return exchange.getResponse().setComplete();
                })
                .onErrorResume(e -> {
                    log.error("rate-limiter-error",
                            kv("path", exchange.getRequest().getPath().value()),
                            kv("error", e.getMessage()));
                    return chain.filter(exchange);
                });
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }
}
