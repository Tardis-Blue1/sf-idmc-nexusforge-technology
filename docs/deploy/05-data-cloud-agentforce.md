# Deploy 05 — Data Cloud and Agentforce

**Solutions:** Salesforce Data Cloud and Agentforce · Sales Cloud / Service Cloud engagement · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (certified data products, CAI agent APIs, MDM golden keys, DQ gates, Catalog policies)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 05 — Data Cloud & Agentforce |
| Version | 1.0 |
| Depends on | [04-integrations.md](./04-integrations.md) |
| Use cases | [05-agentforce-use-cases.md](../05-agentforce-use-cases.md) |

---

## 1. Purpose

Activate Salesforce Data Cloud unified profiles and calculated insights aligned to Informatica MDM golden keys, then configure Agentforce pilot agents with grounding, tool permissions, HITL, and policy denials for Payment-restricted fields.

---

## 2. Data Cloud setup

### 2.1 Ingestion

1. Enable Data Cloud in sandbox/trial per license.
2. Configure connectors / Ingestion API for:
   - Salesforce CRM objects (Account, Contact, Device__c, Entitlement__c)
   - IDMC-published golden extracts (preferred for master attributes)
3. Map identity keys:
   - Party / Account identifiers ← `NF_Golden_Account_Id__c` / `NF_Golden_Contact_Id__c`
4. **Do not** enable competing merge that overrides MDM for Account hierarchy in pilot; document IR settings to prefer golden keys.

### 2.2 Data model & insights

Create/activate calculated insights (names illustrative):

| Insight | Grain | Use |
| --- | --- | --- |
| `account_health_score` | golden Account | Trial coach, renewal |
| `trial_conversion_propensity` | Account | UC-1 |
| `entitlement_risk` | Account/Subscription | UC-2 |
| `device_fleet_risk` | Account | UC-3 |

Source only certified attributes; exclude quarantine devices from fleet risk inputs.

### 2.3 Consent / governance

- Align Contact activation with consent flags where emailing.
- Restrict insights containing PII to workforce Agentforce contexts.

### 2.4 Validation

- Profile retrieve for sample golden Account &lt;2s p95 via tool path.
- Verify entitlement tier matches Salesforce Entitlement__c after Stripe test upgrade.

---

## 3. Agentforce platform prep

1. Assign `NF_Agentforce_Pilot` permission set to UAT personas.
2. Confirm Event Monitoring captures Einstein/Agentforce actions where available.
3. Register external actions / invocable actions pointing at Named Credential `NF_CAI_Agent_API`:
   - getAccount360  
   - getEntitlements  
   - getDeviceFleet  
   - proposeRma  
   - getRenewalBrief  
   - createFollowUpTask (can be native Salesforce action)
4. Action output filters: strip any accidental sensitive fields client-side as defense-in-depth (primary enforce in CAI/Catalog).

---

## 4. Configure pilot agents

Implement all four; enable two for “production-like” pilot per stakeholder choice.

### 4.1 Trial conversion coach (UC-1)

| Setting | Value |
| --- | --- |
| Channel | Sales Cloud |
| Topics | Trial activation, seat utilization, Opportunity next steps |
| Grounding | Data Cloud insights + getAccount360 + getEntitlements |
| Actions allowed | createFollowUpTask, draft email suggest |
| Actions blocked | Opportunity stage update, refunds, Stripe mutate |

### 4.2 Entitlement-aware triage (UC-2)

| Setting | Value |
| --- | --- |
| Channel | Service Cloud Case |
| Grounding | getEntitlements, getAccount360, entitlement_risk |
| Actions allowed | suggestCaseRoute, suggest reply |
| Blocked | Stripe mutate, payment token read |

### 4.3 Proactive RMA (UC-3)

| Setting | Value |
| --- | --- |
| Channel | Service Cloud |
| Grounding | getDeviceFleet, device_fleet_risk |
| Actions allowed | proposeRma when DQ=Certified and same Account |
| HITL | rebindDeviceAccount; quarantine devices |

Test quarantine fixture: agent must escalate, not ship RMA.

### 4.4 ARR / renewal brief (UC-4)

| Setting | Value |
| --- | --- |
| Channel | Sales Cloud |
| Grounding | getRenewalBrief, insights |
| Mode | Read-only; block Opportunity field updates |

---

## 5. Policy enforcement verification

1. Call getEntitlements with debug flag requesting `stripe_payment_method_token` → expect **deny** + audit (`POL-AGENT-DENY-STRIPE-TOKEN`).
2. Confirm Agentforce user-visible message uses safe fallback.
3. Attempt cross-tenant device get → hard fail + alert.
4. Record evidence for acceptance scenario 3.

---

## 6. HITL configuration

| Action | Mechanism |
| --- | --- |
| Cross-Account device rebind | Approval Work Item / Flow to steward queue |
| Case Account change | Manager approval |
| Refunds | Not exposed in pilot |

Document approver roster in ops runbook.

---

## 7. Shadow mode then assist mode

1. **Shadow (3–5 days):** agents generate recommendations logged but not shown—or shown read-only to champions.
2. Review wrong-account and policy metrics.
3. **Assist:** enable for `NF_Agentforce_Pilot` group.
4. No autonomous money movement in 90-day pilot.

---

## 8. Exit checklist

- [ ] Data Cloud profiles keyed by golden IDs
- [ ] Four calculated insights active (or waived with EA sign-off)
- [ ] All CAI actions registered and authorized
- [ ] Four agents configured; two enabled for pilot users
- [ ] Token deny proven with audit event
- [ ] Cross-tenant deny proven
- [ ] HITL paths tested for RMA rebind
- [ ] Profile retrieve p95 &lt;2s on sample
- [ ] Event Monitoring / audit retention configured
- [ ] UC owners (VP CX / CRO) accept grounding scope

**Next:** [06-demo-ui.md](./06-demo-ui.md)

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
