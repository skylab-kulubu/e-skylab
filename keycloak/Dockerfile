# syntax=docker/dockerfile:1.7

ARG KEYCLOAK_IMAGE=quay.io/keycloak/keycloak:26.7.4@sha256:82a77884f3af238beab1e7afd63b5f530e1b5c0590bd7aa60b40a40463e29b2c
ARG NODE_IMAGE=node:22.22.1-bookworm-slim@sha256:4f77a690f2f8946ab16fe1e791a3ac0667ae1c3575c3e4d0d4589e9ed5bfaf3d

FROM ${NODE_IMAGE} AS node-runtime

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

FROM maven:3.9.11-eclipse-temurin-21@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237 AS theme

COPY --from=node-runtime /usr/local/ /usr/local/
WORKDIR /build/theme
COPY theme/package.json theme/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --ignore-scripts
COPY theme/index.html theme/tsconfig.json theme/vite.config.ts theme/vitest.config.ts ./
COPY theme/scripts ./scripts
COPY theme/src ./src
RUN npm test && npm run build-keycloak-theme && \
    test "$(find dist_keycloak -maxdepth 1 -type f -name '*.jar' | wc -l | tr -d ' ')" = 1 && \
    test -f dist_keycloak/e-skylab-theme-2.0.0.jar

FROM ${KEYCLOAK_IMAGE} AS builder

ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true \
    KC_FEATURES=account-api:v1,account:v3,par:v1,passkeys:v1,web-authn:v1

COPY --from=providers --chown=keycloak:keycloak --chmod=0644 /build/spi/target/e-skylab-spi-1.8.0.jar /opt/keycloak/providers/e-skylab-spi-1.8.0.jar
COPY --from=providers --chown=keycloak:keycloak --chmod=0644 /build/rabbitmq-provider/target/keycloak-to-rabbit-3.1.0.jar /opt/keycloak/providers/keycloak-to-rabbit-3.1.0.jar
COPY --from=theme --chown=keycloak:keycloak --chmod=0644 /build/theme/dist_keycloak/e-skylab-theme-2.0.0.jar /opt/keycloak/providers/e-skylab-theme-2.0.0.jar

# Keep provider mtimes stable across Docker implementations. Keycloak records them
# while augmenting the optimized image and checks them again at runtime.
RUN touch -m --date=@1789833600 /opt/keycloak/providers/*.jar && \
    /opt/keycloak/bin/kc.sh build

FROM ${KEYCLOAK_IMAGE}

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY --chown=keycloak:keycloak --chmod=0555 config /opt/keycloak/config

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
