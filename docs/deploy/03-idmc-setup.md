# Deploy 03 — IDMC Setup

**Solutions:** Salesforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CDI, CAI, MDM, Data Quality, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 03 — IDMC Setup |
| Version | 1.0 |
| Depends on | [01-prerequisites.md](./01-prerequisites.md), [02-salesforce-setup.md](./02-salesforce-setup.md) |

---

## 1. Purpose

Stand up Informatica IDMC as the trust fabric: runtime, connections, CDI/CAI projects, MDM models and match rules, DQ rule packs, and Catalog data products with agent policies. Domain connector wiring continues in [04-integrations.md](./04-integrations.md); this runbook establishes the foundation.

Repo assets: `idmc/cai/`, `idmc/cdi/`, `idmc/mdm/`, `idmc/dq/`, `idmc/catalog/`.

---

## 2. Org and runtime

1. Confirm IDMC non-prod org URL and admin SSO via Okta.
2. Create folders/projects:
   - `NF_CDI_Core`
   - `NF_CAI_Events`
   - `NF_CAI_Agent_APIs`
   - `NF_MDM_Customer_Product_Device`
   - `NF_DQ_Pilot`
   - `NF_Catalog_Pilot`
3. Provision runtime / Secure Agent group if Device Registry requires private connectivity (`NF_SecureAgent_NonProd`).
4. Configure Git/export discipline: export process JSON/YAML stubs into repo after each approved change.

---

## 3. Connections (stubs → validated)

Create connections with secrets from vault (names from prerequisites):

| Connection name | Type | Target |
| --- | --- | --- |
| `conn_salesforce_uat` | Salesforce | Sandbox |
| `conn_stripe_test` | REST | Stripe API |
| `conn_netsuite_sb` | NetSuite | Sandbox |
| `conn_zendesk_sb` | REST | Zendesk |
| `conn_forgeobserve_np` | REST | Control plane |
| `conn_device_registry_np` | REST | Registry (± Secure Agent) |
| `conn_snowflake_np` | Snowflake | Non-prod |
| `conn_datacloud` | Via SF / ingestion | As licensed |

**Validation:** Test connection for each; capture screenshot/log in engagement evidence folder (internal ops).

---

## 4. CDI foundation

1. Import mapping specs from `idmc/cdi/` (Account, Contact, Product, Subscription staging, Device, Snowflake publish).
2. Create parameter files per environment (`env_nonprod.param`).
3. Build schedules:
   - Nightly NetSuite reconcile
   - Hourly Snowflake publish of match/DQ metrics
   - On-demand initial load taskflow
4. Enable job monitoring notifications to Platform Ops channel.

---

## 5. CAI foundation

1. Import process definitions from `idmc/cai/`:
   - `prc_stripe_webhook_subscription`
   - `prc_device_bind_event`
   - `prc_forgeobserve_entitlement`
   - `prc_agent_get_account360`
   - `prc_agent_get_entitlements`
   - `prc_agent_get_device_fleet`
   - `prc_agent_propose_rma`
   - `prc_agent_get_renewal_brief`
2. Configure API gateway endpoints; note URLs for Salesforce Named Credentials.
3. Implement correlation ID middleware: accept/generate `X-NF-Correlation-Id`.
4. Wire DLQ / fault paths for Stripe and Device processes.

---

## 6. MDM stand-up

### 6.1 Models

Import/create business entities per [02-data-model-mdm.md](../02-data-model-mdm.md):

- Account/Customer  
- Contact/User  
- Subscription/Entitlement  
- Product/SKU  
- Device/Asset  

Include crosswalk attribute groups and hierarchy (parent Account).

### 6.2 Match rules

Load rule packs from `idmc/mdm/`:

- Account: Stripe/NetSuite ID exact; domain+country; fuzzy name  
- Contact: email+Account; Auth0 subject  
- Device: serial exact  
- Product: Stripe price / NetSuite item  
- Subscription: Stripe subscription ID  

Set suspect thresholds (0.85–0.94) and auto thresholds (≥0.95) as documented.

### 6.3 Survivorship

Configure attribute-level rules (NetSuite legal name, Salesforce AE owner, Stripe subscription status, latest verified device bind, etc.).

### 6.4 Initial load

1. Run CDI initial extract from Salesforce sample + Device Registry sample + Stripe test customers.
2. Load sequence: Product → Account → Contact → Subscription → Device.
3. Verify golden ID generation and publish job to Salesforce golden fields.
4. Measure baseline duplicate rate on top logos sample.

---

## 7. Data Quality

1. Import rule packs from `idmc/dq/`:
   - Completeness (IDs, domain)
   - Validity (`billing_status` enum, firmware allowlist)
   - Uniqueness (serial)
   - Referential (Device→Account)
2. Configure quarantine tables/queues and steward notifications.
3. Link DQ status attributes to MDM publish and Catalog certification.
4. **Critical:** ensure Agent APIs filter `DQ_Status != Certified`.

---

## 8. Catalog and Governance

1. Register data products from `idmc/catalog/`:
   - `dp.customer.golden`
   - `dp.device.fleet`
   - `dp.entitlement.active`
2. Assign owners, SLAs, sensitivity tags.
3. Implement policy `POL-AGENT-DENY-STRIPE-TOKEN` on payment-restricted attributes.
4. Enable lineage harvesting for CDI/CAI/MDM jobs.
5. Certify pilot products after DQ baseline green.

---

## 9. Observability hooks

| Signal | Destination |
| --- | --- |
| CDI/CAI job success | IDMC monitor + webhook to ops |
| MDM match % | Snowflake metrics table + dashboard |
| DQ fail rate | Same |
| Agent allow/deny | CAI logs → metrics |

---

## 10. Exit checklist

- [ ] Projects/folders created; Secure Agent decision executed
- [ ] All connections test successful (or waived with ticket)
- [ ] CDI mappings + schedules deployed
- [ ] CAI processes deployed; agent API URLs recorded
- [ ] MDM models, match, survivorship active
- [ ] Initial sample load completed; golden IDs in Salesforce
- [ ] DQ packs active; quarantine path tested with fixture
- [ ] Three data products registered; token deny policy active
- [ ] Lineage visible for pilot attributes
- [ ] Correlation ID verified on sample CAI run

**Next:** [04-integrations.md](./04-integrations.md)

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
