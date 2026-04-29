package com.skylab.gateway.core.filters;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
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

        log.info("[{}] Received request: {} {}",
                correlationId,
                exchange.getRequest().getMethod(),
                exchange.getRequest().getURI().getPath());

        ServerWebExchange mutatedExchange = exchange.mutate()
                .request(r -> r.header(CORRELATION_ID_HEADER, correlationId))
                .build();

        return chain.filter(mutatedExchange).then(Mono.fromRunnable(() -> {
            exchange.getResponse().getHeaders().add(CORRELATION_ID_HEADER, correlationId);

            log.info("[{}] Response sent with status: {}",
                    correlationId,
                    exchange.getResponse().getStatusCode());
        }));
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}