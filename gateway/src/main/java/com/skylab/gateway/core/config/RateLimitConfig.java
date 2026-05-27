package com.skylab.gateway.core.config;

import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.cloud.gateway.filter.ratelimit.RedisRateLimiter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import reactor.core.publisher.Mono;

@Configuration
public class RateLimitConfig {


    @Bean
    @Primary
    public RedisRateLimiter authenticatedRateLimiter() {
        return new RedisRateLimiter(20, 40, 1);
    }


    @Bean("anonymousRateLimiter")
    public RedisRateLimiter anonymousRateLimiter() {
        return new RedisRateLimiter(5, 10, 1);
    }


    @Bean
    @Primary
    public KeyResolver userKeyResolver() {
        return exchange -> ReactiveSecurityContextHolder.getContext()
                .flatMap(ctx -> {
                    var auth = ctx.getAuthentication();
                    if (auth == null || auth instanceof AnonymousAuthenticationToken) {
                        return Mono.empty();
                    }
                    return Mono.just(auth.getName());
                })
                .switchIfEmpty(Mono.justOrEmpty(exchange.getRequest().getRemoteAddress())
                        .map(addr -> "anon:" + addr.getAddress().getHostAddress()))
                .defaultIfEmpty("anon:unknown");
    }
}
