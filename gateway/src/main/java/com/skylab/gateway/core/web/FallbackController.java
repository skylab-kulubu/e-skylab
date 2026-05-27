package com.skylab.gateway.core.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;


@RestController
public class FallbackController {

    @RequestMapping("/fallback/super-skylab")
    public Mono<ResponseEntity<Map<String, Object>>> superSkylabFallback(ServerWebExchange exchange) {
        return Mono.just(buildFallbackResponse(
                exchange,
                "super-skylab service is temporarily unavailable. Please try again shortly."
        ));
    }

    @RequestMapping("/fallback/dotnet")
    public Mono<ResponseEntity<Map<String, Object>>> dotnetFallback(ServerWebExchange exchange) {
        return Mono.just(buildFallbackResponse(
                exchange,
                "Forms service is temporarily unavailable. Please try again shortly."
        ));
    }

    @RequestMapping("/fallback/skymail")
    public Mono<ResponseEntity<Map<String, Object>>> skymailFallback(ServerWebExchange exchange) {
        return Mono.just(buildFallbackResponse(
                exchange,
                "Skymail service is temporarily unavailable. Please try again shortly."
        ));
    }

    private ResponseEntity<Map<String, Object>> buildFallbackResponse(ServerWebExchange exchange, String detail) {
        String requestId = exchange.getRequest().getHeaders().getFirst("X-Request-ID");
        String path = exchange.getRequest().getURI().getPath();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type", "https://api.yildizskylab.com/errors/service-unavailable");
        body.put("title", "Service Unavailable");
        body.put("status", HttpStatus.SERVICE_UNAVAILABLE.value());
        body.put("detail", detail);
        body.put("instance", path);
        body.put("timestamp", Instant.now().toString());
        if (requestId != null) {
            body.put("requestId", requestId);
        }

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .body(body);
    }
}
