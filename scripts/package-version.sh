#!/usr/bin/env bash
set -euo pipefail

package_ref="${PARTNER_SYNC_PACKAGE:-PartnerSync}"
dev_hub="${PARTNER_SYNC_DEV_HUB:-}"
definition_file="${PARTNER_SYNC_DEFINITION_FILE:-config/package-test-scratch-def.json}"
calculate_coverage="${PARTNER_SYNC_CODE_COVERAGE:-true}"

if [[ ! -f "${definition_file}" ]]; then
  echo "Package definition file not found: ${definition_file}" >&2
  exit 1
fi

args=(
  package version create
  --package "${package_ref}"
  --definition-file "${definition_file}"
  --installation-key-bypass
  --wait "${PARTNER_SYNC_PACKAGE_WAIT_MINUTES:-60}"
)

if [[ "${calculate_coverage}" == "true" ]]; then
  args+=(--code-coverage)
elif [[ "${calculate_coverage}" != "false" ]]; then
  echo "PARTNER_SYNC_CODE_COVERAGE must be true or false." >&2
  exit 1
fi

if [[ -n "${dev_hub}" ]]; then
  args+=(--target-dev-hub "${dev_hub}")
fi

sf "${args[@]}"
