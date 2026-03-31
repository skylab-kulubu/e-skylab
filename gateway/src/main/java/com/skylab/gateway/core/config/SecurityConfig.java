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
                                "/swagger-resources/**",
                                "/api/auth/register",
                                "/api/auth/login"

                        ).permitAll()


                        //USERS
                        .pathMatchers(HttpMethod.GET, "/api/users/me").hasAnyRole("users.me", "users.moderator")
                        .pathMatchers(HttpMethod.PATCH, "/api/users/me").hasAnyRole("users.me", "users.moderator")
                        .pathMatchers(HttpMethod.POST, "/api/users/me/profile-picture").hasAnyRole("users.me", "users.moderator")
                        .pathMatchers(HttpMethod.GET, "/api/users").hasAnyRole("users.list", "users.moderator")
                        .pathMatchers(HttpMethod.GET, "/api/users/{id}").hasAnyRole("users.get", "users.moderator")
                        .pathMatchers(HttpMethod.PUT, "/api/users/{id}").hasAnyRole("users.update", "users.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/users/{id}").hasAnyRole("users.delete", "users.moderator")
                        .pathMatchers(HttpMethod.POST, "/api/users/{id}/promote").hasAnyRole("users.promote", "users.moderator")


                        //ANNOUNCEMENTS
                        .pathMatchers(HttpMethod.GET, "/api/announcements").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/announcements/{id}").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/announcements/event-type/{eventTypeId}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/announcements").hasAnyRole("announcements.create", "announcements.moderator")
                        .pathMatchers(HttpMethod.PATCH, "/api/announcements/{id}").hasAnyRole("announcements.update", "announcements.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/announcements/{id}").hasAnyRole("announcements.delete", "announcements.moderator")


                        //COMPETITORS
                        .pathMatchers(HttpMethod.GET, "/api/competitors/leaderboard").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/leaderboard/season/{seasonId}").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/event/{eventId}/winner").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/competitors/my").hasAnyRole("competitors.me", "competitors.moderator")
                        .pathMatchers(HttpMethod.GET, "/api/competitors/user/{userId}").hasAnyRole("competitors.list", "competitors.moderator")
                        .pathMatchers(HttpMethod.GET, "/api/competitors/event/{eventId}").hasAnyRole("competitors.list", "competitors.moderator")
                        .pathMatchers(HttpMethod.POST, "/api/competitors").hasAnyRole("competitors.create", "competitors.moderator")
                        .pathMatchers(HttpMethod.GET, "/api/competitors").hasAnyRole("competitors.list", "competitors.moderator")
                        .pathMatchers(HttpMethod.GET, "/api/competitors/{id}").hasAnyRole("competitors.get", "competitors.moderator")
                        .pathMatchers(HttpMethod.PUT, "/api/competitors/{id}").hasAnyRole("competitors.update", "competitors.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/competitors/{id}").hasAnyRole("competitors.delete", "competitors.moderator")


                        // EVENTS!!
                        .pathMatchers(HttpMethod.GET, "/api/events/active").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events/event-type").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/events/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/events").hasAnyRole("events.create", "events.moderator")
                        .pathMatchers(HttpMethod.PUT, "/api/events/{id}").hasAnyRole("events.update", "events.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/events/{id}").hasAnyRole("events.delete", "events.moderator")


                        //EVENT TYPES
                        .pathMatchers(HttpMethod.GET, "/api/event-types/{eventTypeName}/coordinators").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/event-types").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/event-types/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/event-types").hasAnyRole("event_types.create", "event_types.moderator")
                        .pathMatchers(HttpMethod.PUT, "/api/event-types/{id}").hasAnyRole("event_types.update", "event_types.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/event-types/{id}").hasAnyRole("event_types.delete", "event_types.moderator")


                        //MEDIA
                        .pathMatchers(HttpMethod.GET, "/api/media/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/media").hasAnyRole("media.upload", "media.moderator")


                        //SEASONS
                        .pathMatchers(HttpMethod.GET, "/api/seasons/active").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/seasons/{seasonId}/events/{eventId}").hasAnyRole("seasons.manage_events", "seasons.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/seasons/{seasonId}/events/{eventId}").hasAnyRole("seasons.manage_events", "seasons.moderator")
                        .pathMatchers(HttpMethod.GET, "/api/seasons").permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/seasons/{id}").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/seasons").hasAnyRole("seasons.create", "seasons.moderator")
                        .pathMatchers(HttpMethod.PUT, "/api/seasons/{id}").hasAnyRole("seasons.update", "seasons.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/seasons/{id}").hasAnyRole("seasons.delete", "seasons.moderator")


                        //SESSIONS
                        .pathMatchers(HttpMethod.GET, "/api/sessions").permitAll()
                        .pathMatchers(HttpMethod.POST, "/api/sessions").hasAnyRole("sessions.create", "sessions.moderator")
                        .pathMatchers(HttpMethod.DELETE, "/api/sessions/{id}").hasAnyRole("sessions.delete", "sessions.moderator")


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
