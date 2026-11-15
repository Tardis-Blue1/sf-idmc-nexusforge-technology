# NexusForge Systems — Data Model & Master Data Management

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (MDM, CDI, CAI, Data Quality, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | 02 — Data Model & MDM |
| Version | 1.0 |
| System of reference | Informatica MDM |
| System of engagement | Salesforce Sales / Service Cloud |
| Activation | Salesforce Data Cloud |

---

## 1. Purpose

Define the master data domains, attributes, match/merge rules, survivorship, hierarchy, and crosswalk ID publication required for NexusForge’s trusted customer/product/device graph. Agents treat these masters as their world model; incorrect merges become incorrect autonomous actions.

---

## 2. MDM operating model

| Concept | NexusForge rule |
| --- | --- |
| System of reference | Informatica MDM owns golden records and merge decisions |
| System of engagement | Salesforce displays golden keys and engagement attributes; does not unilaterally merge masters |
| Activation / profile | Data Cloud unified profiles **consume** MDM crosswalk IDs; IR aligned to MDM, not competing merge logic |
| Domain SoRs | Stripe, NetSuite, ForgeObserve, Device Registry, Zendesk contribute source records |
| Stewardship | Data stewards resolve quarantine and low-confidence matches via IDMC workflows |
| Agent access | Only certified attributes on cataloged data products |

---

## 3. Master domains

### 3.1 Account / Customer

**Business meaning:** Legal or commercial entity that buys ForgeObserve seats and/or ForgeEdge appliances. Includes self-serve PLG orgs and enterprise logos with complex hierarchies.

| Attribute group | Examples | Sources |
| --- | --- | --- |
| Identity | Legal name, DBA, tax ID (where collected), website domain | Salesforce, NetSuite, Stripe customer |
| Commercial | Segment (SMB/MM/ENT), channel, owner AE | Salesforce |
| Hierarchy | Parent Account, billing child, product org mapping | MDM hierarchy + ForgeObserve org |
| Keys | `golden_account_id`, `sf_account_id`, `stripe_customer_id`, `netsuite_customer_id`, `forge_org_ids[]` | Crosswalk |
| Risk / compliance | Export-control flag (appliance SKUs), DPA region | Manual + NetSuite |

**Salesforce mapping:** Account (+ custom golden key fields). Data Cloud: Account/Unified Account profile.

### 3.2 Contact / User

**Business meaning:** People who may be buying-center stakeholders **and/or** product users (Auth0 identities). One human may have multiple product users across orgs.

| Attribute group | Examples | Sources |
| --- | --- | --- |
| Identity | Name, email, phone, title | Salesforce, Zendesk, Auth0 (hashed/subject) |
| Roles | Bill-to, technical contact, admin seat | Salesforce + ForgeObserve |
| Keys | `golden_contact_id`, `sf_contact_id`, `zendesk_user_id`, `auth0_user_ids[]` | Crosswalk |
| Privacy | Consent flags, region, do-not-contact | Salesforce / Data Cloud consent |

**Match caution:** Email is strong but not unique across contractors; combine email + Account context + Auth0 subject where available.

### 3.3 Subscription / Entitlement

**Business meaning:** Commercial subscription (Stripe) projected to product entitlements (seats, feature flags, support tier) and CRM Contract/Subscription records.

| Attribute group | Examples | Sources |
| --- | --- | --- |
| Commercial | Plan/tier, quantity seats, MRR/ARR components, renew date | Stripe, NetSuite, Salesforce |
| Product | Feature flag set, workspace limits, support SLA tier | ForgeObserve |
| Status | `trial`, `active`, `past_due`, `canceled`, `entitlement_pending` | Derived |
| Keys | `golden_subscription_id`, `stripe_subscription_id`, `sf_contract_id`, `forge_entitlement_id` | Crosswalk |

**Agent rule:** Agents read `billing_status` and entitlement flags from `dp.entitlement.active`—never raw payment tokens.

### 3.4 Product / SKU

**Business meaning:** Sellable units spanning SaaS plans and appliance SKUs; bridges CPQ/catalog, Stripe Price IDs, and NetSuite items.

| Attribute group | Examples | Sources |
| --- | --- | --- |
| Identity | SKU code, name, family (SaaS vs Appliance) | Salesforce Product2, NetSuite item, Stripe Price/Product |
| Commercial | List metrics, entitlement template | CPQ light catalog |
| Compliance | Export-controlled appliance flag | Product master |
| Keys | `golden_sku_id`, `sf_product2_id`, `stripe_price_id`, `netsuite_item_id` | Crosswalk |

### 3.5 Device / Asset

**Business meaning:** ForgeEdge appliance instance identified by serial; bound to a tenant (ForgeObserve org) and ultimately a golden Account.

| Attribute group | Examples | Sources |
| --- | --- | --- |
| Identity | Serial number, model, ship date | Device Registry, NetSuite fulfillment |
| State | Firmware version, health, RMA status | Device Registry, ForgeObserve telemetry aggregates |
| Binding | `tenant_org_id`, `golden_account_id`, bind confidence | Device Registry + MDM |
| Keys | `golden_device_id`, `serial_number`, `registry_device_id`, `sf_device_id` | Crosswalk |

**Survivorship highlight:** Latest **verified** serial↔tenant binding wins; disputed binds quarantine for steward.

---

## 4. Logical relationships

```text
Parent Account (Enterprise)
 ├── Billing Account (child)
 │     ├── Subscription / Entitlement ── Product/SKU
 │     └── Contact (bill-to)
 ├── Product Org (ForgeObserve) ←── mapped via crosswalk
 │     ├── Users (Contacts / Auth0)
 │     └── Devices (ForgeEdge serials)
 └── Opportunity / Case (engagement only)
```

Hierarchy rules:

1. Enterprise parent wins commercial hierarchy when match confidence ≥ threshold.
2. Self-serve Stripe customer may start as standalone Account; on enterprise attach, merge under parent with billing child retained.
3. Device always resolves to exactly one golden Account for active fleet; multi-bind is invalid and quarantined.
4. Entitlements inherit Account hierarchy for support routing but remain tied to the subscribing billing entity.

---

## 5. Match rules

### 5.1 Account match

| Priority | Rule | Action |
| --- | --- | --- |
| 1 | Exact `stripe_customer_id` or `netsuite_customer_id` | Auto-link |
| 2 | Exact normalized website domain + country | Auto-match if single candidate |
| 3 | Fuzzy legal name (token/Jaro) + overlapping domain or tax ID | Suspect queue if score 0.85–0.94; auto ≥0.95 with steward sample audit |
| 4 | ForgeObserve org billing email domain clustering | Suggest only; no auto-merge without #1–3 |

**Pilot target:** Duplicate Account rate &lt;2% for top 2,000 logos.

### 5.2 Contact match

| Priority | Rule | Action |
| --- | --- | --- |
| 1 | Exact email + same golden Account | Auto-merge |
| 2 | Auth0 subject match | Auto-link |
| 3 | Email across Accounts | Suspect; may be multi-Account consultant—**do not** auto-merge across enterprise parents without steward |

### 5.3 Device match

| Priority | Rule | Action |
| --- | --- | --- |
| 1 | Exact serial number | Identity |
| 2 | Serial + model checksum from registry | Confirm |
| 3 | Tenant bind vs Account crosswalk | Require Account match confidence ≥0.98 for agent RMA actions |

**Pilot target:** Device-to-Account match confidence ≥98% for active fleet.

### 5.4 Product / SKU match

| Priority | Rule | Action |
| --- | --- | --- |
| 1 | Stripe `price_id` ↔ Salesforce Product2 custom field | Auto |
| 2 | NetSuite item ↔ SKU code | Auto |
| 3 | Name-only fuzzy | Steward only |

### 5.5 Subscription match

| Priority | Rule | Action |
| --- | --- | --- |
| 1 | Stripe `subscription_id` | Identity |
| 2 | Account + plan + overlapping active window | Suspect duplicate if two actives |

---

## 6. Survivorship

Survivorship is **attribute-level**, not “whole record from one system.”

| Domain | Attribute | Winning source / rule |
| --- | --- | --- |
| Account | Legal name | NetSuite if present; else Salesforce enterprise; else Stripe |
| Account | AE / owner | Salesforce |
| Account | Billing address | NetSuite bill-to; else Stripe |
| Account | Hierarchy parent | MDM steward-approved enterprise hierarchy |
| Contact | Email | Most recently verified Auth0/Salesforce |
| Contact | Phone | Salesforce if verified; else Zendesk |
| Subscription | Status | Stripe canonical for payment status; ForgeObserve for feature enablement lag flag |
| Subscription | Seat quantity | Stripe quantity; ForgeObserve seats_used is observational |
| Product | Entitlement template | Product master (Salesforce/MDM), not Stripe nickname |
| Device | Firmware | Device Registry latest telemetry heartbeat |
| Device | Tenant binding | Latest **verified** bind event; unverified → quarantine |
| Device | Ship / warranty | NetSuite fulfillment |

**Enterprise vs self-serve conflict:** When merging PLG Account into enterprise hierarchy, commercial fields from enterprise parent survive; Stripe IDs remain on billing child; product org links retained.

---

## 7. Crosswalk IDs and publication

### 7.1 Canonical keys

| Key | Format (example) | Published to |
| --- | --- | --- |
| `golden_account_id` | `GA-XXXXXXXX` | Salesforce Account, Data Cloud, CAI responses |
| `golden_contact_id` | `GC-XXXXXXXX` | Salesforce Contact, Data Cloud |
| `golden_subscription_id` | `GS-XXXXXXXX` | Salesforce Contract/custom, Data Cloud |
| `golden_sku_id` | `GK-XXXXXXXX` | Product2, entitlement templates |
| `golden_device_id` | `GD-XXXXXXXX` | Device__c, Case, RMA flows |

### 7.2 Salesforce fields (illustrative)

- `Account.NF_Golden_Account_Id__c`
- `Account.NF_MDM_Match_Score__c`
- `Account.NF_MDM_Last_Sync__c`
- `Contact.NF_Golden_Contact_Id__c`
- `Device__c.NF_Golden_Device_Id__c`
- `Device__c.Serial_Number__c`
- `Device__c.Golden_Account__c` (lookup)
- `Entitlement__c.NF_Golden_Subscription_Id__c`

### 7.3 Data Cloud alignment

- External ID / party identification fields store golden keys.
- Unified profile linking keys **must** prefer MDM golden IDs over raw email-only IR for Account hierarchy scenarios.
- Calculated insights reference golden Account as grain where possible.

### 7.4 API contract for Agentforce

```json
{
  "golden_account_id": "GA-0F3A91C2",
  "hierarchy": { "parent": "GA-00AA11BB", "role": "billing_child" },
  "entitlements": { "tier": "pro", "seats": 120, "billing_status": "active" },
  "devices_summary": { "active": 14, "rma_open": 1 },
  "correlation_id": "c0ffee-..."
}
```

Raw Stripe payment method IDs and tokens are absent by contract.

---

## 8. Initial load and incremental strategy

| Phase | Scope |
| --- | --- |
| Pilot sample | Top 500 Accounts, related Contacts, active Subscriptions, Devices for those Accounts |
| Top-logo focus | Top 2,000 logos duplicate remediation |
| Incremental | CDC/events continuously; nightly CDI reconcile for NetSuite |
| Zendesk | Sample users/orgs only in pilot—not full history |

Load sequence: Product/SKU → Account → Contact → Subscription/Entitlement → Device (devices require Account crosswalk).

---

## 9. Stewardship and exception queues

| Queue | Trigger | SLA |
| --- | --- | --- |
| Account suspect match | Score 0.85–0.94 | 2 business days |
| Cross-Account contact | Same email, different parents | 3 business days |
| Device bind conflict | Two tenants claim serial | 4 business hours (RMA impact) |
| SKU map miss | Stripe price without Product2 | 1 business day |
| DQ quarantine | See governance DQ gates | Per severity |

Stewards use IDMC MDM UI; Salesforce shows read-only match score and “pending steward” badge where useful.

---

## 10. Success metrics (MDM)

| Metric | Target |
| --- | --- |
| Duplicate Account rate (top 2,000) | &lt;2% |
| Device→Account confidence (active fleet) | ≥98% |
| Agent wrong-account actions in UAT | 0 |
| Golden key coverage on active Accounts | ≥99% of pilot set |
| Suspect queue age P95 | Within queue SLAs above |

---

## 11. Relationship to other pillars

- Integration must deliver source records with stable natural keys—[03-integration-catalog.md](./03-integration-catalog.md).
- Governance certifies which MDM attributes agents may see—[04-governance-and-policies.md](./04-governance-and-policies.md).
- Acceptance scenario 2 exercises Account merge + Device follow—[acceptance/scenarios.md](./acceptance/scenarios.md).

**Specs in repo:** `idmc/mdm/` (model, match, survivorship).

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
