# Deploy 04 — Integrations

**Solutions:** Salesforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CAI event processes, CDI CDC/schedules) · domain systems Stripe, NetSuite, Zendesk, ForgeObserve, Device Registry, Snowflake

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 04 — Integrations |
| Version | 1.0 |
| Depends on | [03-idmc-setup.md](./03-idmc-setup.md) |
| Spec | [03-integration-catalog.md](../03-integration-catalog.md) |

---

## 1. Purpose

Wire end-to-end interfaces IF-STRIPE-*, IF-NETSUITE-*, IF-FO-*, IF-DEV-*, IF-ZD-*, IF-SF-CDC-*, IF-SNOW-*, and IF-AGENT-API-* with observability, correlation IDs, and SLA instrumentation. Exit when subscription upgrade path meets &lt;5 min median in non-prod.

---

## 2. Order of enablement

1. Salesforce bidirectional (golden publish + CDC inbound)  
2. Stripe subscription + customer  
3. ForgeObserve entitlement  
4. Device Registry bind/RMA  
5. NetSuite CDC + nightly reconcile  
6. Zendesk sample  
7. Snowflake metrics publish  
8. Agent CAI APIs (smoke; full Agentforce in next doc)  

---

## 3. Salesforce ↔ IDMC

### 3.1 Golden publish

1. CDI/CAI upsert Account/Contact/Device/Entitlement by External ID (`NF_Golden_*` / natural keys).
2. Verify idempotent re-run does not duplicate.
3. Measure upsert latency.

### 3.2 CDC inbound (IF-SF-CDC-07)

1. Subscribe to Account and Contact CDC in CAI/CDI.
2. Map AE owner and hierarchy updates into MDM per survivorship.
3. Confirm correlation ID stamped on processing logs.

---

## 4. Stripe (IF-STRIPE-SUB-01, IF-STRIPE-CUST-02)

1. Create webhook endpoint on CAI process `prc_stripe_webhook_subscription`.
2. Subscribe events: `customer.created`, `customer.subscription.*`, `invoice.paid`, `invoice.payment_failed`.
3. Validate signature with `stripe/webhook_secret`.
4. Map price IDs via Product crosswalk; unknown price → SKU steward queue.
5. **Sanitize:** strip payment method tokens from payloads before any agent-facing store; persist `billing_status` only on Entitlement.
6. Test: upgrade subscription in Stripe test → observe Salesforce Entitlement tier + ForgeObserve flag within SLA.
7. Configure DLQ alarms.

**SLA probe:** script in `tests/integration/` records timestamps at Stripe event, MDM publish, SF upsert, product API.

---

## 5. ForgeObserve entitlement (IF-FO-ENT-04)

1. Configure OAuth/mTLS client from vault.
2. Enable event webhook **or** 5-minute poller fallback.
3. Require `forge_org_id` on all writes; reject missing org.
4. Project seats/feature packages into MDM Entitlement + `Entitlement__c`.
5. Tenant isolation test: attempt cross-org update → expect hard fail.

---

## 6. Device Registry (IF-DEV-BIND-05)

1. If private network: deploy Secure Agent; confirm connectivity.
2. Subscribe bind/unbind/firmware/RMA events.
3. Upsert `Device__c`; set `DQ_Status__c` from DQ service.
4. Seed intentional firmware mismatch fixture for acceptance scenario 4.
5. RMA draft API: map `proposeRma` CAI process; dual-control for cross-Account rebind.

---

## 7. NetSuite (IF-NETSUITE-CUST-03)

1. Enable CDI CDC for customer and item.
2. Map legal name, bill-to, item ↔ SKU.
3. Schedule nightly reconcile; publish drift report to Snowflake + email steward.
4. Confirm survivorship: NetSuite wins legal name when present.

---

## 8. Zendesk sample (IF-ZD-SYNC-06)

1. Limit to pilot org IDs allowlist.
2. Sync users → Contact crosswalk suspects.
3. Optional ticket bridge to Case with golden Account lookup.
4. Do not block go-live on full history.

---

## 9. Snowflake publish (IF-SNOW-PUB-09)

1. Create tables: `nf_match_rates`, `nf_dq_fails`, `nf_integration_lag`, `nf_agent_allow_deny`.
2. Hourly CDI job from IDMC metrics.
3. Grant Looker read role; **no** agent write role.

---

## 10. Agent CAI APIs (IF-AGENT-API-08) — smoke

| Process | Smoke test |
| --- | --- |
| `getAccount360` | Returns golden_account_id + hierarchy |
| `getEntitlements` | Returns billing_status; **omits** tokens |
| `getDeviceFleet` | Filters quarantine unless steward token |
| `proposeRma` | Creates draft for certified device |
| `getRenewalBrief` | Read-only JSON brief |

Point Salesforce Named Credential `NF_CAI_Agent_API` at base URL. Capture OpenAPI/postman collection under `tests/integration/`.

---

## 11. Observability go-live for integrations

- Dashboards: lag P50/P95 per interface, success ratio, DLQ depth, duplicate create rate.  
- Alerts: P50 lag &gt;5 min on Stripe path; success &lt;99.5%; DLQ &gt;0 for 15 min.  
- Log retention ≥1 year for agent-related CAI (compliance).  

---

## 12. Exit checklist

- [ ] Stripe upgrade path median &lt;5 min in non-prod (n≥20 test events)
- [ ] ForgeObserve entitlement updates reflected in Salesforce
- [ ] Device bind updates Device__c; mismatch fixture quarantined
- [ ] NetSuite CDC + nightly reconcile green
- [ ] Zendesk sample linked for pilot Accounts
- [ ] Snowflake metrics tables populated
- [ ] Agent APIs smoke-tested; token fields absent
- [ ] Correlation IDs present in logs end-to-end
- [ ] Alerts routed to Platform Ops
- [ ] Integration catalog interface IDs annotated with endpoint URLs (ops wiki / internal)

**Next:** [05-data-cloud-agentforce.md](./05-data-cloud-agentforce.md)

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
