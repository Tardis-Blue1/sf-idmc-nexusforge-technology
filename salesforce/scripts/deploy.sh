#!/usr/bin/env bash
# Deploy NexusForge Salesforce metadata to a target org.
# Requires Salesforce CLI (sf). Secrets/Named Credential passwords are NOT set here.
set -euo pipefail

TARGET_ORG=""
DRY_RUN=0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "Usage: $0 --target-org <alias> [--dry-run]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-org) TARGET_ORG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) usage ;;
  esac
done

[[ -n "$TARGET_ORG" ]] || usage

echo "[NexusForge] Deploying Salesforce metadata from ${ROOT} to ${TARGET_ORG}"
echo "[NexusForge] Platforms: Salesforce (engagement) + Informatica IDMC (golden keys via Named Credential IDMC_CAI_API)"

ARGS=(project deploy start --source-dir "${ROOT}/force-app" --target-org "${TARGET_ORG}" --wait 30)
if [[ "$DRY_RUN" -eq 1 ]]; then
  ARGS+=(--dry-run)
fi

sf "${ARGS[@]}"
echo "[NexusForge] Deploy complete. Configure Named Credential IDMC_CAI_API credentials in the org (vault-injected)."
