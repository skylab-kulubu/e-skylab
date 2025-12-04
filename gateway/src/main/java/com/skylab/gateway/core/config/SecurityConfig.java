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

    private static final String[] ADMIN_ROLES = {"ADMIN", "YK", "DK"};


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
                                "/swagger-resources/**",
                                "/api/auth/register",
                                "/api/auth/login"

                        ).permitAll()


                        .pathMatchers(HttpMethod.GET, "/api/users/me").authenticated()
                        .pathMatchers(HttpMethod.PUT, "/api/users/me").authenticated()
                        .pathMatchers(HttpMethod.POST, "/api/users/me/profile-picture").authenticated()

                        .pathMatchers(HttpMethod.POST, "/api/groups/**").hasAnyRole(ADMIN_ROLES)
                        .pathMatchers(HttpMethod.POST, "/api/users/assign-role/**").authenticated()

                        .pathMatchers(HttpMethod.GET, "/api/users/**").hasAnyRole(ADMIN_ROLES)
                        .pathMatchers(HttpMethod.PUT, "/api/users/{id}").hasAnyRole(ADMIN_ROLES)
                        .pathMatchers(HttpMethod.DELETE, "/api/users/{id}").hasAnyRole(ADMIN_ROLES)

                        .pathMatchers(HttpMethod.GET, "/api/event-types/**").permitAll()
                        .pathMatchers("/api/event-types/**").hasAnyRole(ADMIN_ROLES)

                        .pathMatchers(HttpMethod.GET, "/api/seasons/**").permitAll()
                        .pathMatchers("/api/seasons/**").hasAnyRole(ADMIN_ROLES)


                        .pathMatchers(HttpMethod.GET, "/api/events/**").permitAll()


                        .pathMatchers(HttpMethod.POST, "/api/events/**").authenticated()
                        .pathMatchers(HttpMethod.PUT, "/api/events/**").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/events/**").authenticated()


                        .pathMatchers(HttpMethod.GET, "/api/competitors/leaderboard/**").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/event/**").permitAll()


                        .pathMatchers(HttpMethod.GET, "/api/competitors/my").authenticated()

                        .pathMatchers(HttpMethod.GET, "/api/competitors/").hasAnyRole(ADMIN_ROLES)

                        .pathMatchers(HttpMethod.GET, "/api/competitors/{id}").hasAnyRole(ADMIN_ROLES)

                        .pathMatchers("/api/competitors/**").authenticated()


                        .pathMatchers(HttpMethod.GET, "/api/sessions/**").permitAll()

                        .pathMatchers("/api/sessions/**").authenticated()


                        .pathMatchers(HttpMethod.GET, "/api/announcements/**").permitAll()
                        .pathMatchers("/api/announcements/**").hasAnyRole(ADMIN_ROLES)

                        .pathMatchers(HttpMethod.GET, "/api/qrCodes/**").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/images/**").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/images/**").hasAnyRole(ADMIN_ROLES)


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
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setExposedHeaders(List.of("Authorization"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }



}
