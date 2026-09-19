#!/usr/bin/env bash
set -euo pipefail

target_org="${PARTNER_SYNC_TARGET_ORG:-psync-dev}"
deploy_org_config="${PARTNER_SYNC_DEPLOY_ORG_CONFIG:-false}"

if [[ "${deploy_org_config}" != "true" && "${deploy_org_config}" != "false" ]]; then
  echo "PARTNER_SYNC_DEPLOY_ORG_CONFIG must be true or false." >&2
  exit 1
fi

npm run validate:project

source_args=(--source-dir force-app)
if [[ "${deploy_org_config}" == "true" ]]; then
  source_args+=(--source-dir org-config)
fi

sf project deploy start \
  "${source_args[@]}" \
  --target-org "${target_org}" \
  --test-level RunLocalTests \
  --wait "${PARTNER_SYNC_DEPLOY_WAIT_MINUTES:-90}"
