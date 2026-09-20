package com.github.aznamier.keycloak.event.provider;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RabbitMqConfigTest {

    @Test
    void normalizesRoutingKeySegments() {
        assertEquals("e-skylab_org", RabbitMqConfig.normalize("e-skylab org!"));
    }

    @Test
    void removesDotsFromTopicSegments() {
        assertEquals("myyildizskylabcom", RabbitMqConfig.withoutDots("my.yildizskylab.com"));
    }
}

