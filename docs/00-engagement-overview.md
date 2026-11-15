# NexusForge Systems — Engagement Overview

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CDI, CAI, MDM, Data Quality, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Engagement | Agentic Customer & Product Data Platform |
| Document | 00 — Engagement Overview |
| Audience | CTO, CDO, VP CX, CRO/RevOps, CISO, Enterprise Architecture |
| Version | 1.0 |

---

## 1. Executive summary

NexusForge Systems sells two tightly coupled product lines: **ForgeObserve**, a multi-tenant SaaS observability platform for SRE and platform teams, and **ForgeEdge**, connected hardware appliances that stream telemetry into ForgeObserve. At roughly $480M ARR, ~9,000 paying accounts, and ~180,000 managed device serials, growth is healthy—but the operating model is fracturing.

Salesforce CRM, NetSuite ERP, Stripe billing, Zendesk support, the ForgeObserve control plane, and the ForgeEdge Device Registry each hold partial truths about accounts, subscriptions, entitlements, and devices. Revenue operations reconciles subscription state in warehouse scripts. Support agents open cases without a reliable link to Salesforce Account hierarchy or active entitlement. Device RMA flows depend on tribal knowledge of which serial belongs to which tenant.

Over the next 12–24 months, NexusForge intends to put **agentic AI into production** for trial-to-paid conversion coaching, entitlement-aware support triage, proactive hardware RMA, and ARR/renewal briefs for AEs and CSMs. Those agents will fail—or worse, act incorrectly—if they cannot discover trusted, governed enterprise data at runtime.

This engagement designs and delivers an end-to-end architecture on **Salesforce** (Sales Cloud, Service Cloud, Data Cloud, Agentforce) and **Informatica Intelligent Data Management Cloud (IDMC)** (integration, MDM, data quality, catalog, and governance). Deliverables include deployable configuration, Salesforce metadata, IDMC asset specs, a thin demo UI, branded architecture diagrams, and acceptance scenarios that prove Integration, MDM, and Governance as first-class pillars—not slideware.

**Desired outcomes**

| Outcome | Measure |
| --- | --- |
| Single trusted customer / product / device graph | Golden Account, Contact, Subscription/Entitlement, Product/SKU, Device/Asset with published crosswalk IDs |
| Agent-safe data contracts | 100% of pilot Agentforce tools resolve from cataloged, DQ-gated data products |
| Lower support misroutes & billing disputes | Entitlement-aware triage; subscription sync &lt;5 min median CRM↔billing↔product |
| Defended buy-vs-build stance | IDMC as indispensable trust fabric vs AI-scaffolded custom pipelines |

---

## 2. Customer context

### 2.1 Company profile

| Attribute | Assumption |
| --- | --- |
| Legal name | NexusForge Systems, Inc. |
| HQ / footprint | Austin, TX; engineering hubs in Toronto and Kraków; ~2,400 employees |
| Business | B2B SaaS observability + edge appliances sold into mid-market and enterprise DevOps/SRE orgs |
| Scale | ~$480M ARR; ~9,000 paying accounts; ~180k device serials; ~1.2B events/day into product analytics (agents consume curated aggregates and masters only—not raw events) |
| Go-to-market | PLG + enterprise sales hybrid; partner channel for appliances |

### 2.2 As-is systems landscape

| Domain | Systems |
| --- | --- |
| CRM / CPQ | Salesforce Sales Cloud (partial); legacy CPQ spreadsheets for appliance bundles |
| Support | Zendesk + PagerDuty; weak link to Salesforce Account/Contact |
| Product / tenancy | ForgeObserve control plane (Postgres): orgs, workspaces, seats, feature flags |
| Devices | ForgeEdge Device Registry (microservice + DynamoDB): serial, firmware, tenant binding |
| Billing | Stripe + NetSuite; RevOps reconciles in BigQuery manually |
| Identity | Okta (workforce); Auth0 (customer product SSO) |
| Analytics | Segment → Snowflake; Looker dashboards |
| Collaboration | Slack, Gong, Notion |

### 2.3 Constraints

- Multi-tenant SaaS isolation must never be violated by agent tools.
- Device PII and customer telemetry subject to SOC 2 Type II, ISO 27001, GDPR, and CCPA.
- Preference for cloud-native SaaS (Salesforce + IDMC) over net-new custom MDM.
- 90-day pilot path to production for two Agentforce use cases; full MDM golden record is phased.
- Snowflake remains analytical-only; not a source of truth for agent write-back.
- IDMC is the integration fabric of record for this engagement (MuleSoft optional only if already licensed—not assumed).

---

## 3. Engagement outcomes

### 3.1 Business outcomes

1. **Trusted Account 360 for CX and revenue.** AEs, CSMs, and support see one hierarchy: parent enterprise Account → billing entities → product orgs → devices and entitlements.
2. **Subscription and entitlement consistency.** Stripe upgrades, seat changes, and appliance activations land in Salesforce and product within a five-minute median SLA.
3. **Safer agentic operations.** Agentforce pilots act only on certified data products; raw Stripe PAN/tokens and uncertified fields are denied at tool time.
4. **Measurable trust fabric.** Match rates, DQ fail rates, sync lag, and agent allow/deny metrics are operational dashboards—not quarterly audit artifacts.

### 3.2 Technical outcomes

- Informatica MDM as system of reference for Account/Customer, Contact/User, Subscription/Entitlement, Product/SKU, and Device/Asset.
- Salesforce as system of engagement; Data Cloud as activation and unified-profile layer feeding Agentforce.
- IDMC CDI/CAI as the integration control plane with correlation IDs, replay, and poison-message handling.
- IDMC Catalog + DQ + Governance policies as machine-enforceable contracts for agent consumption.
- Deployable non-prod reference environment with IaC, metadata, IDMC specs, demo UI, and acceptance pack.

---

## 4. Scope

### 4.1 In scope

| Workstream | Deliverables |
| --- | --- |
| Architecture | Logical E2E design; six branded SVG diagrams; buy-vs-build defense |
| Salesforce | Sales Cloud / Service Cloud object model alignment; Data Cloud ingestion & insights; Agentforce pilot agents |
| IDMC | CDI/CAI integrations; MDM models & match/merge; DQ rule packs; Catalog data products & policies |
| Domains | Account/Customer, Contact/User, Subscription/Entitlement, Product/SKU, Device/Asset |
| Systems | Stripe, NetSuite, Zendesk, ForgeObserve control plane, Device Registry, Snowflake (analytical) |
| Deploy | Prerequisites through go-live and operations runbooks |
| Acceptance | Five executable scenario scripts covering Integration, MDM, Governance, Device RMA, and buy-vs-build narrative |
| Demo | Thin UI exercising Account 360 and agent action simulator |

### 4.2 Out of scope

- Replacing ForgeObserve product analytics store or building a new enterprise event bus.
- Custom LLM training / fine-tuning platforms.
- Full ERP reimplementation in NetSuite.
- Production cutover of all historical Zendesk tickets (sample migration only).
- FedRAMP authorization (not required in year 1).
- Using named third-party companies from industry brief examples as the customer.

### 4.3 Assumptions

> Reviewers may correct any of the following.

1. NexusForge has Salesforce Sales Cloud today but not Data Cloud / Agentforce licensed in production—pilot uses sandbox/trial patterns.
2. Zendesk remains for ~12 months; Service Cloud becomes the primary system of engagement gradually.
3. Device Registry exposes a stable REST API suitable for IDMC CAI.
4. Snowflake remains analytical-only; not used for agent write-back.
5. MuleSoft is not required; IDMC is the integration fabric of record.
6. No FedRAMP requirement in year 1.

---

## 5. Thesis — buy vs build

**Thesis:** For NexusForge, AI-assisted engineering can scaffold a pipeline in a day; it cannot sustain a **trust fabric**—identity resolution, survivorship, policy enforcement, lineage, and agent-time contracts—across CRM, billing, product tenancy, and hardware. **Salesforce + Informatica IDMC are indispensable** because agents require operationally governed masters and discoverable, quality-scored data products, not one-off scripts.

### 5.1 CTO objection and architecture response

**Objection:** “My engineers can use Claude/Cursor to build the integration they need in a day.”

| Response pillar | Architecture argument |
| --- | --- |
| Day-1 code ≠ year-1 reliability | Appliance firmware ↔ tenant binding ↔ entitlement ↔ invoice disputes create multi-system survivorship rules that drift when owned as tribal Python. |
| Agents amplify blast radius | An Agentforce support agent that refunds or rebinds a device on the wrong Account hierarchy is a revenue and security incident—not a ticket. |
| Governance is runtime, not docs | IDMC Catalog + DQ + MDM provide machine-enforceable contracts that Agentforce and Data Cloud can consume; AI-generated Glue jobs do not. |
| Buy the control plane; build the adapters | Custom code remains for ForgeObserve and Device Registry connectors; IDMC owns orchestration, MDM, DQ, lineage, and policy. |

### 5.2 Where custom build remains appropriate

- ForgeObserve and Device Registry API adapters (domain-specific payloads).
- Demo UI and acceptance harnesses.
- Tenant-isolation automated tests as CI gates.
- Light Salesforce Apex / Flow for engagement UX—not for master survivorship.

### 5.3 What must not be DIY

- Match/merge and survivorship across self-serve vs enterprise Accounts.
- Cross-system golden keys and hierarchy publication.
- Field-level sensitivity enforcement for agent tools (e.g., deny raw Stripe tokens).
- End-to-end lineage from source → MDM → Data Cloud → agent action audit.
- Continuous DQ gates before agent consumption.

Detailed buy-vs-build defense appears in [01-architecture.md](./01-architecture.md). Lineage and match-rate demo notes appear in [acceptance/scenarios.md](./acceptance/scenarios.md).

---

## 6. Stakeholders and RACI (engagement)

| Stakeholder | Role in engagement |
| --- | --- |
| CTO | Buy-vs-build decision owner; engineering culture sponsor |
| CDO / Head of Data Platform | MDM, Catalog, DQ ownership; data product SLAs |
| VP Customer Experience | Service Cloud + Agentforce triage / RMA outcomes |
| VP Product | In-product assistant alignment; tenancy isolation requirements |
| CRO / RevOps | Subscription sync SLAs; ARR/renewal brief consumers |
| CISO / Privacy counsel | SOC 2 / GDPR / CCPA controls; agent tool policy |
| Enterprise Architect | Named engagement counterpart; architecture acceptance |

| Workstream | Responsible | Accountable | Consulted | Informed |
| --- | --- | --- | --- | --- |
| Architecture & diagrams | Solution Architecture | Enterprise Architect | CTO, CDO | All stakeholders |
| Salesforce / Data Cloud / Agentforce | Salesforce workstream lead | VP CX / CRO (by domain) | CISO, RevOps | Product |
| IDMC CDI/CAI/MDM/DQ/Catalog | IDMC workstream lead | CDO | EA, CISO | CTO |
| Integrations (Stripe, NetSuite, product, devices) | Integration lead | CDO | RevOps, Product Eng | Support Ops |
| Demo UI & acceptance | Delivery eng | Solution Architecture | All pilot owners | Exec sponsors |
| Go-live & hypercare | Platform Ops | CTO delegate | CISO | All |

---

## 7. Ninety-day pilot path

The pilot lands **two Agentforce use cases** in production-like sandboxes with governed data products, then promotes with hypercare. Full historical MDM backfill and Zendesk cutover remain phased beyond day 90.

### Phase A — Days 0–30: Foundation

| Milestone | Exit criteria |
| --- | --- |
| Prerequisites & IaC bootstrap | Non-prod Salesforce, IDMC, secrets, CI green |
| Salesforce baseline objects | Device__c, Entitlement__c (or equivalent), permission sets, record types |
| IDMC connections & CDI/CAI projects | Stripe, NetSuite, Zendesk, ForgeObserve, Device Registry connections validated |
| MDM model v1 | Account, Contact, Device, Product, Subscription models loaded with sample data |
| DQ + Catalog seed | `dp.customer.golden`, `dp.device.fleet`, `dp.entitlement.active` defined |

### Phase B — Days 31–60: Trust fabric + Data Cloud

| Milestone | Exit criteria |
| --- | --- |
| Match/merge & survivorship | Duplicate Account rate measurable; Device→Account confidence baseline |
| Bidirectional golden keys | Crosswalk IDs in Salesforce and Data Cloud |
| Data Cloud unified profiles | Individual/Account + calculated insights (health, entitlement risk) |
| Integration SLA instrumentation | Sync lag dashboards; &lt;5 min median on subscription path in non-prod |
| Agent tool policy stubs | Deny raw Stripe PAN/token fields; allow certified billing_status |

### Phase C — Days 61–90: Agentforce pilots + UAT

| Milestone | Exit criteria |
| --- | --- |
| Pilot agents live in sandbox | (1) Trial conversion coach **or** entitlement-aware triage; (2) proactive RMA **or** ARR brief (read-only)—two of four, prioritized with VP CX / CRO |
| HITL thresholds configured | Refunds above threshold; cross-Account device rebinds require human approval |
| Acceptance pack executed | All five scenarios in [acceptance/scenarios.md](./acceptance/scenarios.md) pass |
| Go-live checklist | Monitoring, runbooks, hypercare roster signed |
| Executive readout | Match rates, DQ gates, agent allow/deny, buy-vs-build evidence |

### Beyond day 90 (roadmap, not pilot commitment)

- Expand remaining Agentforce use cases; enable bounded write-backs with audit.
- Progressive Service Cloud adoption; sample→broader Zendesk migration.
- Full MDM golden for top logos; channel/partner Experience Cloud later.
- Continuous match-rule change control and stewardship ops.

Detailed phase expansion lives under [deploy/](./deploy/).

---

## 8. Success metrics (engagement KPIs)

| Pillar | Metric | Target (pilot) |
| --- | --- | --- |
| Integration | Median CRM↔billing↔product consistency (subscription changes) | &lt;5 minutes |
| Integration | Successful integration job completion | ≥99.5% |
| Integration | Duplicate Account creates from sync | &lt;0.1% |
| MDM | Duplicate Account rate (top 2,000 logos) | &lt;2% |
| MDM | Device-to-Account match confidence (active fleet) | ≥98% |
| MDM | Agent “wrong account” actions in UAT | 0 |
| Governance | Agent-consumed data products cataloged with owner + sensitivity | 100% |
| Governance | Lineage completeness for pilot domains | ≥95% |
| Governance | Critical DQ gate bypasses in production pilot | 0 |
| Agent runtime | Profile retrieve p95 | &lt;2 seconds |
| Platform | Integration tier availability (critical subscription sync) | 99.9% monthly |

---

## 9. Document map

| Document | Purpose |
| --- | --- |
| [01-architecture.md](./01-architecture.md) | E2E logical architecture; buy-vs-build; diagram references |
| [02-data-model-mdm.md](./02-data-model-mdm.md) | Master domains, match/merge, survivorship, hierarchy, crosswalk |
| [03-integration-catalog.md](./03-integration-catalog.md) | Event-driven + scheduled patterns, SLAs, observability |
| [04-governance-and-policies.md](./04-governance-and-policies.md) | Data products, sensitivity, agent denials, lineage, compliance |
| [05-agentforce-use-cases.md](./05-agentforce-use-cases.md) | Four pilot agents; grounding; HITL |
| [deploy/](./deploy/) | Actionable runbooks prerequisites → operations |
| [acceptance/scenarios.md](./acceptance/scenarios.md) | Five executable acceptance scenarios |

**Diagrams (logical references):** `diagrams/svg/01-nexusforge-logical-architecture.svg` through `06-nexusforge-deploy-topology.svg`.

---

## 10. Engagement principles

1. **Agents consume contracts, not tables.** Cataloged data products with DQ gates are the interface.
2. **MDM is system of reference; CRM is system of engagement.** Survivorship is not an Apex responsibility.
3. **Buy the control plane; build the adapters.** Defend IDMC where trust compounds; customize where domain APIs are unique.
4. **Tenant isolation is a hard gate.** Automated tests block promotion if isolation is violated.
5. **Human-in-the-loop for irreversible money and device moves.** Refunds and cross-Account rebinds escalate.
6. **Snowflake informs; it does not authorize writes.** Analytical plane stays read-oriented for agents.

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
