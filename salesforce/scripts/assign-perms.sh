#!/usr/bin/env bash
# Assign NexusForge permission sets to a Salesforce user.
set -euo pipefail

TARGET_ORG=""
USER_NAME=""

usage() {
  echo "Usage: $0 --target-org <alias> --user <username>"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-org) TARGET_ORG="$2"; shift 2 ;;
    --user) USER_NAME="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$TARGET_ORG" && -n "$USER_NAME" ]] || usage

PERMS=(
  NexusForge_Agent_Read
  NexusForge_Integration_User
  NexusForge_Data_Steward
)

echo "[NexusForge] Assigning Salesforce permission sets to ${USER_NAME} in ${TARGET_ORG}"
for ps in "${PERMS[@]}"; do
  echo "  -> ${ps}"
  sf org assign permset --name "${ps}" --target-org "${TARGET_ORG}" --on-behalf-of "${USER_NAME}" || \
    sf org assign permset --name "${ps}" --target-org "${TARGET_ORG}"
done
echo "[NexusForge] Permission set assignment finished."
