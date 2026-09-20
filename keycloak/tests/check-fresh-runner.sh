#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
MISSING_IMAGE="account-keycloak-definitely-missing-$RANDOM-$$"

if docker image inspect "$MISSING_IMAGE" >/dev/null 2>&1; then
  printf 'fresh-runner fixture image unexpectedly exists: %s\n' "$MISSING_IMAGE" >&2
  exit 1
fi

# This check is intentionally executed with a missing candidate. Static/render
# validation must complete before any workflow build step on a fresh runner.
KEYCLOAK_TEST_IMAGE="$MISSING_IMAGE" \
  "$SCRIPT_DIR/check-production-compose.sh" >/dev/null

ruby -ryaml - "$REPOSITORY_ROOT" <<'RUBY'
root = ARGV.fetch(0)

def assert_order(workflow, job_name)
  document = YAML.load_file(workflow, aliases: true)
  steps = document.fetch("jobs").fetch(job_name).fetch("steps")
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
end

assert_order(File.join(root, ".github/workflows/keycloak-ci.yml"), "integration")
assert_order(File.join(root, ".github/workflows/deploy.yml"), "keycloak-build")
RUBY

printf 'Fresh-runner static checks precede candidate build and runtime integration.\n'
