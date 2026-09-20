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

release_gate="$SCRIPT_DIR/check-physical-webauthn-release.sh"
fake_commit=0123456789abcdef0123456789abcdef01234567
if GITHUB_SHA="$fake_commit" "$release_gate" >/dev/null 2>&1; then
  fail 'physical WebAuthn release gate accepted missing evidence'
fi
if GITHUB_SHA="$fake_commit" \
  PHYSICAL_WEBAUTHN_APPROVED_COMMIT=ffffffffffffffffffffffffffffffffffffffff \
  PHYSICAL_WEBAUTHN_EVIDENCE_URL=https://evidence.example.invalid/keycloak \
  PHYSICAL_WEBAUTHN_APPROVED_SURFACES=touch-id,face-id \
  "$release_gate" >/dev/null 2>&1; then
  fail 'physical WebAuthn release gate accepted evidence for another commit'
fi
if GITHUB_SHA="$fake_commit" \
  PHYSICAL_WEBAUTHN_APPROVED_COMMIT="$fake_commit" \
  PHYSICAL_WEBAUTHN_EVIDENCE_URL=https://evidence.example.invalid/keycloak \
  PHYSICAL_WEBAUTHN_APPROVED_SURFACES=touch-id,face-id,android-credential-manager,windows-hello,mobile-webview \
  "$release_gate" >/dev/null 2>&1; then
  fail 'physical WebAuthn release gate accepted untested rollout surfaces'
fi
GITHUB_SHA="$fake_commit" \
  PHYSICAL_WEBAUTHN_APPROVED_COMMIT="$fake_commit" \
  PHYSICAL_WEBAUTHN_EVIDENCE_URL=https://evidence.example.invalid/keycloak \
  PHYSICAL_WEBAUTHN_APPROVED_SURFACES=touch-id,face-id \
  "$release_gate" >/dev/null

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

def assert_release_boundary(workflow)
  document = YAML.load_file(workflow, aliases: true)
  build_job = document.fetch("jobs").fetch("keycloak-build")
  publish_job = document.fetch("jobs").fetch("keycloak-publish")
  build_steps = build_job.fetch("steps")
  publish_steps = publish_job.fetch("steps")

  if build_job.fetch("permissions", {}).fetch("packages", nil) == "write"
    abort "#{workflow} keycloak-build must not receive package-write permission"
  end
  unless publish_job.fetch("permissions", {}).fetch("packages", nil) == "write"
    abort "#{workflow} keycloak-publish must own the package-write permission"
  end
  unless publish_job.fetch("needs", nil) == "keycloak-build"
    abort "#{workflow} keycloak-publish must depend on the tested and physically approved build job"
  end

  integration_index = build_steps.index { |step| step.fetch("run", "").include?("keycloak/tests/run-integration.sh") }
  gate_index = build_steps.index { |step| step.fetch("run", "").include?("keycloak/tests/check-physical-webauthn-release.sh") }
  package_index = build_steps.index { |step| step.fetch("name", "") == "Package the tested image bytes" }
  upload_index = build_steps.index { |step| step.fetch("uses", "") == "actions/upload-artifact@v4" }
  unless integration_index && gate_index && package_index && upload_index &&
      integration_index < gate_index && gate_index < package_index && package_index < upload_index
    abort "#{workflow} must test, physically approve, package and upload the candidate in that order"
  end

  upload = build_steps.fetch(upload_index).fetch("with")
  unless upload["name"] == "keycloak-candidate-${{ github.sha }}" && upload["retention-days"] == 1
    abort "#{workflow} must bind the short-lived candidate artifact to the release commit"
  end

  download_index = publish_steps.index { |step| step.fetch("uses", "") == "actions/download-artifact@v5" }
  verify_index = publish_steps.index { |step| step.fetch("name", "") == "Verify and load the tested candidate" }
  login_index = publish_steps.index { |step| step.fetch("uses", "") == "docker/login-action@v4" }
  publish_index = publish_steps.index { |step| step.fetch("name", "") == "Publish the tested image bytes" }
  unless download_index && verify_index && login_index && publish_index &&
      download_index < verify_index && verify_index < login_index && login_index < publish_index
    abort "#{workflow} keycloak-publish must verify the transferred bytes before registry login and publication"
  end

  verification = publish_steps.fetch(verify_index).fetch("run", "")
  for required_check in ["commit-sha", "sha256sum --check", "image-id", "e-skylab-theme-*.jar", "check-theme-contract.sh"]
    unless verification.include?(required_check)
      abort "#{workflow} publish verification is missing #{required_check}"
    end
  end
  if publish_steps.any? { |step| step["uses"] == "docker/build-push-action@v7" }
    abort "#{workflow} keycloak-publish must load the tested artifact, not rebuild it"
  end

  publication = publish_steps.fetch(publish_index).fetch("run", "")
  for alias_name in ["latest", "main", "production"]
    unless publication.include?(%($PUBLISH_IMAGE:#{alias_name}))
      abort "#{workflow} tested Keycloak release must publish the #{alias_name} alias"
    end
  end
  unless publication.include?('published_images=(') &&
      publication.include?('docker image inspect') &&
      publication.include?('docker buildx imagetools inspect --raw') &&
      publication.include?('test "$version_digest" = "$alias_digest"')
    abort "#{workflow} all release aliases must be bound to the tested image ID and manifest digest"
  end
end

assert_order(File.join(root, ".github/workflows/keycloak-ci.yml"), "integration")
assert_order(File.join(root, ".github/workflows/deploy.yml"), "keycloak-build")
assert_release_boundary(File.join(root, ".github/workflows/deploy.yml"))
RUBY

printf 'Fresh-runner portability, explicit candidate wiring and workflow order checks passed.\n'
