package com.skylab.gateway.core.filters;

import com.skylab.gateway.core.web.ClientIpResolver;
import io.micrometer.tracing.Tracer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.UUID;

import static net.logstash.logback.argument.StructuredArguments.kv;

@Slf4j
@Component
public class RequestIdFilter implements GlobalFilter, Ordered {

    private static final String REQUEST_ID_HEADER = "X-Request-ID";

    private final ClientIpResolver clientIpResolver;
    private final Tracer tracer;

    public RequestIdFilter(ClientIpResolver clientIpResolver, Tracer tracer) {
        this.clientIpResolver = clientIpResolver;
        this.tracer = tracer;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String requestId = currentTraceId();
        String clientIp = clientIpResolver.resolve(exchange);

        long startTime = System.currentTimeMillis();

        exchange.getResponse().beforeCommit(() -> {
            exchange.getResponse().getHeaders().set(REQUEST_ID_HEADER, requestId);
            return Mono.empty();
        });

        ServerWebExchange mutatedExchange = exchange.mutate()
                .request(r -> r.header(REQUEST_ID_HEADER, requestId))
                .build();

        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> ctx.getAuthentication() != null ? ctx.getAuthentication().getName() : "anonymous")
                .defaultIfEmpty("anonymous")
                .flatMap(userId -> {
                    log.info("http-request",
                            kv("direction", "in"),
                            kv("method", exchange.getRequest().getMethod().name()),
                            kv("path", exchange.getRequest().getURI().getPath()),
                            kv("userId", userId),
                            kv("clientIp", clientIp));

                    return chain.filter(mutatedExchange).then(Mono.fromRunnable(() -> {
                        long duration = System.currentTimeMillis() - startTime;
                        int status = exchange.getResponse().getStatusCode() != null
                                ? exchange.getResponse().getStatusCode().value() : 0;
                        log.info("http-response",
                                kv("direction", "out"),
                                kv("method", exchange.getRequest().getMethod().name()),
                                kv("path", exchange.getRequest().getURI().getPath()),
                                kv("userId", userId),
                                kv("clientIp", clientIp),
                                kv("status", status),
                                kv("duration", duration));
                    }));
                });
    }

    private String currentTraceId() {
        var span = tracer.currentSpan();
        if (span != null) {
            return span.context().traceId();
        }
        return UUID.randomUUID().toString();
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
