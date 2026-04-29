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
import org.springframework.web.cors.reactive.CorsConfigurationSource;
import reactor.core.publisher.Mono;

@Configuration
@EnableWebFluxSecurity
@EnableReactiveMethodSecurity
public class SecurityConfig {


    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http, CorsConfigurationSource corsConfigurationSource) {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchange -> exchange

                        .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        .pathMatchers(
                                "/webjars/**",
                                "/v3/api-docs/**",
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/swagger-resources/**",
                                "/api/auth/register",
                                "/api/auth/login"

                        ).permitAll()


                        //USERS
                        .pathMatchers(HttpMethod.GET, "/api/users/me").authenticated()
                        .pathMatchers(HttpMethod.PATCH, "/api/users/me").authenticated()
                        .pathMatchers(HttpMethod.POST, "/api/users/me/profile-picture").authenticated()
                        .pathMatchers(HttpMethod.GET, "/api/users").authenticated()
                        .pathMatchers(HttpMethod.GET, "/api/users/{id}").authenticated()
                        .pathMatchers(HttpMethod.PUT, "/api/users/{id}").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/users/{id}").authenticated()
                        .pathMatchers(HttpMethod.POST, "/api/users/{id}/promote").authenticated()


                        //ANNOUNCEMENTS
                        .pathMatchers(HttpMethod.GET, "/api/announcements").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/announcements/{id}").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/announcements/event-type/{eventTypeId}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/announcements").authenticated()
                        .pathMatchers(HttpMethod.PATCH, "/api/announcements/{id}").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/announcements/{id}").authenticated()


                        //COMPETITORS
                        .pathMatchers(HttpMethod.GET, "/api/competitors/leaderboard/type/{eventTypeName}").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/leaderboard/season/{seasonId}/type/{eventTypeName}").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events/{eventId}/competitors/winner").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events/{eventId}/competitors").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/me").authenticated()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/user/{userId}").authenticated()
                        .pathMatchers(HttpMethod.POST, "/api/competitors").authenticated()
                        .pathMatchers(HttpMethod.GET, "/api/competitors").authenticated()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/{id}").authenticated()
                        .pathMatchers(HttpMethod.PUT, "/api/competitors/{id}").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/competitors/{id}").authenticated()


                        // EVENTS!!
                        .pathMatchers(HttpMethod.GET, "/api/events/active").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events/type/{eventTypeName}").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/events").authenticated()
                        .pathMatchers(HttpMethod.PUT, "/api/events/{id}").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/events/{id}").authenticated()
                        .pathMatchers(HttpMethod.POST, "/api/events/{eventId}/seasons/{seasonId}").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/events/{eventId}/season").authenticated()


                        //EVENT TYPES
                        .pathMatchers(HttpMethod.GET, "/api/event-types/{eventTypeName}/coordinators").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/event-types").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/event-types/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/event-types").authenticated()
                        .pathMatchers(HttpMethod.PUT, "/api/event-types/{id}").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/event-types/{id}").authenticated()


                        //MEDIA
                        .pathMatchers(HttpMethod.GET, "/api/media/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/media").authenticated()


                        //SEASONS
                        .pathMatchers(HttpMethod.GET, "/api/seasons").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/seasons/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/seasons").authenticated()
                        .pathMatchers(HttpMethod.PUT, "/api/seasons/{id}").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/seasons/{id}").authenticated()


                        //SESSIONS
                        .pathMatchers(HttpMethod.GET, "/api/sessions").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/sessions").authenticated()
                        .pathMatchers(HttpMethod.DELETE, "/api/sessions/{id}").authenticated()


                        //QR CODES
                        .pathMatchers(HttpMethod.GET, "/api/qrCodes/**").permitAll()



                        // SKYFORMS ACCESS
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms").hasAnyRole("skyforms:access")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/metrics").hasAnyRole("skyforms:access")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/component-groups").hasAnyRole("skyforms:access")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/component-groups/{id}").hasAnyRole("skyforms:access")
                        .pathMatchers(HttpMethod.POST, "/api/admin/forms/component-groups").hasAnyRole("skyforms:access")
                        .pathMatchers(HttpMethod.PUT, "/api/admin/forms/component-groups/{id}").hasAnyRole("skyforms:access")
                        .pathMatchers(HttpMethod.DELETE, "/api/admin/forms/component-groups/{id}").hasAnyRole("skyforms:access")

                        // SKYFORMS FORM MANAGE
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/{id}").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/{id}/info").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/{id}/linkable-forms").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.POST, "/api/admin/forms").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.PUT, "/api/admin/forms/{id}").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/{id}/draft").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.POST, "/api/admin/forms/{id}/draft").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.DELETE, "/api/admin/forms/{id}/draft").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.DELETE, "/api/admin/forms/{id}").hasAnyRole("skyforms:form:manage")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/{id}/metrics").hasAnyRole("skyforms:form:manage")

                        // SKYFORMS RESPONSE MANAGE
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/{id}/responses").hasAnyRole("skyforms:response:manage")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/responses/{id}").hasAnyRole("skyforms:response:manage")
                        .pathMatchers(HttpMethod.PATCH, "/api/admin/forms/responses/{id}/status").hasAnyRole("skyforms:response:manage")
                        .pathMatchers(HttpMethod.POST, "/api/admin/forms/responses/{id}/archive").hasAnyRole("skyforms:response:manage")
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/{id}/responses/export").hasAnyRole("skyforms:response:manage")

                        // SKYFORMS ALL
                        .pathMatchers(HttpMethod.GET, "/api/admin/forms/all").hasAnyRole("skyforms:*")

                        // SKYFORMS FEEDBACKS
                        .pathMatchers(HttpMethod.GET, "/api/feedbacks").hasAnyRole("skyforms:feedback:manage")
                        .pathMatchers(HttpMethod.GET, "/api/feedbacks/{id}").hasAnyRole("skyforms:feedback:manage")
                        .pathMatchers(HttpMethod.GET, "/api/feedbacks/all").hasAnyRole("skyforms:feedback:*")

                        // PUBLIC FORMS
                        .pathMatchers(HttpMethod.GET, "/api/forms/{id}").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/forms/{id}/meta").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/forms/responses").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/forms/responses/draft").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/forms/responses/draft/{id}").permitAll()
                        .pathMatchers(HttpMethod.DELETE, "/api/forms/responses/draft/{id}").permitAll()

                        // PUBLIC FEEDBACKS
                        .pathMatchers(HttpMethod.POST, "/api/feedbacks").permitAll()


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


}
