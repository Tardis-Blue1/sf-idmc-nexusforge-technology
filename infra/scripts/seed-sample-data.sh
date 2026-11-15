#!/usr/bin/env bash
# Seed sample NexusForge CRM/device/entitlement fixtures for non-prod demos.
# Uses Salesforce CLI when available; otherwise writes local JSON fixtures for tests.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT}/tests/fixtures"
TARGET_ORG="${TARGET_ORG:-}"
mkdir -p "${OUT_DIR}"

CORRELATION_ID="nf-seed-$(date -u +%Y%m%d%H%M%S)"

cat > "${OUT_DIR}/sample-accounts.json" << EOF
[
  {
    "Name": "Acme Observability Co",
    "GoldenAccountKey__c": "GAK-ACME-001",
    "ForgeObserveOrgId__c": "org_acme_001",
    "NetSuiteCustomerId__c": "NS-10001",
    "MDMSurvivorshipSource__c": "netsuite_erp",
    "correlationId": "${CORRELATION_ID}"
  },
  {
    "Name": "Acme Observability Co (Self-Serve)",
    "GoldenAccountKey__c": "GAK-ACME-PLG-001",
    "ForgeObserveOrgId__c": "org_acme_plg",
    "MDMSurvivorshipSource__c": "forgeobserve_control_plane",
    "correlationId": "${CORRELATION_ID}"
  }
]
EOF

cat > "${OUT_DIR}/sample-devices.json" << EOF
[
  {
    "Name": "FE-10001",
    "Serial__c": "FE-10001",
    "Firmware__c": "3.2.1",
    "TenantOrgId__c": "org_acme_001",
    "Status__c": "Active",
    "GoldenDeviceKey__c": "GDK-FE-10001",
    "MDMMatchConfidence__c": 99.2,
    "correlationId": "${CORRELATION_ID}"
  }
]
EOF

cat > "${OUT_DIR}/sample-entitlements.json" << EOF
[
  {
    "Name": "sub_acme_enterprise",
    "Tier__c": "Enterprise",
    "StripeSubId__c": "sub_acme_enterprise",
    "Status__c": "Active",
    "GoldenEntitlementKey__c": "GEK-ACME-ENT-001",
    "SKUCode__c": "FO-ENT-SAAS",
    "ProductFamily__c": "SaaS",
    "GoldenProductKey__c": "GPK-FO-ENT",
    "correlationId": "${CORRELATION_ID}"
  }
]
EOF

echo "[NexusForge] Wrote sample fixtures to ${OUT_DIR} (correlation=${CORRELATION_ID})"
echo "[NexusForge] Platforms labeled: Salesforce engagement objects + Informatica IDMC golden keys"

if [[ -n "${TARGET_ORG}" ]] && command -v sf >/dev/null 2>&1; then
  echo "[NexusForge] TARGET_ORG set — load fixtures via Apex / data import in the org as a follow-on step."
  echo "[NexusForge] Prefer NexusForgeMDMKeyService / NexusForgeEntitlementService for idempotent upserts."
else
  echo "[NexusForge] No Salesforce CLI target; fixtures ready for pytest mocks."
fi
