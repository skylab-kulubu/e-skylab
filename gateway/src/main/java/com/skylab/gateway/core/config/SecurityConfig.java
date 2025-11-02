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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsConfigurationSource;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;
import java.util.List;

@Configuration
@EnableWebFluxSecurity
@EnableReactiveMethodSecurity
public class SecurityConfig {


    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchange -> exchange


                        .pathMatchers(
                                "/webjars/**",
                                "/v3/api-docs/**",
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/swagger-resources/**"
                        ).permitAll()



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


                                .pathMatchers(HttpMethod.POST, "/api/groups/").hasAnyRole("ADMIN","YK","DK")


                                //passed tests- EVENT TYPES CONTROLLER
                                .pathMatchers(HttpMethod.POST, "/api/event-types/").hasAnyRole("ADMIN", "YK", "DK")
                                .pathMatchers(HttpMethod.DELETE, "/api/event-types/{id}").hasAnyRole("ADMIN", "YK", "DK")
                                .pathMatchers(HttpMethod.PUT, "/api/event-types/{id}").hasAnyRole("ADMIN", "YK", "DK")
                                .pathMatchers(HttpMethod.GET, "/api/event-types/").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/event-types/{id}").permitAll()

                                .pathMatchers(HttpMethod.POST, "/api/events/").hasAnyRole("ADMIN", "YK", "DK","GECEKODU_LEADER", "AGC_LEADER","BIZBIZE_LEADER")
                                .pathMatchers(HttpMethod.GET, "/api/events/").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/events/{id}").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/events/event-type/{eventTypeName}").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/events/active/{isActive}").permitAll()




                                .pathMatchers(HttpMethod.POST, "/api/competitions/").hasAnyRole("ADMAIN", "YK", "DK")
                                .pathMatchers(HttpMethod.GET, "/api/competitions/").permitAll()
                                .pathMatchers(HttpMethod.DELETE, "/api/competitions/{id}").hasAnyRole("ADMIN", "YK", "DK")
                                .pathMatchers(HttpMethod.POST, "/api/competitions/{competitionId}/events/{eventId}").hasAnyRole("ADMIN", "YK", "DK")
                                .pathMatchers(HttpMethod.GET, "/api/competitions/{id}").permitAll()
                                .pathMatchers(HttpMethod.PUT, "/api/competitions/{id}").hasAnyRole("ADMIN", "YK", "DK")
                                .pathMatchers(HttpMethod.GET, "/api/competitions/active/").permitAll() //TODO: remove this endpoint



                                //sessions
                        .pathMatchers(HttpMethod.GET, "/api/sessions/").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/sessions/").hasAnyRole("ADMIN", "YK", "DK")
                        .pathMatchers(HttpMethod.DELETE, "/api/sessions/{id}").hasAnyRole("ADMIN", "YK", "DK")



                                // QR Code Controller
                                .pathMatchers(HttpMethod.GET, "/api/qrCodes/generateQRCode").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/qrCodes/generateQRCodeWithLogo").permitAll()


                        .anyExchange().denyAll()
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

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*")); // Production'da spesifik olmalı
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setExposedHeaders(List.of("Authorization"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }



}
