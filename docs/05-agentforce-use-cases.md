# NexusForge Systems — Agentforce Use Cases

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (governed data products via CDI/CAI, MDM, DQ, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | 05 — Agentforce Use Cases |
| Version | 1.0 |
| Pilot window | 90 days (two agents to production-like; four designed) |

---

## 1. Purpose

Specify the four Agentforce pilots that justify the Salesforce + IDMC trust fabric: trial conversion coach, entitlement-aware triage, proactive RMA, and ARR/renewal brief (read-only first). Each use case defines grounding sources, allowed tools, HITL thresholds, and failure modes.

**Runtime diagram:** [`diagrams/svg/04-nexusforge-agentforce-runtime-trust.svg`](../diagrams/svg/04-nexusforge-agentforce-runtime-trust.svg)

---

## 2. Shared runtime contract

### 2.1 Grounding hierarchy

1. **Certified data products** via CAI (`dp.customer.golden`, `dp.device.fleet`, `dp.entitlement.active`).
2. **Data Cloud** unified profiles and calculated insights (health, entitlement risk, conversion propensity).
3. **Salesforce** engagement context (Opportunity stage, Case, Activity)—not competing masters.
4. **Never:** ad-hoc Snowflake SQL, raw Stripe tokens, uncertified MDM quarantine records, cross-tenant product APIs.

### 2.2 Common non-functionals

| Requirement | Target |
| --- | --- |
| Profile/tool retrieve p95 | &lt;2s |
| Audit retention | ≥1 year |
| Correlation ID | Per tool call |
| Tenant isolation | Hard fail on mismatch |
| Wrong-account actions in UAT | 0 |

### 2.3 Pilot selection guidance

Days 61–90 ship **two** of four, prioritized with VP CX and CRO. Recommended pair for dual motion proof: **Entitlement-aware triage** + **Proactive RMA** (CX) *or* **Trial conversion coach** + **ARR brief** (revenue). Architecture and acceptance pack cover all four.

---

## 3. UC-1 — Trial conversion coach

### 3.1 Persona and job

| Item | Detail |
| --- | --- |
| Users | AE, SDR, PLG success |
| Job | Coach trial-to-paid conversion with trusted usage + entitlement context |
| Cloud | Sales Cloud + Data Cloud + Agentforce |
| Pilot write scope | Soft: Tasks, recommended next steps, email draft suggestions |

### 3.2 Business context (NexusForge)

ForgeObserve trials often under-activate workspaces while ForgeEdge evaluation units sit unbound. Coaches historically guess from Looker screenshots. The agent must see golden Account, trial entitlement, seat utilization insight, and open Opportunities—without inventing device ownership.

### 3.3 Grounding inputs

| Source | Fields / insights |
| --- | --- |
| `dp.customer.golden` | Hierarchy, segment, AE |
| `dp.entitlement.active` | Trial tier, days remaining, `billing_status` |
| Data Cloud | `trial_conversion_propensity`, `account_health_score`, workspace activation aggregates |
| Sales Cloud | Opportunity stage, amount, close date, contact roles |

### 3.4 Tools

| Tool | Allow | Notes |
| --- | --- | --- |
| `getAccount360` | Yes | Golden only |
| `getEntitlements` | Yes | No payment tokens |
| `getUsageInsight` | Yes | Curated aggregates |
| `createFollowUpTask` | Yes | HITL not required |
| `updateOpportunityStage` | No in pilot | Human AE only |
| `issueRefund` | No | Out of scope |

### 3.5 Policies & HITL

- Deny `Payment-restricted` fields.
- No auto-discount beyond playbook suggestions.
- If entitlement DQ freshness breached, agent discloses low confidence and escalates to RevOps.

### 3.6 Success metrics

| Metric | Target |
| --- | --- |
| Coach sessions grounded on certified products | 100% |
| Hallucinated entitlement tier incidents | 0 in UAT |
| AE acceptance of recommended next step | Track baseline (informational) |

---

## 4. UC-2 — Entitlement-aware triage

### 4.1 Persona and job

| Item | Detail |
| --- | --- |
| Users | Support agents (Service Cloud); transitional Zendesk side-by-side |
| Job | Route and resolve “is this feature on my plan?” using live entitlement |
| Cloud | Service Cloud + Data Cloud + Agentforce |
| Pilot write scope | Case routing, suggested replies, entitlement summary on Case |

### 4.2 Business context

Misroutes spike when Zendesk tickets lack Salesforce Account linkage and Stripe seat state lags product flags. Agents escalate billing for feature questions that entitlement data should answer.

### 4.3 Grounding inputs

| Source | Fields / insights |
| --- | --- |
| `dp.entitlement.active` | Tier, feature flags, support SLA, `billing_status` |
| `dp.customer.golden` | Hierarchy for correct Case Account |
| Data Cloud | `entitlement_risk` |
| Service Cloud | Case subject/description, Contact |

### 4.4 Tools

| Tool | Allow | Notes |
| --- | --- | --- |
| `getEntitlements` | Yes | Certified only |
| `getAccount360` | Yes | |
| `suggestCaseRoute` | Yes | |
| `applyMacro` | Suggest only | Human confirms |
| `mutateStripeSubscription` | No | |
| Raw Zendesk historical dump | No | Sample link only |

### 4.5 Policies & HITL

- If `billing_status=past_due`, agent may explain feature freeze per policy but cannot collect cards—secure billing portal link for human.
- Cross-Account Case Account change → HITL.

### 4.6 Success metrics

| Metric | Target |
| --- | --- |
| Entitlement questions answered without billing queue | Lift vs baseline |
| Wrong Account on Case (UAT) | 0 |
| Median entitlement retrieve | &lt;2s p95 |

---

## 5. UC-3 — Proactive RMA assistant

### 5.1 Persona and job

| Item | Detail |
| --- | --- |
| Users | Support / hardware ops |
| Job | Detect fleet risk, propose RMA, ensure Device sits on correct golden Account |
| Cloud | Service Cloud + Device master via IDMC |
| Pilot write scope | Propose RMA Case; create RMA draft; **no** autonomous cross-Account rebind |

### 5.2 Business context

ForgeEdge serials rebound after depot repair; firmware mismatches cause false RMAs. DIY spreadsheets miss DQ. Agent must respect quarantine.

### 5.3 Grounding inputs

| Source | Fields |
| --- | --- |
| `dp.device.fleet` | Serial, firmware, bind confidence, DQ status, RMA status |
| `dp.customer.golden` | Account hierarchy |
| Data Cloud | `device_fleet_risk` |
| Device Registry (via CAI) | Authoritative RMA draft API |

### 5.4 Tools

| Tool | Allow | HITL |
| --- | --- | --- |
| `getDeviceFleet` | Yes | — |
| `proposeRma` | Yes | Auto if same Account & DQ certified |
| `rebindDeviceAccount` | Propose only | **Always HITL** |
| `overrideDqQuarantine` | No | Steward only |

### 5.5 Policies & HITL

- DQ fail (serial/firmware mismatch) → escalate; agent cannot open shipping RMA until steward clears (acceptance scenario 4).
- Bind confidence &lt;0.98 → HITL.
- Export-controlled SKU → metadata only; logistics action blocked.

### 5.6 Success metrics

| Metric | Target |
| --- | --- |
| RMA on wrong Account | 0 |
| Quarantine bypasses | 0 |
| Bind event→Case visibility | &lt;2 min median |

---

## 6. UC-4 — ARR / renewal brief (read-only first)

### 6.1 Persona and job

| Item | Detail |
| --- | --- |
| Users | AE, CSM, RevOps |
| Job | Generate account renewal brief from trusted ARR/entitlement/health signals |
| Cloud | Sales Cloud + Data Cloud + Agentforce |
| Pilot write scope | **Read-only**: brief document / Chatter / email draft—no Opportunity mutation |

### 6.2 Business context

RevOps reconciles ARR in BigQuery manually; briefs disagree with Stripe. Agent must use certified entitlement and golden Account—not warehouse one-offs.

### 6.3 Grounding inputs

| Source | Fields |
| --- | --- |
| `dp.customer.golden` | Hierarchy, segment |
| `dp.entitlement.active` | Tier, renew date, seats, `billing_status` |
| Data Cloud | Health, expansion propensity (curated) |
| Sales Cloud | Renewal Opportunity (read) |

### 6.4 Tools

| Tool | Allow |
| --- | --- |
| `getRenewalBrief` | Yes (compose) |
| `getAccount360` / `getEntitlements` | Yes |
| `updateOpportunityAmount` | **No** (post-pilot consideration) |
| `applyDiscount` | No |

### 6.5 Policies & HITL

- Read-only enforcement in tool permission set.
- ARR figures labeled with as-of timestamp and data product version.
- If NetSuite lag detected, brief marks revenue figures as “CRM/billing certified; ERP lag possible.”

### 6.6 Success metrics

| Metric | Target |
| --- | --- |
| Briefs citing certified products only | 100% |
| Write attempts blocked | 100% in pilot |
| AE/CSM usefulness score | Survey baseline |

---

## 7. HITL matrix (summary)

| Action | UC-1 | UC-2 | UC-3 | UC-4 |
| --- | --- | --- | --- | --- |
| Create Task / draft email | Auto | Auto | Auto | Auto |
| Case route suggest | — | Auto | Auto | — |
| Case Account change | — | HITL | HITL | — |
| RMA propose (same Account, DQ OK) | — | — | Auto | — |
| Device rebind cross-Account | — | — | HITL | — |
| Opportunity field update | Block | — | — | Block |
| Refund / credit | Block | Block | Block | Block |
| Read payment token | Deny | Deny | Deny | Deny |

---

## 8. Prompting and grounding guidelines

1. Instruct agents to refuse when data product certification is revoked or DQ status ≠ certified.
2. Cite golden IDs in agent responses for support auditability.
3. Prefer structured tool results over free-text memory for entitlements and serials.
4. On policy deny, explain safe alternative (“I can show billing status, not payment method details”).
5. Never invent device serials or seat counts—if tool fails, say so.

---

## 9. Security and privacy

- Workforce Okta SSO to Salesforce; agents run under scoped integration + user context.
- Event Monitoring + CAI audit for every tool call.
- No customer Auth0 tokens in agent context.
- GDPR/CCPA: minimize PII in briefs; honor suppressions from golden Contact.

---

## 10. Implementation mapping

| Asset | Location |
| --- | --- |
| Salesforce permission sets / actions | `salesforce/force-app/` |
| CAI agent APIs | `idmc/cai/` |
| Catalog policies | `idmc/catalog/` |
| Deploy | [deploy/05-data-cloud-agentforce.md](./deploy/05-data-cloud-agentforce.md) |
| Acceptance | Scenarios 1–4 in [acceptance/scenarios.md](./acceptance/scenarios.md) |

---

## 11. Rollout sequence

1. Configure grounding + deny policies in non-prod.  
2. Enable UC-2 or UC-1 with shadow mode (recommend only).  
3. Enable UC-3 with DQ quarantine proven.  
4. Enable UC-4 read-only.  
5. UAT acceptance pack.  
6. Production pilot hypercare (ops runbook).  

Post-90-day: consider bounded Opportunity updates and controlled credits with expanded HITL.

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
