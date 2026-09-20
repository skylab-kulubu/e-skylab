package com.github.aznamier.keycloak.event.provider;

import com.fasterxml.jackson.annotation.JsonTypeInfo;
import org.keycloak.events.Event;

import java.io.Serial;
import java.io.Serializable;

@JsonTypeInfo(use = JsonTypeInfo.Id.CLASS)
final class EventClientNotificationMqMsg extends Event implements Serializable {

    @Serial
    private static final long serialVersionUID = -2192461924304841222L;

    static EventClientNotificationMqMsg from(Event event) {
        EventClientNotificationMqMsg message = new EventClientNotificationMqMsg();
        message.setClientId(event.getClientId());
        message.setDetails(event.getDetails());
        message.setError(event.getError());
        message.setIpAddress(event.getIpAddress());
        message.setRealmId(event.getRealmId());
        message.setSessionId(event.getSessionId());
        message.setTime(event.getTime());
        message.setType(event.getType());
        message.setUserId(event.getUserId());
        return message;
    }
}

