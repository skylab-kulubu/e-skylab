package com.github.aznamier.keycloak.event.provider;

import com.fasterxml.jackson.annotation.JsonTypeInfo;
import org.keycloak.events.admin.AdminEvent;

import java.io.Serial;
import java.io.Serializable;

@JsonTypeInfo(use = JsonTypeInfo.Id.CLASS)
final class EventAdminNotificationMqMsg extends AdminEvent implements Serializable {

    @Serial
    private static final long serialVersionUID = -7367949289101799624L;

    static EventAdminNotificationMqMsg from(AdminEvent event) {
        EventAdminNotificationMqMsg message = new EventAdminNotificationMqMsg();
        message.setAuthDetails(event.getAuthDetails());
        message.setError(event.getError());
        message.setOperationType(event.getOperationType());
        message.setRealmId(event.getRealmId());
        message.setRepresentation(event.getRepresentation());
        message.setResourcePath(event.getResourcePath());
        message.setResourceType(event.getResourceType());
        message.setResourceTypeAsString(event.getResourceTypeAsString());
        message.setTime(event.getTime());
        return message;
    }
}

