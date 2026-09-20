package com.github.aznamier.keycloak.event.provider;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import org.jboss.logging.Logger;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerTransaction;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;

import java.nio.charset.StandardCharsets;
import java.util.Map;

final class RabbitMqEventListenerProvider implements EventListenerProvider {

    private static final Logger LOG = Logger.getLogger(RabbitMqEventListenerProvider.class);

    private final RabbitMqConfig config;
    private final Channel channel;
    private final KeycloakSession session;
    private final EventListenerTransaction transaction;

    RabbitMqEventListenerProvider(Channel channel, KeycloakSession session, RabbitMqConfig config) {
        this.channel = channel;
        this.session = session;
        this.config = config;
        this.transaction = new EventListenerTransaction(this::publishAdminEvent, this::publishEvent);
        session.getTransactionManager().enlistAfterCompletion(transaction);
    }

    @Override
    public void onEvent(Event event) {
        transaction.addEvent(event.clone());
    }

    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
        transaction.addAdminEvent(event, includeRepresentation);
    }

    private void publishEvent(Event event) {
        publish(
                RabbitMqConfig.json(EventClientNotificationMqMsg.from(event)),
                properties(EventClientNotificationMqMsg.class.getName()),
                RabbitMqConfig.routingKey(event, session)
        );
    }

    private void publishAdminEvent(AdminEvent event, boolean includeRepresentation) {
        EventAdminNotificationMqMsg message = EventAdminNotificationMqMsg.from(event);
        if (!includeRepresentation) {
            message.setRepresentation(null);
        }
        publish(
                RabbitMqConfig.json(message),
                properties(EventAdminNotificationMqMsg.class.getName()),
                RabbitMqConfig.routingKey(event, session)
        );
    }

    private void publish(String body, AMQP.BasicProperties properties, String routingKey) {
        if (channel == null || !channel.isOpen()) {
            LOG.errorf("keycloak-to-rabbitmq skipped event because no channel is available: %s", routingKey);
            return;
        }
        try {
            channel.basicPublish(
                    config.exchange(),
                    routingKey,
                    properties,
                    body.getBytes(StandardCharsets.UTF_8)
            );
            LOG.tracef("keycloak-to-rabbitmq published event: %s", routingKey);
        } catch (Exception exception) {
            LOG.errorf(exception, "keycloak-to-rabbitmq failed to publish event: %s", routingKey);
        }
    }

    private static AMQP.BasicProperties properties(String className) {
        return new AMQP.BasicProperties.Builder()
                .appId("Keycloak")
                .headers(Map.of("__TypeId__", className))
                .contentType("application/json")
                .contentEncoding(StandardCharsets.UTF_8.name())
                .deliveryMode(2)
                .build();
    }

    @Override
    public void close() {
        if (channel == null) {
            return;
        }
        try {
            channel.close();
        } catch (Exception exception) {
            LOG.debug("Could not close RabbitMQ channel", exception);
        }
    }
}

