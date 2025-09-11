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
                        .pathMatchers(HttpMethod.GET, "/swagger-ui/**", "/v3/api-docs/**").permitAll()


                                // User Controller
                                .pathMatchers(HttpMethod.GET, "/api/users/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.PUT, "/api/users/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.DELETE, "/api/users/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/users/me").hasAnyRole("USER")
                                .pathMatchers(HttpMethod.PUT, "/api/users/me").hasAnyRole("USER")
                                .pathMatchers(HttpMethod.PUT, "/api/users/addRole/{username}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.POST, "/api/users/addUser").permitAll() //TODO: move it to auth controller later
                                .pathMatchers(HttpMethod.GET, "/api/users/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")

                                // Event Controller
                                .pathMatchers(HttpMethod.GET, "/api/events/").permitAll()
                                .pathMatchers(HttpMethod.PUT, "/api/events/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.POST, "/api/events/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/events/{id}").permitAll()
                                .pathMatchers(HttpMethod.DELETE, "/api/events/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/events/getAllByEventType").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/events/active").permitAll()

                                // Event Type Controller
                                .pathMatchers(HttpMethod.GET, "/api/eventTypes/{id}").permitAll()
                                .pathMatchers(HttpMethod.PUT, "/api/eventTypes/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.DELETE, "/api/eventTypes/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/eventTypes/").permitAll()
                                .pathMatchers(HttpMethod.POST, "/api/eventTypes/").hasAnyRole("ADMIN")

                                // Competitor Controller
                                .pathMatchers(HttpMethod.PUT, "/api/competitors/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.DELETE, "/api/competitors/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.POST, "/api/competitors/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/competitors/user/{userId}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/competitors/my").hasAnyRole("USER")
                                .pathMatchers(HttpMethod.GET, "/api/competitors/leaderboard/{competitionId}").hasAnyRole("USER")
                                .pathMatchers(HttpMethod.GET, "/api/competitors/event/{eventId}").hasAnyRole("USER")

                                // Competition Controller
                                .pathMatchers(HttpMethod.GET, "/api/competitions/{id}").permitAll()
                                .pathMatchers(HttpMethod.PUT, "/api/competitions/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.DELETE, "/api/competitions/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/competitions/").permitAll()
                                .pathMatchers(HttpMethod.POST, "/api/competitions/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/competitions/active").permitAll()

                                // Announcement Controller
                                .pathMatchers(HttpMethod.PUT, "/api/announcements/updateAnnouncement/{id}").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.POST, "/api/announcements/addImagesToAnnouncement").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.POST, "/api/announcements/addAnnouncement").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/announcements/getAnnouncementById/{id}").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/announcements/getAllByEventTypeId/{eventTypeId}").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/announcements/getAllAnnouncements").permitAll()
                                .pathMatchers(HttpMethod.DELETE, "/api/announcements/deleteAnnouncement/{id}").hasAnyRole("ADMIN")

                                // Session Controller
                                .pathMatchers(HttpMethod.GET, "/api/sessions/").permitAll()
                                .pathMatchers(HttpMethod.POST, "/api/sessions/").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.DELETE, "/api/sessions/{id}").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")

                                // Season Controller
                                .pathMatchers(HttpMethod.POST, "/api/seasons/removeEventFromSeason").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.POST, "/api/seasons/addEventToSeason").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/seasons/").permitAll()
                                .pathMatchers(HttpMethod.POST, "/api/seasons/").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/seasons/{id}").permitAll()
                                .pathMatchers(HttpMethod.DELETE, "/api/seasons/{id}").hasAnyRole("ADMIN")

                                // Image Controller
                                .pathMatchers(HttpMethod.POST, "/api/images/addImage").hasAnyRole("ADMIN", "AGC_ADMIN", "GECEKODU_ADMIN", "BIZBIZE_ADMIN")
                                .pathMatchers(HttpMethod.GET, "/api/images/getImageDetailsByUrl/{url}").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/images/getImageByUrl/{url}").permitAll()
                                .pathMatchers(HttpMethod.GET, "/api/images/getAllImages").hasAnyRole("ADMIN")
                                .pathMatchers(HttpMethod.DELETE, "/api/images/deleteImageById/{id}").hasAnyRole("ADMIN")

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
