# Upstream provenance

This module is derived from
[`aznamier/keycloak-event-listener-rabbitmq`](https://github.com/aznamier/keycloak-event-listener-rabbitmq)
at commit `2f9fdbaa7bed27aecdd4d305c57f33e2d357a61c` (Apache-2.0).

SKY LAB changes pin Keycloak 26.7.4 and Java 21, update the RabbitMQ Java
client, avoid sharing a `Channel` between Keycloak sessions, make shutdown
null-safe and add compatibility tests.

