package com.skylab.gateway.core.config;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class KeycloakRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        // 1) Realm roles
        Map<String, Object> realmAccess = jwt.getClaim("realm_access");
        List<String> realmRoles = Collections.emptyList();
        if (realmAccess != null && realmAccess.containsKey("roles")) {
            realmRoles = (List<String>) realmAccess.get("roles");
        }

        // 2) Groups claim (Keycloak groups -> map to roles); examples: ["/admin", "/yk", "/dk"]
        List<String> groupRoles = Collections.emptyList();
        Object groupsObj = jwt.getClaim("groups");
        if (groupsObj instanceof List) {
            List<?> groups = (List<?>) groupsObj;
            groupRoles = groups.stream()
                    .filter(g -> g instanceof String)
                    .map(g -> (String) g)
                    .map(g -> g.startsWith("/") ? g.substring(1) : g)
                    .filter(g -> !g.isEmpty())
                    .collect(Collectors.toList());
        }

        // 3) Merge and normalize
        return  
            java.util.stream.Stream.concat(realmRoles.stream(), groupRoles.stream())
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()))
                .collect(Collectors.toSet());
    }
}
