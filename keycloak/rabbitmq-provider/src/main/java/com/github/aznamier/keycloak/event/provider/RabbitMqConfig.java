package com.github.aznamier.keycloak.event.provider;

import org.jboss.logging.Logger;
import org.keycloak.Config.Scope;
import org.keycloak.events.Event;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;
import org.keycloak.util.JsonSerialization;

import java.util.Locale;
import java.util.regex.Pattern;

final class RabbitMqConfig {

    static final String ROUTING_KEY_PREFIX = "KK.EVENT";
    private static final Logger LOG = Logger.getLogger(RabbitMqConfig.class);
    private static final Pattern SPECIAL_CHARACTERS = Pattern.compile("[^*#a-zA-Z0-9 _.-]");
    private static final Pattern SPACE = Pattern.compile(" ");
    private static final Pattern DOT = Pattern.compile("\\.");

    private String host;
    private int port;
    private String username;
    private String password;
    private String virtualHost;
    private boolean useTls;
    private String trustStore;
    private String trustStorePassword;
    private String keyStore;
    private String keyStorePassword;
    private String exchange;

    static RabbitMqConfig from(Scope scope) {
        RabbitMqConfig config = new RabbitMqConfig();
        config.host = value(scope, "url", "localhost");
        config.port = parsePort(value(scope, "port", "5672"));
        config.username = value(scope, "username", "guest");
        config.password = value(scope, "password", "guest");
        config.virtualHost = value(scope, "vhost", "/");
        config.useTls = Boolean.parseBoolean(value(scope, "use_tls", "false"));
        config.trustStore = value(scope, "trust_store", "");
        config.trustStorePassword = value(scope, "trust_store_pass", "");
        config.keyStore = value(scope, "key_store", "");
        config.keyStorePassword = value(scope, "key_store_pass", "");
        config.exchange = value(scope, "exchange", "amq.topic");
        return config;
    }

    static String routingKey(AdminEvent event, KeycloakSession session) {
        String realm = session.getContext().getRealm() == null
                ? event.getRealmId()
                : session.getContext().getRealm().getName();
        return normalize(ROUTING_KEY_PREFIX
                + ".ADMIN."
                + withoutDots(realm)
                + "."
                + (event.getError() == null ? "SUCCESS" : "ERROR")
                + "."
                + event.getResourceTypeAsString()
                + "."
                + event.getOperationType());
    }

    static String routingKey(Event event, KeycloakSession session) {
        String realmName = session.realms().getRealm(event.getRealmId()).getName();
        return normalize(ROUTING_KEY_PREFIX
                + ".CLIENT."
                + withoutDots(realmName)
                + "."
                + (event.getError() == null ? "SUCCESS" : "ERROR")
                + "."
                + withoutDots(event.getClientId())
                + "."
                + event.getType());
    }

    static String normalize(CharSequence value) {
        return SPACE.matcher(SPECIAL_CHARACTERS.matcher(value).replaceAll(""))
                .replaceAll("_");
    }

    static String withoutDots(String value) {
        return value == null ? "UNKNOWN" : DOT.matcher(value).replaceAll("");
    }

    static String json(Object value) {
        try {
            return JsonSerialization.writeValueAsString(value);
        } catch (Exception exception) {
            LOG.error("Could not serialize Keycloak event", exception);
            return "{\"error\":\"unparseable\"}";
        }
    }

    private static String value(Scope scope, String name, String fallback) {
        String configured = scope == null ? null : scope.get(name);
        if (configured == null) {
            configured = System.getenv("KK_TO_RMQ_" + name.toUpperCase(Locale.ENGLISH));
        }
        String result = configured == null ? fallback : configured;
        if (!name.contains("password") && !name.endsWith("_pass")) {
            LOG.infof("keycloak-to-rabbitmq configuration: %s=%s", name, result);
        }
        return result;
    }

    private static int parsePort(String value) {
        int port = Integer.parseInt(value);
        if (port < 1 || port > 65535) {
            throw new IllegalArgumentException("RabbitMQ port is outside 1-65535");
        }
        return port;
    }

    String host() {
        return host;
    }

    int port() {
        return port;
    }

    String username() {
        return username;
    }

    String password() {
        return password;
    }

    String virtualHost() {
        return virtualHost;
    }

    boolean useTls() {
        return useTls;
    }

    String trustStore() {
        return trustStore;
    }

    String trustStorePassword() {
        return trustStorePassword;
    }

    String keyStore() {
        return keyStore;
    }

    String keyStorePassword() {
        return keyStorePassword;
    }

    String exchange() {
        return exchange;
    }
}

