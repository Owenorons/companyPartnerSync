#!/usr/bin/env bash
set -euo pipefail

sf org create scratch \
  -f config/project-scratch-def.json \
  -a "${PARTNER_SYNC_SCRATCH_ALIAS:-psync-dev}" \
  -d \
  -y "${PARTNER_SYNC_SCRATCH_DAYS:-7}"
