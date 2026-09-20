#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
KEYCLOAK_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

KEYCLOAK_VERSION=26.7.4
KEYCLOAK_IMAGE="quay.io/keycloak/keycloak:$KEYCLOAK_VERSION@sha256:82a77884f3af238beab1e7afd63b5f530e1b5c0590bd7aa60b40a40463e29b2c"
MAVEN_IMAGE='maven:3.9.11-eclipse-temurin-21@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237'
NODE_IMAGE='node:22.22.1-bookworm-slim@sha256:4f77a690f2f8946ab16fe1e791a3ac0667ae1c3575c3e4d0d4589e9ed5bfaf3d'
POSTGRES_IMAGE='postgres:17.6-alpine@sha256:ef257d85f76e48da1c64832459b59fcaba1a4dac97bf5d7450c77753542eee94'
RABBITMQ_IMAGE='rabbitmq:4.2-management-alpine@sha256:643139a7e9b4d7e2c1d6a06295d0296c3c58e5de7666a09630b4564a15c951cd'
KEYCLOAK_CI="$KEYCLOAK_DIR/../.github/workflows/keycloak-ci.yml"

fail() {
  printf 'version consistency failure: %s\n' "$1" >&2
  exit 1
}

dockerfile_image=$(sed -n 's/^ARG KEYCLOAK_IMAGE=//p' "$KEYCLOAK_DIR/Dockerfile")
[[ $dockerfile_image == "$KEYCLOAK_IMAGE" ]] \
  || fail 'Dockerfile Keycloak tag and digest are not the approved atomic reference'
if grep -q '^ARG KEYCLOAK_VERSION=' "$KEYCLOAK_DIR/Dockerfile"; then
  fail 'Dockerfile must not allow a version-only Keycloak override'
fi

for pom in "$KEYCLOAK_DIR/spi/pom.xml" "$KEYCLOAK_DIR/rabbitmq-provider/pom.xml"; do
  pom_version=$(sed -n 's:.*<keycloak.version>\([^<]*\)</keycloak.version>.*:\1:p' "$pom")
  [[ $pom_version == "$KEYCLOAK_VERSION" ]] \
    || fail "$pom does not use Keycloak $KEYCLOAK_VERSION"
done

grep -Fq 'x-keycloak-image: &keycloak-image ghcr.io/skylab-kulubu/e-skylab-keycloak@sha256:${KEYCLOAK_IMAGE_DIGEST:?' \
  "$KEYCLOAK_DIR/docker-compose.yml" \
  || fail 'production compose does not hardcode the approved repository and require a digest'
if grep -Eq 'KEYCLOAK_IMAGE_REPOSITORY' \
  "$KEYCLOAK_DIR/docker-compose.yml" \
  "$KEYCLOAK_DIR/docker-compose.bootstrap.yml" \
  "$KEYCLOAK_DIR/.env.example"; then
  fail 'production repository must not be operator-overridable'
fi
if grep -Eq 'KEYCLOAK_IMAGE_REF' \
  "$KEYCLOAK_DIR/docker-compose.yml" \
  "$KEYCLOAK_DIR/docker-compose.bootstrap.yml" \
  "$KEYCLOAK_DIR/.env.example" \
  "$KEYCLOAK_DIR/README.md"; then
  fail 'legacy tag-or-digest KEYCLOAK_IMAGE_REF must not remain'
fi
if grep -Eq '^[[:space:]]+build:' "$KEYCLOAK_DIR/docker-compose.yml"; then
  fail 'production compose must be pull-only; local builds belong in the override'
fi
grep -Fq "KEYCLOAK_IMAGE: \${KEYCLOAK_BASE_IMAGE_REF:-$KEYCLOAK_IMAGE}" \
  "$KEYCLOAK_DIR/docker-compose.build.yml" \
  || fail 'local build override does not use the approved atomic Keycloak base reference'

grep -Fqx "FROM $MAVEN_IMAGE AS providers" "$KEYCLOAK_DIR/Dockerfile" \
  || fail 'Maven builder image is not digest-pinned'
grep -Fqx "ARG NODE_IMAGE=$NODE_IMAGE" "$KEYCLOAK_DIR/Dockerfile" \
  || fail 'Node builder image is not the approved atomic tag and digest'
grep -Fqx 'COPY --from=theme --chown=keycloak:keycloak --chmod=0644 /build/theme/dist_keycloak/e-skylab-theme-2.0.0.jar /opt/keycloak/providers/e-skylab-theme-2.0.0.jar' "$KEYCLOAK_DIR/Dockerfile" \
  || fail 'optimized image does not install the one source-built SKY LAB theme'
if grep -Fq 'providers/e-skylab-theme-1.1.1.jar' "$KEYCLOAK_DIR/Dockerfile"; then
  fail 'optimized image still installs the source-less legacy theme'
fi

for compose_file in "$KEYCLOAK_DIR/docker-compose.yml" "$SCRIPT_DIR/docker-compose.integration.yml"; do
  grep -Fq "image: $POSTGRES_IMAGE" "$compose_file" \
    || fail "$compose_file does not use the approved digest-pinned PostgreSQL image"
done

grep -Fq "image: $RABBITMQ_IMAGE" "$SCRIPT_DIR/docker-compose.integration.yml" \
  || fail 'integration RabbitMQ image is not digest-pinned'

[[ $(grep -Fc -- '- ".github/workflows/deploy.yml"' "$KEYCLOAK_CI") == 2 ]] \
  || fail 'Keycloak CI must gate deploy workflow changes on pull request and main push'

printf 'Keycloak and fixture image versions are consistent.\n'
