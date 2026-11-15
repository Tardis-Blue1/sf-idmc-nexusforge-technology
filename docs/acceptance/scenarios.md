# NexusForge Systems — Acceptance Scenarios

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CDI, CAI, MDM, Data Quality, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Acceptance — Scenarios |
| Version | 1.0 |
| Environment | UAT / non-prod unless noted |
| Automation | `tests/acceptance/` mirrors these scripts |

---

## 0. How to use this pack

Each scenario is a **stepwise executable test script**: preconditions, exact actions, expected results, evidence to capture, and pass/fail criteria. Run in order 1→5 on a clean fixture set when possible. Record `correlation_id` values for every CAI invocation.

**Global preconditions**

- Deploy 01–06 complete in UAT.
- Fixtures loaded: enterprise Account, PLG duplicate, Stripe test customer, Device certified + Device quarantined, synthetic payment token attribute for deny test (never real PAN).
- Pilot Agentforce user in `NF_Agentforce_Pilot`.
- Clock sync verified across Stripe, IDMC, Salesforce (&lt;5s skew).

**Global evidence**

- Screenshots or CLI output attached to test run ID.
- JSON tool responses saved under `tests/acceptance/evidence/<run-id>/`.
- Dashboard snapshots for lag/match/DQ where applicable.

---

## Scenario 1 — Integration: subscription upgrade within SLA

### 1.1 Intent

Prove Stripe subscription upgrade lands in Salesforce entitlement/contract fields and ForgeObserve product entitlement within **&lt;5 minutes median**, and that Agentforce sees the new tier via governed API—not warehouse lag.

### 1.2 Preconditions

| ID | Fixture |
| --- | --- |
| A1 | Golden Account `GA-ACCEPT-001` linked to Stripe customer `cus_accept_001` |
| E1 | Entitlement__c tier `pro`, seats `10`, `billing_status=active` |
| S1 | Stripe subscription `sub_accept_001` on price `price_pro` |
| P1 | ForgeObserve org `org_accept_001` mapped to A1 |
| Agent | UC-1 or UC-2 enabled with `getEntitlements` |

### 1.3 Steps

| Step | Action | Command / UI |
| --- | --- | --- |
| 1 | Note `T0` UTC | `date -u +%Y-%m-%dT%H:%M:%SZ` |
| 2 | Upgrade Stripe subscription to enterprise price `price_enterprise` (test mode) | Stripe Dashboard or API `subscriptions.update` |
| 3 | Capture Stripe event ID | Dashboard Developers → Events |
| 4 | Locate CAI process run for event | IDMC Monitor; copy `correlation_id` |
| 5 | Wait MDM Subscription golden update | Confirm tier/seats survivorship |
| 6 | Query Salesforce Entitlement | `sf data query -q "SELECT Tier__c, Seats__c, Billing_Status__c, NF_MDM_Last_Sync__c FROM Entitlement__c WHERE Stripe_Subscription_Id__c='sub_accept_001'"` |
| 7 | Verify ForgeObserve entitlement | `GET /api/orgs/org_accept_001/entitlements` (non-prod) shows enterprise flags |
| 8 | Invoke Agentforce / demo `getEntitlements` for `GA-ACCEPT-001` | Demo UI or CAI smoke |
| 9 | Record `T_sf`, `T_fo`, `T_agent` when each reflects new tier | Evidence JSON |

### 1.4 Expected results

- CAI run **success**; correlation ID present end-to-end.
- Salesforce `Tier__c` = enterprise (or mapped picklist value); seats updated per Stripe quantity.
- ForgeObserve feature package matches enterprise template.
- Agent response tier matches Salesforce; **no** payment token fields in payload.
- `T_sf - T0`, `T_fo - T0`, `T_agent - T0` each **&lt; 5 minutes** (pass band); record if &lt;15 min P95 for single-run caveat—execute **n≥5** upgrades for median calculation in formal gate.

### 1.5 Automation hook

```bash
tests/acceptance/test_scenario_01_subscription_upgrade.sh
# asserts: median_lag_seconds < 300; agent_payload.has_token == false
```

### 1.6 Pass / fail

| Result | Criteria |
| --- | --- |
| **PASS** | Median lag &lt;300s over ≥5 runs; agent sees new tier; zero token fields |
| **FAIL** | Any run missing SF or product update &gt;15 min; agent stale/wrong tier; token leakage |

---

## Scenario 2 — MDM: Account merge + Device follows golden Account

### 2.1 Intent

Prove two Accounts (self-serve PLG + enterprise) merge under MDM survivorship; Device serial follows **golden** Account; Agentforce Case opens on correct hierarchy (wrong-account actions = 0).

### 2.2 Preconditions

| ID | Fixture |
| --- | --- |
| A-ENT | Enterprise parent `GA-ACCEPT-100` (Salesforce + NetSuite IDs) |
| A-PLG | PLG Account `GA-ACCEPT-101` with Stripe `cus_plg_101`, domain match to A-ENT |
| D1 | Device serial `NFEDGE-ACCEPT-4421` bound to Forge org on A-PLG; `Device__c.Golden_Account__c` = A-PLG |
| Match | Accounts in suspect or auto-merge eligible per domain+name rules |

### 2.3 Steps

| Step | Action |
| --- | --- |
| 1 | Snapshot pre-merge: query both Accounts’ golden IDs; Device lookup |
| 2 | In IDMC MDM, run match for A-PLG ↔ A-ENT (or approve suspect) |
| 3 | Apply merge: enterprise parent wins hierarchy; Stripe IDs retain on billing child per survivorship design |
| 4 | Publish golden keys to Salesforce |
| 5 | Re-query `Device__c` for serial `NFEDGE-ACCEPT-4421` — `Golden_Account__c` must resolve to surviving golden hierarchy (billing child under A-ENT or A-ENT per model—**document actual**; must **not** remain orphan PLG-only) |
| 6 | Create Service Cloud Case via Agentforce triage / RMA path referencing device serial |
| 7 | Confirm Case.AccountId is the surviving hierarchy Account (not losing duplicate) |
| 8 | Invoke `getAccount360` — hierarchy shows parent + billing child; device summary under correct Account |

### 2.4 Expected results

- Single golden commercial hierarchy; losing Account merged/retired per MDM rules.
- Device crosswalk `golden_account_id` updated; bind confidence ≥0.98.
- Case opened on correct Account; agent never references retired duplicate as primary.
- Crosswalk IDs present in Data Cloud profile for surviving Account.

### 2.5 Automation hook

```bash
tests/acceptance/test_scenario_02_account_merge_device.sh
# asserts: device.golden_account_id in surviving_set; case.account_id in surviving_set
```

### 2.6 Pass / fail

| Result | Criteria |
| --- | --- |
| **PASS** | Device + Case on surviving hierarchy; 0 wrong-account agent actions |
| **FAIL** | Device remains on losing Account; Case misfiled; agent cites duplicate |

---

## Scenario 3 — Governance: agent denied raw billing token

### 3.1 Intent

Prove Agentforce / CAI **denies** raw Stripe payment token (Payment-restricted) and falls back to certified `billing_status` on `dp.entitlement.active`; audit shows policy hit `POL-AGENT-DENY-STRIPE-TOKEN`.

### 3.2 Preconditions

| ID | Fixture |
| --- | --- |
| A1 | Account with active entitlement |
| F1 | Synthetic attribute `stripe_payment_method_token` = `tok_accept_synthetic` exists **only** in restricted store / staging—not on certified product |
| Policy | Catalog tag `Payment-restricted` + deny policy active |
| UI | Demo “Request raw billing token” control |

### 3.3 Steps

| Step | Action |
| --- | --- |
| 1 | Call `getEntitlements` normally — confirm `billing_status` returned |
| 2 | Call agent tool / CAI with explicit field request `stripe_payment_method_token` (demo deny button or test client) |
| 3 | Capture HTTP/tool error code and message |
| 4 | Query audit / metrics for `agent_tool_deny` with policy ID |
| 5 | Confirm Salesforce Agentforce user sees safe fallback text (no token value) |
| 6 | Grep evidence logs for `tok_accept_synthetic` — must **not** appear in agent response |

### 3.4 Expected results

- Step 1 success with `billing_status` ∈ {active, past_due, trialing, canceled}.
- Step 2 **denied**; correlation ID logged.
- Audit event includes agent ID, field path, policy ID.
- No token material in UI, SF, or agent transcript.

### 3.5 Automation hook

```bash
tests/acceptance/test_scenario_03_token_deny.sh
# asserts: response.status in {403,460_policy}; body contains no tok_; audit_row_exists
```

### 3.6 Pass / fail

| Result | Criteria |
| --- | --- |
| **PASS** | Deny + audit + billing_status still available |
| **FAIL** | Token returned; deny without audit; billing_status missing entirely without explanation |

---

## Scenario 4 — Device RMA: DQ quarantine then steward release

### 4.1 Intent

Prove firmware + serial mismatch is quarantined by DQ; agent escalates and cannot complete shipping RMA; after steward fix, RMA action allowed.

### 4.2 Preconditions

| ID | Fixture |
| --- | --- |
| D-Q | Device serial `NFEDGE-ACCEPT-9001`, model `FE-1000`, firmware **invalid** `0.0.0-bad` vs allowlist |
| DQ | Consistency rule active → `DQ_Status__c=Quarantine` |
| A1 | Valid golden Account ownership |
| Agent | UC-3 Proactive RMA enabled |

### 4.3 Steps

| Step | Action |
| --- | --- |
| 1 | Confirm Device__c DQ_Status = Quarantine; Catalog certification revoked for this record |
| 2 | Agent / demo `getDeviceFleet` — device flagged quarantined |
| 3 | Attempt `proposeRma` on `NFEDGE-ACCEPT-9001` |
| 4 | Expect **reject/escalate**; no RMA draft in Device Registry |
| 5 | Steward corrects firmware to allowlisted `2.4.1` in Registry; DQ re-runs |
| 6 | Confirm DQ_Status=Certified; bind confidence ≥0.98 |
| 7 | Retry `proposeRma` |
| 8 | Expect RMA draft ID; Case created on correct Account; HITL not required for same-Account certified |

### 4.4 Expected results

- Steps 3–4 blocked with explicit DQ reason code.
- Zero quarantine bypasses.
- Steps 7–8 succeed with correlation IDs; Registry draft exists.
- Lineage shows DQ state transition in Catalog/ops evidence.

### 4.5 Automation hook

```bash
tests/acceptance/test_scenario_04_rma_dq_quarantine.sh
# asserts: first_propose_rma == denied_dq; second_propose_rma == draft_created
```

### 4.6 Pass / fail

| Result | Criteria |
| --- | --- |
| **PASS** | Deny while quarantined; allow after steward fix; correct Account |
| **FAIL** | RMA created while quarantined; still denied after certify; wrong Account |

---

## Scenario 5 — Buy-vs-build: lineage and match-rate demo notes

### 5.1 Intent

Demonstrate operational **lineage** and **match-rate** dashboards delivered by Informatica IDMC (+ metrics publish) that an AI-scaffolded DIY pipeline would not provide out of the box. This scenario is both an acceptance check (dashboards exist and are accurate) and a **demo script** for the CTO buy-vs-build conversation.

### 5.2 Preconditions

- Scenarios 1–2 have produced recent MDM publishes.
- Snowflake (or IDMC-native) dashboards: match rate, DQ fails, lineage for `dp.customer.golden` / `dp.device.fleet` / `dp.entitlement.active`.
- Demo UI Trust metrics panel online.

### 5.3 Steps (executable demo script)

| Step | Action | Talking point (architecture, not sales theater) |
| --- | --- | --- |
| 1 | Open lineage for `Entitlement__c.Billing_Status__c` (or Catalog equivalent) | “Source Stripe → CAI → MDM → DQ certify → Salesforce/Data Cloud → agent tool. DIY Glue jobs rarely ship enforceable lineage to agent runtime.” |
| 2 | Show lineage completeness ≥95% on pilot products | KPI from governance success metrics |
| 3 | Open match-rate dashboard for top logos / pilot set | “Survivorship + suspect queues are productized; generated Python drifts without steward workflow.” |
| 4 | Correlate scenario 2 merge in match history | Evidence that merge decisions are audited |
| 5 | Show agent allow/deny metric including scenario 3 | “Governance is runtime. Agents amplify blast radius without Catalog policy.” |
| 6 | Contrast: point to absence of agent write-back from Snowflake | “Buy control plane; build adapters. Warehouse is analytical-only.” |
| 7 | Capture screenshots into evidence pack | Required for PASS |

### 5.4 Expected results

- Lineage path visible for subscription billing_status and device golden_account_id.
- Match rate metric populated and consistent with MDM UI (±1% tolerance).
- Deny counts increment after scenario 3.
- Demo notes below acknowledged by EA/CTO in sign-off comment.

### 5.5 Demo notes (buy-vs-build narrative)

1. **Day-1 code ≠ year-1 reliability** — appliance bind ↔ entitlement ↔ invoice disputes need durable survivorship; show match history age and steward SLA.
2. **Agents amplify blast radius** — replay scenario 2/3: wrong Account or leaked token is a security/revenue incident.
3. **Governance is runtime** — policy deny is a machine event, not a wiki page.
4. **Buy control plane; build adapters** — ForgeObserve/Device Registry connectors remain NexusForge-owned; IDMC owns orchestration, MDM, DQ, lineage, policy.
5. **Acceptance proof** — scenarios 1–4 are the operational evidence; this scenario packages the executive narrative on the same stack.

### 5.6 Automation hook

```bash
tests/acceptance/test_scenario_05_lineage_matchrate.sh
# asserts: lineage_completeness >= 95; match_rate_endpoint_ok; evidence_screenshots >= 3
```

### 5.7 Pass / fail

| Result | Criteria |
| --- | --- |
| **PASS** | Lineage + match-rate + allow/deny visible; evidence captured; EA acknowledges demo notes |
| **FAIL** | Missing lineage for pilot attributes; match-rate blank; no evidence pack |

---

## Pack execution record

| Scenario | Run ID | Result | Correlation IDs | Tester | Date |
| --- | --- | --- | --- | --- | --- |
| 1 Integration subscription upgrade | | | | | |
| 2 MDM Account merge + Device | | | | | |
| 3 Governance token deny | | | | | |
| 4 Device RMA DQ quarantine | | | | | |
| 5 Buy-vs-build lineage/match-rate | | | | | |

**Pack PASS** requires all five PASS. Go-live blocked otherwise ([deploy/07-go-live-checklist.md](../deploy/07-go-live-checklist.md)).

---

## Traceability

| Scenario | Pillar | Primary docs |
| --- | --- | --- |
| 1 | Integration | [03-integration-catalog.md](../03-integration-catalog.md) |
| 2 | MDM | [02-data-model-mdm.md](../02-data-model-mdm.md) |
| 3 | Governance | [04-governance-and-policies.md](../04-governance-and-policies.md) |
| 4 | DQ + Agentforce | [04-governance-and-policies.md](../04-governance-and-policies.md), [05-agentforce-use-cases.md](../05-agentforce-use-cases.md) |
| 5 | Buy-vs-build | [01-architecture.md](../01-architecture.md), [00-engagement-overview.md](../00-engagement-overview.md) |

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
