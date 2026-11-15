# Deploy 01 — Prerequisites

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CDI, CAI, MDM, Data Quality, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 01 — Prerequisites |
| Version | 1.0 |
| Phase | Days 0–7 (foundation) |

---

## 1. Purpose

Establish accounts, licenses, identity apps, API credentials, networking, and team access required before Salesforce baseline, IDMC foundation, or integrations. Do not proceed to [02-salesforce-setup.md](./02-salesforce-setup.md) until the checklist in §8 is green.

---

## 2. Environments

| Environment | Salesforce | IDMC | Domain systems |
| --- | --- | --- | --- |
| Dev | Developer/sandbox | Non-prod org / space | Mocks or sandbox APIs |
| Test/UAT | Full sandbox | Non-prod | Stripe test, NetSuite sandbox, ForgeObserve/Device Registry non-prod |
| Prod | Production (later) | Prod | Prod credentials under change control |

**Diagram:** [`diagrams/svg/06-nexusforge-deploy-topology.svg`](../../diagrams/svg/06-nexusforge-deploy-topology.svg)

---

## 3. License and entitlement checklist

### 3.1 Salesforce

| Capability | Non-prod need | Notes |
| --- | --- | --- |
| Sales Cloud | Required | Existing NexusForge assumption |
| Service Cloud | Required for triage/RMA pilots | |
| Data Cloud | Trial/sandbox acceptable for pilot | Identity resolution aligned to MDM keys |
| Agentforce | Pilot licenses / sandbox | Two agents minimum |
| API / Connected App | Required | Integration + Named Credentials |
| Event Monitoring | Recommended | Agent audit |
| Shield | Optional | Per CISO |

### 3.2 Informatica IDMC (Informatica by Salesforce)

| Capability | Non-prod need |
| --- | --- |
| Cloud Data Integration (CDI) | Required |
| Cloud Application Integration (CAI) | Required |
| MDM | Required |
| Data Quality | Required |
| Catalog + Governance / policy | Required |
| Secure Agent rights | If Device Registry private network |

### 3.3 Domain sandboxes

| System | Prerequisite |
| --- | --- |
| Stripe | Test mode account; webhook endpoint capable; restricted API key |
| NetSuite | Sandbox with customer/item sample; token auth |
| Zendesk | Sandbox or sample subdomain |
| ForgeObserve | Non-prod control plane API + service account |
| Device Registry | Non-prod REST + optional private network path |
| Snowflake | Non-prod DB/schema for certified publish |
| Okta | Apps for Salesforce + IDMC admin SSO |
| Auth0 | No agent access to customer tokens—document boundary only |
| Secrets manager | AWS/GCP/Azure vault project for non-prod |

---

## 4. Identity and access

### 4.1 Workforce (Okta)

Create groups:

- `nf-sf-admins`, `nf-sf-integrators`, `nf-sf-stewards-ro`
- `nf-idmc-admins`, `nf-idmc-developers`, `nf-idmc-stewards`
- `nf-agentforce-pilots` (AE/CSM/Support UAT users)

SSO:

1. SAML/OIDC to Salesforce sandbox.
2. SSO to IDMC admin per Informatica guidance.
3. Enforce MFA.

### 4.2 Service principals

| Principal | Use |
| --- | --- |
| `sf-idmc-integration` | Salesforce Connected App for IDMC |
| `cai-stripe-receiver` | Webhook validation |
| `cai-forgeobserve` | Product API |
| `cai-device-registry` | Device API |
| `cdi-netsuite` | ERP |
| `cdi-snowflake` | Analytical publish |
| `agent-actions` | CAI APIs for Agentforce Named Credential |

Store client secrets **only** in secrets manager. Reference via IaC—never commit.

### 4.3 Least privilege

- Stripe key: read subscriptions/customers; no arbitrary charge in pilot.
- Device Registry: read bind + create RMA draft; no global rebind without steward role.
- Salesforce integration user: permission set `NF_Integration_Minimal` (created in SF setup doc).

---

## 5. Networking

| Path | Requirement |
| --- | --- |
| IDMC ↔ Salesforce | Public API + IP allowlisting if required |
| IDMC ↔ Stripe/NetSuite/Zendesk | Public SaaS HTTPS |
| IDMC ↔ ForgeObserve | HTTPS; allowlist IDMC egress IPs |
| IDMC ↔ Device Registry | Prefer private: Secure Agent or Private Link; document in architecture |
| Demo UI ↔ APIs | Non-prod only; VPN or IP restrict |
| CI runners | OIDC to cloud; no long-lived keys in git |

Record egress allowlists in `infra/` docs after first connection test.

---

## 6. Secrets inventory (names only)

Create empty secret slots (values injected by security ops):

```text
nf/nonprod/salesforce/client_id
nf/nonprod/salesforce/client_secret
nf/nonprod/salesforce/refresh_token_or_jwt
nf/nonprod/stripe/api_key
nf/nonprod/stripe/webhook_secret
nf/nonprod/netsuite/token_*
nf/nonprod/zendesk/api_token
nf/nonprod/forgeobserve/client_*
nf/nonprod/device_registry/client_*
nf/nonprod/snowflake/keypair
nf/nonprod/demo_app/session_secret
```

---

## 7. Bootstrap IaC and CI

From repo root:

1. Configure cloud credentials for Terraform backend (non-prod state).
2. Review `infra/terraform/` variables—no prod.
3. `terraform init` && `terraform plan` (apply per change window).
4. Ensure CI workflow can: validate Terraform, run Salesforce org auth via JWT, lint demo-app, execute acceptance stubs.
5. Create artifact registries if needed for demo-app.

Scripts: `infra/scripts/`.

---

## 8. Sample data readiness

| Dataset | Minimum for pilot |
| --- | --- |
| Accounts | 500 with mix of PLG + enterprise hierarchy |
| Contacts | Related bill-to + technical |
| Stripe customers/subscriptions | Matching subset in test mode |
| Devices | ≥200 serials; include intentional DQ mismatch fixtures |
| ForgeObserve orgs | Mapped to Accounts |
| Duplicate fixtures | Known duplicate pair for MDM scenario 2 |
| Token fixture | Synthetic payment token field for deny test (never real PAN) |

---

## 9. Team and RACI for prerequisites

| Task | Owner |
| --- | --- |
| License procurement | EA + procurement |
| Okta apps | IAM |
| Secrets slots | Security ops |
| Sandbox APIs | Product Eng / RevOps |
| Terraform backend | Platform Ops |
| Sign-off | Enterprise Architect |

---

## 10. Exit checklist

- [ ] Salesforce sandbox available with Sales + Service; Data Cloud & Agentforce trial enabled or gap documented
- [ ] IDMC non-prod with CDI, CAI, MDM, DQ, Catalog entitlements confirmed
- [ ] Okta groups and SSO smoke-tested
- [ ] All secret slots created; accessors granted to integration lead
- [ ] Stripe test + webhook URL placeholder ready
- [ ] NetSuite sandbox token issued
- [ ] ForgeObserve + Device Registry non-prod URLs reachable from IDMC (or Secure Agent plan written)
- [ ] Snowflake non-prod schema created
- [ ] Terraform plan succeeds for non-prod
- [ ] Sample/fixture data plan approved by CDO
- [ ] CISO acknowledges Payment-restricted deny requirement

**Next:** [02-salesforce-setup.md](./02-salesforce-setup.md)

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
