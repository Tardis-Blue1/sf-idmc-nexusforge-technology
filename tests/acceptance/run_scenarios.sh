#!/usr/bin/env bash
# Stepwise acceptance runner mirroring NexusForge UAT scenarios.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT}"

echo "=== NexusForge acceptance: Salesforce + Informatica IDMC ==="

echo "[1/5] Integration — Stripe subscription sync process present"
test -f idmc/cai/stripe-subscription-sync.yaml

echo "[2/5] MDM — hierarchy + match rules present"
test -f idmc/mdm/hierarchy.yaml && test -f idmc/mdm/match-rules.yaml

echo "[3/5] Governance — deny raw Stripe tokens"
grep -q "deny-raw-stripe-tokens-to-agents" idmc/catalog/policies.yaml

echo "[4/5] Device RMA — DQ referential integrity + CAI rma_gate"
grep -q "device_must_map_to_account" idmc/dq/referential-integrity.yaml
grep -q "rma_gate" idmc/cai/agent-writeback-api.yaml

echo "[5/5] Tenant isolation script"
infra/scripts/seed-sample-data.sh >/dev/null
infra/scripts/validate-tenant-isolation.sh

if command -v pytest >/dev/null 2>&1; then
  pytest tests/acceptance tests/integration -q
else
  echo "pytest not installed; structural checks passed. pip install pytest pyyaml to run full suite."
fi

echo "=== ACCEPTANCE PASSED ==="
