package com.skylab.gateway.core.filters;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Slf4j
@Component
public class CorrelationIdFilter implements GlobalFilter, Ordered {

    private static final String CORRELATION_ID_HEADER = "X-Correlation-Id";

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String correlationId = UUID.randomUUID().toString();

        long startTime = System.currentTimeMillis();

        exchange.getResponse().beforeCommit(() -> {
            exchange.getResponse().getHeaders().set(CORRELATION_ID_HEADER, correlationId);
            return Mono.empty();
        });

        ServerWebExchange mutatedExchange = exchange.mutate()
                .request(r -> r.header(CORRELATION_ID_HEADER, correlationId))
                .build();

        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> ctx.getAuthentication() != null ? ctx.getAuthentication().getName() : "anonymous")
                .defaultIfEmpty("anonymous")
                .flatMap(userId -> {
                    log.info("[{}] --> {} {} userId={}",
                            correlationId,
                            exchange.getRequest().getMethod(),
                            exchange.getRequest().getURI().getPath(),
                            userId);

                    return chain.filter(mutatedExchange).then(Mono.fromRunnable(() -> {
                        long duration = System.currentTimeMillis() - startTime;
                        log.info("[{}] <-- {} {} userId={} status={} duration={}ms",
                                correlationId,
                                exchange.getRequest().getMethod(),
                                exchange.getRequest().getURI().getPath(),
                                userId,
                                exchange.getResponse().getStatusCode(),
                                duration);
                    }));
                });
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}