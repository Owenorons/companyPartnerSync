#!/usr/bin/env bash
set -euo pipefail

sf apex run test \
  --target-org "${PARTNER_SYNC_TARGET_ORG:-psync-dev}" \
  --test-level RunLocalTests \
  --code-coverage \
  --result-format human \
  --wait "${PARTNER_SYNC_TEST_WAIT_MINUTES:-60}"
