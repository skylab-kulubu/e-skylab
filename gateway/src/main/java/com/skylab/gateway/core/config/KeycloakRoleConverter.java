package com.skylab.gateway.core.config;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class KeycloakRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        Map<String, Object> realmAccess = jwt.getClaim("realm_access");
        Collection<String> realmRoles = extractRoles(realmAccess);

        Map<String, Object> resourceAccess = jwt.getClaim("resource_access");
        Set<String> clientRoles = new HashSet<>();

        if (resourceAccess != null){
            resourceAccess.values().forEach(clientAccess -> {
                clientRoles.addAll(extractRoles((Map<String, Object>) clientAccess));
            });
        }


        return Stream.concat(realmRoles.stream(), clientRoles.stream())
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                .collect(Collectors.toSet());

    }

    private Collection<String> extractRoles(Map<String, Object> accessMap) {

        if (accessMap == null || !accessMap.containsKey("roles")){
            return Collections.emptyList();
        }

        return (Collection<String>) accessMap.get("roles");

    }
}