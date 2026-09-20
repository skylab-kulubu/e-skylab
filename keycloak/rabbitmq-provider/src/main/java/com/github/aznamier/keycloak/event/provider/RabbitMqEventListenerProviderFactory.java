package com.github.aznamier.keycloak.event.provider;

import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import org.jboss.logging.Logger;
import org.keycloak.Config.Scope;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;
import java.io.FileInputStream;
import java.security.KeyStore;

public final class RabbitMqEventListenerProviderFactory implements EventListenerProviderFactory {

    public static final String PROVIDER_ID = "keycloak-to-rabbitmq";

    private static final Logger LOG = Logger.getLogger(RabbitMqEventListenerProviderFactory.class);

    private RabbitMqConfig config;
    private ConnectionFactory connectionFactory;
    private volatile Connection connection;

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        return new RabbitMqEventListenerProvider(openChannel(), session, config);
    }

    private Channel openChannel() {
        try {
            return connection().createChannel();
        } catch (Exception exception) {
            LOG.error("keycloak-to-rabbitmq could not open a channel; authentication remains available", exception);
            return null;
        }
    }

    private Connection connection() throws Exception {
        Connection current = connection;
        if (current != null && current.isOpen()) {
            return current;
        }
        synchronized (this) {
            current = connection;
            if (current == null || !current.isOpen()) {
                current = connectionFactory.newConnection("keycloak-event-listener");
                connection = current;
            }
            return current;
        }
    }

    @Override
    public void init(Scope scope) {
        config = RabbitMqConfig.from(scope);
        connectionFactory = new ConnectionFactory();
        connectionFactory.setUsername(config.username());
        connectionFactory.setPassword(config.password());
        connectionFactory.setVirtualHost(config.virtualHost());
        connectionFactory.setHost(config.host());
        connectionFactory.setPort(config.port());
        connectionFactory.setAutomaticRecoveryEnabled(true);
        connectionFactory.setTopologyRecoveryEnabled(true);
        connectionFactory.setConnectionTimeout(5_000);

        if (config.useTls()) {
            configureTls(connectionFactory, config);
        }
    }

    private static void configureTls(ConnectionFactory factory, RabbitMqConfig config) {
        try {
            SSLContext context = SSLContext.getInstance("TLSv1.3");
            TrustManagerFactory trustManagers = null;
            KeyManagerFactory keyManagers = null;

            if (!config.trustStore().isBlank()) {
                KeyStore trustStore = KeyStore.getInstance("JKS");
                char[] password = config.trustStorePassword().toCharArray();
                try (FileInputStream input = new FileInputStream(config.trustStore())) {
                    trustStore.load(input, password);
                }
                trustManagers = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
                trustManagers.init(trustStore);
            }

            if (!config.keyStore().isBlank()) {
                KeyStore keyStore = KeyStore.getInstance("PKCS12");
                char[] password = config.keyStorePassword().toCharArray();
                try (FileInputStream input = new FileInputStream(config.keyStore())) {
                    keyStore.load(input, password);
                }
                keyManagers = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                keyManagers.init(keyStore, password);
            }

            context.init(
                    keyManagers == null ? null : keyManagers.getKeyManagers(),
                    trustManagers == null ? null : trustManagers.getTrustManagers(),
                    null
            );
            factory.useSslProtocol(context);
        } catch (Exception exception) {
            throw new IllegalStateException("RabbitMQ TLS configuration is invalid", exception);
        }
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // no-op
    }

    @Override
    public void close() {
        Connection current = connection;
        if (current == null) {
            return;
        }
        try {
            current.close();
        } catch (Exception exception) {
            LOG.debug("Could not close RabbitMQ connection", exception);
        }
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}

