# syntax=docker/dockerfile:1.7

ARG KEYCLOAK_IMAGE=quay.io/keycloak/keycloak:26.7.4@sha256:82a77884f3af238beab1e7afd63b5f530e1b5c0590bd7aa60b40a40463e29b2c

FROM maven:3.9.11-eclipse-temurin-21@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237 AS providers

WORKDIR /build/spi
COPY spi/pom.xml ./pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn --batch-mode --no-transfer-progress dependency:go-offline
COPY spi/src ./src
RUN --mount=type=cache,target=/root/.m2 mvn --batch-mode --no-transfer-progress verify

WORKDIR /build/rabbitmq-provider
COPY rabbitmq-provider/pom.xml ./pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn --batch-mode --no-transfer-progress dependency:go-offline
COPY rabbitmq-provider/src ./src
RUN --mount=type=cache,target=/root/.m2 mvn --batch-mode --no-transfer-progress verify

FROM ${KEYCLOAK_IMAGE} AS builder

ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true \
    KC_FEATURES=account-api:v1,account:v3,par:v1,passkeys:v1,web-authn:v1

COPY --from=providers --chown=keycloak:keycloak --chmod=0644 /build/spi/target/e-skylab-spi-1.7.0.jar /opt/keycloak/providers/e-skylab-spi-1.7.0.jar
COPY --from=providers --chown=keycloak:keycloak --chmod=0644 /build/rabbitmq-provider/target/keycloak-to-rabbit-3.1.0.jar /opt/keycloak/providers/keycloak-to-rabbit-3.1.0.jar
COPY --chown=keycloak:keycloak --chmod=0644 providers/e-skylab-theme-1.1.1.jar /opt/keycloak/providers/e-skylab-theme-1.1.1.jar

# Keep provider mtimes stable across Docker implementations. Keycloak records them
# while augmenting the optimized image and checks them again at runtime.
RUN touch -m --date=@1789833600 /opt/keycloak/providers/*.jar && \
    /opt/keycloak/bin/kc.sh build

FROM ${KEYCLOAK_IMAGE}

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY --chown=keycloak:keycloak --chmod=0555 config /opt/keycloak/config

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
