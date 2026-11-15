# NexusForge Systems — Target Architecture

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CDI, CAI, MDM, Data Quality, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | 01 — Architecture |
| Version | 1.0 |
| Related diagrams | `diagrams/svg/01`–`06` (see §8) |

---

## 1. Purpose

This document defines the end-to-end logical architecture for NexusForge’s Agentic Customer & Product Data Platform. It covers systems of engagement, the Informatica IDMC trust fabric, domain systems of record, the analytics plane, identity boundaries, data flows, non-functional requirements, and a defended buy-vs-build stance.

Audience: Enterprise Architect, CTO, CDO, security architecture, and delivery leads executing the [deploy runbooks](./deploy/).

---

## 2. Architectural drivers

| Driver | Implication |
| --- | --- |
| Dual motion (SaaS + hardware) | Continuous mismatch risk among Opportunity stage, product org, Stripe subscription, and device activation |
| Agentic CX & RevOps in 12–24 months | Agents require fresh, contract-versioned, policy-bound data—not warehouse snapshots |
| Multi-tenant isolation | Agent tools must never cross ForgeObserve org boundaries |
| SOC 2 / ISO 27001 / GDPR / CCPA | Classification, lineage, DSR paths, and agent action audit ≥1 year |
| Engineering culture (buy-vs-build skepticism) | Architecture must show where DIY fails under agent blast radius |
| 90-day pilot | Two Agentforce use cases on governed masters; phased full MDM |

---

## 3. Logical architecture overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ SYSTEMS OF ENGAGEMENT                                                       │
│  Salesforce Sales Cloud · Service Cloud · (Experience Cloud later)          │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────────────┐
│ INTELLIGENCE & AGENTS                                                       │
│  Salesforce Data Cloud (unified profiles, calculated insights)              │
│  Salesforce Agentforce (CX + revenue pilots)                                │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │ governed APIs / certified data products
┌───────────────────────────────▼─────────────────────────────────────────────┐
│ TRUST FABRIC — Informatica IDMC (Informatica by Salesforce)                 │
│  CDI / CAI · MDM · Data Quality · Catalog · Governance                      │
└───┬───────────┬───────────┬───────────┬───────────┬─────────────────────────┘
    │           │           │           │           │
    ▼           ▼           ▼           ▼           ▼
 Stripe     NetSuite    Zendesk   ForgeObserve   Device Registry
                                          │              │
                                          └──────┬───────┘
                                                 ▼
                                    Analytics: Snowflake (read)
```

**Reference diagram:** [`diagrams/svg/01-nexusforge-logical-architecture.svg`](../diagrams/svg/01-nexusforge-logical-architecture.svg)

### 3.1 Layer responsibilities

| Layer | Components | Responsibility |
| --- | --- | --- |
| Engagement | Sales Cloud, Service Cloud | Opportunity, Case, human workflows; golden keys displayed; not survivorship engine |
| Intelligence | Data Cloud, Agentforce | Unified profiles, insights, agent grounding and bounded actions |
| Trust fabric | IDMC CDI/CAI, MDM, DQ, Catalog, Governance | Integration orchestration, masters, quality gates, discoverable contracts, policy |
| Domain SoR | Stripe, NetSuite, Zendesk, ForgeObserve, Device Registry | Authoritative domain transactions; emit CDC / APIs into IDMC |
| Analytics | Snowflake (+ Segment ingest path) | Historical analytics; **not** agent write-back SoT |
| Identity | Okta workforce, Auth0 customer, Salesforce SSO, IDMC service principals | AuthN/AuthZ boundaries; least privilege |

---

## 4. Salesforce solution architecture

### 4.1 Sales Cloud

- Account and Contact hygiene aligned to Informatica MDM golden keys (`NF_Golden_Account_Id__c`, `NF_Golden_Contact_Id__c`).
- Opportunity and Contract/Subscription representation for SaaS tiers and appliance bundles (lightweight product catalog; spreadsheet CPQ retired for pilot SKUs).
- Trial conversion coach Agentforce agent consumes Data Cloud health/entitlement insights and CRM stage—not ad-hoc SQL.

### 4.2 Service Cloud

- Cases linked to Device and Entitlement custom objects (or standard Entitlements where appropriate).
- Entitlement-aware triage replaces brittle macros for “is this feature on plan?” questions.
- Proactive RMA assistant proposes RMAs only when Device master + DQ gates pass.
- Gradual migration from Zendesk: sample tickets in pilot; dual-running for ~12 months.

### 4.3 Data Cloud

- Ingestion of golden masters and certified aggregates from IDMC / Salesforce.
- Identity resolution **aligned** to MDM crosswalk IDs (MDM remains system of reference for merge decisions).
- Calculated insights: account health score, entitlement risk, trial conversion propensity, device fleet risk.
- Consent and data governance constructs applied where customer contact data is activated.

### 4.4 Agentforce

| Pilot agent | Primary clouds | Write scope (pilot) |
| --- | --- | --- |
| Trial conversion coach | Sales + Data Cloud | Soft actions: tasks, next-best-action recommendations |
| Entitlement-aware triage | Service + Data Cloud | Case routing, suggested macros; no billing writes |
| Proactive RMA | Service + Device master | Propose RMA; HITL for cross-Account rebind |
| ARR / renewal brief | Revenue (read-only first) | Generate brief only; no opportunity mutation in pilot |

Grounding rules and HITL thresholds: [05-agentforce-use-cases.md](./05-agentforce-use-cases.md).

### 4.5 Security (Salesforce)

- Profiles and permission sets: least privilege for agent-related integration users.
- Event Monitoring for agent and API audit trails.
- Optional Salesforce Shield for encryption/monitoring where CISO requires.
- Named Credentials for outbound governed CAI endpoints—no secrets in metadata.

**Diagram:** [`diagrams/svg/04-nexusforge-agentforce-runtime-trust.svg`](../diagrams/svg/04-nexusforge-agentforce-runtime-trust.svg)

---

## 5. Informatica IDMC architecture

### 5.1 Cloud Data Integration (CDI) and Cloud Application Integration (CAI)

| Pattern | Use |
| --- | --- |
| CDI batch / CDC | Scheduled reconciliation NetSuite↔Salesforce; Snowflake analytical loads; bulk MDM initial load |
| CAI process / APIs | Near-real-time Stripe subscription events; Device Registry webhooks; Agentforce action endpoints |
| Secure Agent | Where private connectivity to Device Registry or on-prem-adjacent network is required |

**Default:** IDMC is the integration fabric of record. MuleSoft/Anypoint is optional only if NexusForge already licenses it; this engagement does not depend on it.

### 5.2 MDM

- System of **reference** for Account/Customer, Contact/User, Subscription/Entitlement, Product/SKU, Device/Asset.
- Match/merge, survivorship, hierarchy, and crosswalk publication to Salesforce and Data Cloud.
- Detail: [02-data-model-mdm.md](./02-data-model-mdm.md).

### 5.3 Data Quality

- Completeness, validity, uniqueness, referential integrity (device must map to Account).
- Quarantine before agent consumption; steward workflows for RMA serial/firmware mismatches.
- Detail: [04-governance-and-policies.md](./04-governance-and-policies.md).

### 5.4 Catalog and Governance

- Data products: `dp.customer.golden`, `dp.device.fleet`, `dp.entitlement.active`.
- Sensitivity tags; agent tool denials for raw Stripe PAN/tokens.
- Lineage source → MDM → Data Cloud → agent action audit.

**Pillars diagram:** [`diagrams/svg/02-nexusforge-integration-mdm-governance-pillars.svg`](../diagrams/svg/02-nexusforge-integration-mdm-governance-pillars.svg)

---

## 6. Domain systems and integration touchpoints

| System | Role | Integration mode |
| --- | --- | --- |
| Stripe | Billing SoR for subscriptions, invoices, payment method tokens | CAI webhooks + CDI reconcile; **never** expose raw PAN/token to agents |
| NetSuite | ERP / revenue recognition / order | CDI CDC / scheduled; financial attributes to CRM summaries |
| Zendesk | Legacy support SoR (transitional) | CAI ticket sync sample; Account link via golden key |
| ForgeObserve control plane | Product tenancy: orgs, seats, feature flags | CAI/REST; entitlement projection into MDM |
| Device Registry | Serial, firmware, tenant binding | CAI/REST + Secure Agent if private; Device master source |
| Snowflake | Analytics | CDI load of certified aggregates; agents do not write back here |
| Segment | Product analytics ingress | Existing path into Snowflake; not agent SoT |

**Subscription + device flow diagram:** [`diagrams/svg/03-nexusforge-data-flow-subscription-device.svg`](../diagrams/svg/03-nexusforge-data-flow-subscription-device.svg)

Catalog of patterns, SLAs, and correlation IDs: [03-integration-catalog.md](./03-integration-catalog.md).

---

## 7. End-to-end data flows

### 7.1 Inbound trust path (systems → masters → activation)

1. Domain systems emit events (Stripe `customer.subscription.updated`, Device Registry binding change) or CDC batches.
2. IDMC CAI/CDI normalizes payloads, attaches **correlation ID**, upserts staging.
3. MDM match/merge applies survivorship; publishes golden record + crosswalk IDs.
4. DQ evaluates rules; failures quarantine; Catalog certification status updates.
5. Certified attributes sync to Salesforce (engagement) and Data Cloud (profile/insights).
6. Agentforce retrieves unified profile + entitlements via approved tools only.

### 7.2 Agent write-back path (bounded)

1. Agent proposes action (e.g., open RMA, create follow-up Task).
2. Policy engine checks Catalog sensitivity + purpose + HITL thresholds.
3. Allowed actions invoke IDMC CAI APIs with correlation ID and agent session audit.
4. Downstream systems update; MDM/DQ re-evaluate as needed.
5. Lineage records agent action → API → target system.

### 7.3 Analytical path (non-authoritative for agents)

- Certified aggregates and historical facts land in Snowflake for Looker.
- Agents may use **pre-approved** calculated insights published into Data Cloud—not arbitrary warehouse SQL.

---

## 8. Diagram index

| File | Content |
| --- | --- |
| [`diagrams/svg/01-nexusforge-logical-architecture.svg`](../diagrams/svg/01-nexusforge-logical-architecture.svg) | Full logical stack: engagement, intelligence, IDMC, domain SoRs, analytics |
| [`diagrams/svg/02-nexusforge-integration-mdm-governance-pillars.svg`](../diagrams/svg/02-nexusforge-integration-mdm-governance-pillars.svg) | Three pillars with NexusForge-specific capabilities |
| [`diagrams/svg/03-nexusforge-data-flow-subscription-device.svg`](../diagrams/svg/03-nexusforge-data-flow-subscription-device.svg) | Subscription upgrade + device binding flow through IDMC → CRM/Data Cloud |
| [`diagrams/svg/04-nexusforge-agentforce-runtime-trust.svg`](../diagrams/svg/04-nexusforge-agentforce-runtime-trust.svg) | Agentforce runtime, grounding, policy denials, HITL |
| [`diagrams/svg/05-nexusforge-security-identity-boundaries.svg`](../diagrams/svg/05-nexusforge-security-identity-boundaries.svg) | Okta/Auth0/Salesforce/IDMC trust boundaries and tenant isolation |
| [`diagrams/svg/06-nexusforge-deploy-topology.svg`](../diagrams/svg/06-nexusforge-deploy-topology.svg) | Non-prod/prod deploy topology, Secure Agent, secrets, CI |

All diagrams carry Salesforce and Informatica labeling per branding standards.

---

## 9. Trust, security, and identity boundaries

**Diagram:** [`diagrams/svg/05-nexusforge-security-identity-boundaries.svg`](../diagrams/svg/05-nexusforge-security-identity-boundaries.svg)

| Boundary | Control |
| --- | --- |
| Workforce | Okta → Salesforce SSO; IDMC admin via enterprise IdP |
| Customer product | Auth0; agents never receive customer session tokens |
| Integration principals | OAuth2 / private keys in secrets manager; Named Credentials / IDMC connections |
| Tenant isolation | ForgeObserve org_id required on entitlement/device tools; automated acceptance gates |
| Network | Private connectivity pattern for Device Registry (Secure Agent / private link documented in deploy) |
| Data | Sensitivity tags; agent deny on raw billing tokens; Shield/Event Monitoring as required |
| Audit | Correlation ID on every sync and agent write-back; retention ≥1 year for agent actions |

---

## 10. Buy vs build — architecture defense

### 10.1 Decision summary

| Capability | Buy (Salesforce / IDMC) | Build (NexusForge) |
| --- | --- | --- |
| Integration orchestration, retry, observability | IDMC CDI/CAI | — |
| MDM match/merge, survivorship, hierarchy | Informatica MDM | — |
| DQ rules + quarantine + stewarding | IDMC DQ | Steward UI process ownership |
| Catalog, lineage, agent policy | IDMC Catalog/Governance | Policy requirements from CISO |
| CRM engagement + Agentforce runtime | Salesforce | Prompt/grounding content, HITL ops |
| ForgeObserve / Device Registry connectors | IDMC hosts; **adapters built** | Payload mapping, auth, webhooks |
| Demo UI / acceptance harness | — | Build |
| Custom Glue/Airflow “MDM” | **Do not build** | — |
| Agent-facing ad-hoc SQL to Snowflake | **Do not build** | — |

### 10.2 Why AI-scaffolded pipelines are insufficient

1. **Survivorship is a product, not a script.** Self-serve Stripe customer vs enterprise Salesforce Account vs NetSuite subsidiary requires durable rules, exception queues, and steward workflows. Generated Python drifts with every schema change.
2. **Agents multiply incorrect joins.** A wrong Device→Account link in a DIY table becomes an autonomous RMA or refund. IDMC MDM + DQ + Catalog make “uncertified” data invisible to tools.
3. **Governance must execute at runtime.** PDF policies do not block Agentforce from reading `stripe_payment_method_token`. Catalog policies do.
4. **Lineage and match-rate are operational KPIs.** DIY pipelines rarely ship first-class lineage and match dashboards; IDMC does. Acceptance scenario 5 demonstrates this gap explicitly.
5. **Control plane vs adapters.** NexusForge engineers should own ForgeObserve and Device Registry semantics. They should not own a second enterprise MDM.

### 10.3 Cost-of-delay framing (architecture, not sales)

Every quarter without a trust fabric increases: duplicate Accounts in top logos, billing disputes from entitlement lag, support misroutes, and risk of premature agent rollout on unclean joins. The architecture buys time-to-safe-agents, not merely time-to-first-pipeline.

---

## 11. Deploy topology (summary)

**Diagram:** [`diagrams/svg/06-nexusforge-deploy-topology.svg`](../diagrams/svg/06-nexusforge-deploy-topology.svg)

| Environment | Purpose |
| --- | --- |
| Non-prod (dev/test) | Full stack sandbox: Salesforce sandbox, IDMC non-prod, sample Stripe/NetSuite, mock or sandbox product APIs |
| UAT | Acceptance scenarios; Agentforce pilots; steward training |
| Prod | Phased connections; monitoring; hypercare |

IaC under `infra/terraform/` provisions supporting cloud resources and secrets references. Salesforce metadata under `salesforce/force-app/`. IDMC specs under `idmc/`. Step-by-step: [deploy/](./deploy/).

---

## 12. Non-functional requirements

| Area | Requirement |
| --- | --- |
| Security | SOC 2 aligned; secrets in vault; least privilege; tenant isolation tests |
| Compliance | GDPR/CCPA DSR via governed masters; agent action audit ≥1 year |
| Observability | Sync lag, MDM match %, DQ fail rate, agent allow/deny |
| Availability | 99.9% monthly for critical subscription sync tier |
| Performance | Agent profile retrieve p95 &lt;2s for pilot payloads |
| Scalability | Design for 3× account and device growth without re-architecture |
| Integration SLA | &lt;5 min median CRM↔billing↔product for subscription changes |

---

## 13. Architecture principles (normative)

1. Informatica MDM is system of reference for masters; Salesforce is system of engagement; Data Cloud is activation.
2. IDMC is the integration fabric of record for this engagement.
3. Agents consume cataloged, DQ-gated data products only.
4. Snowflake is analytical; not authoritative for write-back.
5. Correlation IDs traverse sync and agent actions end-to-end.
6. Buy control plane; build domain adapters and tests.
7. HITL for refunds above threshold and cross-Account device rebinds.
8. Tenant isolation failures block release.

---

## 14. Related documents

- [00-engagement-overview.md](./00-engagement-overview.md) — scope, stakeholders, 90-day path  
- [02-data-model-mdm.md](./02-data-model-mdm.md) — MDM domains  
- [03-integration-catalog.md](./03-integration-catalog.md) — patterns & SLAs  
- [04-governance-and-policies.md](./04-governance-and-policies.md) — policies & compliance  
- [05-agentforce-use-cases.md](./05-agentforce-use-cases.md) — agents  

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
