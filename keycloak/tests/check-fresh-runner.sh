#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
MISSING_IMAGE="account-keycloak-definitely-missing-$RANDOM-$$"
INTEGRATION_COMPOSE="$SCRIPT_DIR/docker-compose.integration.yml"

fail() {
  printf 'fresh-runner validation failure: %s\n' "$1" >&2
  exit 1
}

if docker image inspect "$MISSING_IMAGE" >/dev/null 2>&1; then
  fail "fixture image unexpectedly exists: $MISSING_IMAGE"
fi

# CI's stock runner contract is bash plus standard Unix tools. Keep local-only
# conveniences such as ripgrep out of every executable verification script.
for verification_script in "$SCRIPT_DIR"/*.sh; do
  [[ $verification_script == "$SCRIPT_DIR/check-fresh-runner.sh" ]] && continue
  if grep -Eq '(^|[[:space:];|&()])rg([[:space:]]|$)' "$verification_script"; then
    fail "verification script has an undeclared ripgrep dependency: $verification_script"
  fi
done

# This check is intentionally executed with a missing candidate. Static/render
# validation must complete before any workflow build step on a fresh runner.
KEYCLOAK_TEST_IMAGE="$MISSING_IMAGE" \
  "$SCRIPT_DIR/check-production-compose.sh" >/dev/null

# Runtime checks must never silently select a conventional local tag. The
# already-built candidate is an explicit input shared by all fixture services.
if env -u KEYCLOAK_TEST_IMAGE \
  docker compose -f "$INTEGRATION_COMPOSE" config --quiet >/dev/null 2>&1; then
  fail 'integration Compose accepted a missing KEYCLOAK_TEST_IMAGE'
fi
grep -Fq 'TEST_IMAGE=${KEYCLOAK_TEST_IMAGE:?' "$SCRIPT_DIR/run-integration.sh" \
  || fail 'integration runner does not require the exact candidate image'

ruby -ryaml - "$REPOSITORY_ROOT" <<'RUBY'
root = ARGV.fetch(0)

def assert_order(workflow, job_name)
  document = YAML.load_file(workflow, aliases: true)
  job = document.fetch("jobs").fetch(job_name)
  steps = job.fetch("steps")
  static_index = steps.index do |step|
    step.fetch("run", "").include?("keycloak/tests/check-fresh-runner.sh")
  end
  build_index = steps.index do |step|
    step["uses"] == "docker/build-push-action@v7"
  end
  integration_index = steps.index do |step|
    step.fetch("run", "").include?("keycloak/tests/run-integration.sh")
  end

  unless static_index && build_index && integration_index &&
      static_index < build_index && build_index < integration_index
    abort "#{workflow} #{job_name} must run fresh-runner static checks, then build, then integration"
  end

  build = steps.fetch(build_index).fetch("with")
  abort "#{workflow} #{job_name} must load the tested candidate locally" unless build["load"] == true
  test_image = job.fetch("env").fetch("KEYCLOAK_TEST_IMAGE")
  if test_image.to_s.empty?
    abort "#{workflow} #{job_name} must name the candidate image explicitly"
  end
  unless build["tags"] == "${{ env.KEYCLOAK_TEST_IMAGE }}"
    abort "#{workflow} #{job_name} must build the exact KEYCLOAK_TEST_IMAGE used by integration"
  end
  if steps.fetch(integration_index).fetch("env", {}).key?("KEYCLOAK_TEST_IMAGE")
    abort "#{workflow} #{job_name} must not override the job's tested candidate in the integration step"
  end
end

assert_order(File.join(root, ".github/workflows/keycloak-ci.yml"), "integration")
assert_order(File.join(root, ".github/workflows/deploy.yml"), "keycloak-build")
RUBY

printf 'Fresh-runner portability, explicit candidate wiring and workflow order checks passed.\n'
