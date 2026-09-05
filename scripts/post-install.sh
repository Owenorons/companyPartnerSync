#!/usr/bin/env bash
set -euo pipefail

target_org="${PARTNER_SYNC_TARGET_ORG:-}"
deploy_org_config="${PARTNER_SYNC_DEPLOY_ORG_CONFIG:-false}"
run_tests="${PARTNER_SYNC_RUN_POST_INSTALL_TESTS:-true}"
expected_package_version="${PARTNER_SYNC_EXPECTED_PACKAGE_VERSION:-}"

if [[ -z "${target_org}" ]]; then
  echo "PARTNER_SYNC_TARGET_ORG is required; refusing to use an implicit default org." >&2
  exit 1
fi

if [[ ! "${expected_package_version}" =~ ^04t[A-Za-z0-9]{12,15}$ ]]; then
  echo "PARTNER_SYNC_EXPECTED_PACKAGE_VERSION must be an explicit 04t package version ID." >&2
  exit 1
fi

if [[ "${deploy_org_config}" != "true" && "${deploy_org_config}" != "false" ]]; then
  echo "PARTNER_SYNC_DEPLOY_ORG_CONFIG must be true or false." >&2
  exit 1
fi

if [[ "${run_tests}" != "true" && "${run_tests}" != "false" ]]; then
  echo "PARTNER_SYNC_RUN_POST_INSTALL_TESTS must be true or false." >&2
  exit 1
fi

sf org display --target-org "${target_org}"
sf package installed list --target-org "${target_org}" --json | \
  node scripts/ci/verify-installed-package.js "${expected_package_version}"

if [[ "${deploy_org_config}" == "true" ]]; then
  echo "Deploying reviewed subscriber configuration from org-config."
  sf project deploy start \
    --source-dir org-config \
    --target-org "${target_org}" \
    --wait 30
else
  echo "Skipping org-config. Review subscriber-specific values before enabling it."
fi

sf apex run \
  --file scripts/apex/assign-internal-admin-access.apex \
  --target-org "${target_org}"
sf apex run \
  --file scripts/apex/schedule-partnersync-operations.apex \
  --target-org "${target_org}"
sf apex run \
  --file scripts/apex/post-deployment-smoke.apex \
  --target-org "${target_org}"

if [[ "${run_tests}" == "true" ]]; then
  sf apex run test \
    --target-org "${target_org}" \
    --test-level RunAllTestsInOrg \
    --code-coverage \
    --result-format human \
    --wait 90
fi

echo "Automated PartnerSync post-install checks completed."
echo "Manual sharing, credentials, Experience Cloud, and cross-account isolation checks remain required."
