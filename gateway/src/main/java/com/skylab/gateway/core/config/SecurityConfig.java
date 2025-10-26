package com.skylab.gateway.core.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableReactiveMethodSecurity;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.ReactiveJwtAuthenticationConverterAdapter;
import org.springframework.security.web.server.SecurityWebFilterChain;
import reactor.core.publisher.Mono;

@Configuration
@EnableWebFluxSecurity
@EnableReactiveMethodSecurity
public class SecurityConfig {


    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchange -> exchange

                            .pathMatchers(HttpMethod.POST, "/api/auth/register").permitAll()


                                // User Controller
                                .pathMatchers(HttpMethod.GET, "/api/users/me").hasAnyRole("USER")
                                .pathMatchers(HttpMethod.PUT, "/api/users/me").hasAnyRole("USER")
                                .pathMatchers(HttpMethod.POST, "/api/users/me/profile-picture").hasAnyRole("USER")
                                .pathMatchers(HttpMethod.GET, "/api/users/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/users/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.PUT, "/api/users/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.DELETE, "/api/users/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.PUT, "/api/users/add-role/{username}").permitAll()

                                //Groups
                                 .pathMatchers(HttpMethod.POST, "/api/groups/").permitAll()//will change later
                                // Event Controller
                                .pathMatchers(HttpMethod.GET, "/api/events/").permitAll()
                                .pathMatchers(HttpMethod.PUT, "/api/events/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.POST, "/api/events/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/events/{id}").permitAll()
                                .pathMatchers(HttpMethod.DELETE, "/api/events/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/events/event-type").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/events/active").permitAll()
                                .pathMatchers(HttpMethod.PATCH, "/api/events/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")


                                // QR Code Controller
                                .pathMatchers(HttpMethod.GET, "/api/qrCodes/generateQRCode").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/qrCodes/generateQRCodeWithLogo").permitAll()


                        .anyExchange().hasAnyRole("ADMIN")
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(grantedAuthoritiesExtractor()))
                );
        return http.build();
    }


    private Converter<Jwt, Mono<AbstractAuthenticationToken>> grantedAuthoritiesExtractor() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(new KeycloakRoleConverter());
        return new ReactiveJwtAuthenticationConverterAdapter(converter);
    }



}
