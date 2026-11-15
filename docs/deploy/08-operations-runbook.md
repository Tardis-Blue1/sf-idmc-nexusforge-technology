# Deploy 08 — Operations Runbook

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CDI, CAI, MDM, Data Quality, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 08 — Operations Runbook |
| Version | 1.0 |
| Audience | Platform Ops, MDM stewards, Salesforce admins, on-call integration engineers |

---

## 1. Purpose

Operate the NexusForge Agentic Customer & Product Data Platform after go-live: monitoring, incident response, replay, stewardship, match-rule change control, DR, and agent policy operations.

---

## 2. Service map

| Service | Criticality | Owner |
| --- | --- | --- |
| IF-STRIPE-SUB-01 path | Sev-1 capable | Integration + RevOps |
| MDM golden publish | Sev-1 | CDO / MDM |
| DQ certification | Sev-2 | Stewards |
| Agent CAI APIs | Sev-1 during business hours for pilot | SF Admin + Integration |
| Device bind / RMA | Sev-2 (Sev-1 if fleet outage) | Product Eng |
| Snowflake metrics | Sev-3 | Data Platform |
| Demo UI | Sev-4 | Delivery (non-prod) |

---

## 3. Dashboards and alerts

### 3.1 Primary metrics

| Metric | Warn | Page |
| --- | --- | --- |
| Subscription sync lag P50 | &gt;3 min | &gt;5 min for 10 min |
| Integration success ratio | &lt;99.7% | &lt;99.5% for 1h |
| DLQ depth (Stripe/Device) | &gt;0 for 5 min | &gt;0 for 15 min |
| Duplicate Account create rate | &gt;0.05% | &gt;0.1% |
| MDM match rate (top logos) | &lt;95% rolling | &lt;90% |
| DQ fail rate critical | &gt;1% | &gt;2% or any bypass |
| Agent token deny anomalies | Spike 3× baseline | Sustained probe pattern (security) |
| Cross-tenant deny | Any | Immediate security page |
| Agent profile p95 | &gt;2s | &gt;5s |

### 3.2 Where to look

1. IDMC Monitor — job/process status  
2. CAI logs — correlation ID search  
3. Salesforce Event Monitoring — agent actions  
4. Snowflake/Looker — `nf_integration_lag`, `nf_match_rates`, `nf_dq_fails`, `nf_agent_allow_deny`  
5. Stripe dashboard — webhook delivery  

---

## 4. Incident response

### 4.1 Severity

| Sev | Definition | Response |
| --- | --- | --- |
| 1 | Subscription sync down; agent wrong-account risk active; tenant isolation breach | 15 min ack; war room |
| 2 | Device/RMA degraded; DQ quarantine backlog blocking CX | 30 min ack |
| 3 | Zendesk sample lag; metrics delay | Next business day |
| 4 | Demo UI | Best effort |

### 4.2 Playbook — subscription lag Sev-1

1. Capture correlation IDs from recent Stripe events.  
2. Check CAI process health + DLQ.  
3. If Stripe 429/5xx → backoff; communicate RevOps.  
4. If mapping/SKU miss → steward queue; block bad entitlements.  
5. If Salesforce API limit → engage SF admin; throttle.  
6. After restore: replay DLQ with idempotency; verify Entitlement__c; postmortem 48h.

### 4.3 Playbook — suspected wrong Account agent action

1. Disable affected Agentforce agent / permission set immediately.  
2. Freeze Device rebind actions.  
3. Trace correlation ID → golden IDs → match score history.  
4. Open MDM suspect review; correct hierarchy.  
5. CISO notified if cross-tenant.  
6. Re-enable only after acceptance retest scenario 2.

### 4.4 Playbook — policy deny misconfiguration

1. If tokens **exposed**: treat as Sev-1 security; revoke agent tools; rotate keys if leakage.  
2. If over-deny: hot-patch Catalog allowlist with CISO approval.  

---

## 5. DLQ replay procedure

1. Identify message; confirm idempotency key.  
2. For financial / entitlement writes: dual approval (Integration + RevOps).  
3. Replay single message; watch lag metrics.  
4. Batch replay only after 3 successful singles.  
5. Document ticket with correlation IDs.

---

## 6. Stewardship operations

| Queue | Tool | SLA |
| --- | --- | --- |
| Account suspect match | IDMC MDM | 2 BD |
| Device bind conflict | IDMC + Registry | 4 BH |
| SKU map miss | MDM Product | 1 BD |
| DQ quarantine firmware | DQ workspace | Before RMA ship |

Stewards never bypass critical DQ without CDO+CISO break-glass ticket (time-boxed ≤4h, auto-expire).

---

## 7. Match-rule change control

1. Propose rule change in ticket with sample false-positive/negative analysis.  
2. Apply in non-prod; run duplicate report on top 2,000 logos sample.  
3. EA + CDO approve.  
4. Tag version in `idmc/mdm/`; promote.  
5. Monitor match rate 72h; rollback tag if &gt;2% duplicate regression.

---

## 8. Agent operations

- Weekly review of allow/deny counts and HITL queue age.  
- Prompt/grounding changes go through Salesforce change set + UAT scenario smoke.  
- New agent-consumed attributes require Catalog certification (governance doc §10).  
- Audit export monthly for compliance evidence (≥1 year retention).  

---

## 9. Backup and DR

| Component | DR note |
| --- | --- |
| Salesforce | Native redundancy; metadata in git |
| IDMC | Vendor SaaS RPO/RTO per contract; export assets to git weekly |
| Secure Agent | Secondary host warm; documented rebuild |
| Secrets | Multi-AZ vault; restore runbook with IAM |
| Snowflake metrics | Time travel per edition; non-authoritative |

**Annual DR tabletop:** Stripe path outage + MDM rollback drill.

---

## 10. Maintenance windows

- Prefer Tue/Wed 02:00–04:00 CT for match-rule and connector upgrades.  
- Announce 48h ahead to RevOps/CX.  
- Freeze during month-end close for NetSuite-heavy changes (RevOps call).  

---

## 11. Contacts (fill at go-live)

| Function | Primary | Backup |
| --- | --- | --- |
| Integration on-call | | |
| MDM steward lead | | |
| Salesforce admin | | |
| CISO duty | | |
| Product Eng (Observe/Registry) | | |
| EA | | |

---

## 12. Related references

- Architecture: [01-architecture.md](../01-architecture.md)  
- Integration catalog: [03-integration-catalog.md](../03-integration-catalog.md)  
- Governance: [04-governance-and-policies.md](../04-governance-and-policies.md)  
- Acceptance: [acceptance/scenarios.md](../acceptance/scenarios.md)  
- Go-live: [07-go-live-checklist.md](./07-go-live-checklist.md)  

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
