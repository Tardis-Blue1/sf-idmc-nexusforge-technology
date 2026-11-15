#!/usr/bin/env bash
# Bootstrap NexusForge non-prod supporting infra (secrets refs, optional log bucket, monitors).
# Does not write secret values. Requires Terraform + AWS credentials from the operator vault.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform"
ENV_FILE="${TF_DIR}/envs/nonprod.tfvars"

echo "[NexusForge] Bootstrap IaC for Salesforce + Informatica IDMC supporting resources"
echo "[NexusForge] Terraform dir: ${TF_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[NexusForge] ${ENV_FILE} missing — copying example (edit before apply)"
  cp "${TF_DIR}/envs/nonprod.tfvars.example" "${ENV_FILE}"
fi

cd "${TF_DIR}"
terraform init -input=false
terraform validate
terraform plan -var-file="${ENV_FILE}" -out=tfplan.nonprod

if [[ "${APPLY:-0}" == "1" ]]; then
  terraform apply -auto-approve tfplan.nonprod
  echo "[NexusForge] Apply complete. Populate Secrets Manager values out-of-band."
else
  echo "[NexusForge] Plan written to tfplan.nonprod. Re-run with APPLY=1 to apply."
fi
