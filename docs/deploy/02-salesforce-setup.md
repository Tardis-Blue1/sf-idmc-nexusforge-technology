# Deploy 02 — Salesforce Setup

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (integration targets and golden key publication)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 02 — Salesforce Setup |
| Version | 1.0 |
| Depends on | [01-prerequisites.md](./01-prerequisites.md) |

---

## 1. Purpose

Bootstrap the Salesforce sandbox as system of engagement: custom objects/fields for Device and Entitlement, golden key fields, permission sets, Connected App, Named Credentials placeholders, Flows, and baseline UI so IDMC and Agentforce can attach.

Metadata lives under `salesforce/force-app/`. Prefer source-driven deploy via Salesforce CLI.

---

## 2. Org preparation

1. Authenticate CLI to sandbox:
   ```bash
   sf org login jwt --client-id ... --jwt-key-file ... --username ... --instance-url ... --alias nf-uat
   ```
2. Confirm Sales Cloud + Service Cloud features; enable Cases, Accounts, Contacts, Opportunities, Products.
3. Enable **Change Data Capture** for Account, Contact, and custom objects listed below (for IF-SF-CDC-07).
4. Create integration user `nf.integration@nexusforge.example` (or sandbox equivalent) with API enabled; MFA via SSO.
5. Optional: enable Event Monitoring; note Shield decision from CISO.

---

## 3. Data model — custom objects and fields

### 3.1 Account / Contact golden keys

Deploy fields (API names illustrative—match metadata in repo):

| Object | Field | Type | Purpose |
| --- | --- | --- | --- |
| Account | `NF_Golden_Account_Id__c` | Text(40), External ID, Unique | MDM crosswalk |
| Account | `NF_MDM_Match_Score__c` | Number(3,2) | Steward visibility |
| Account | `NF_MDM_Last_Sync__c` | DateTime | Freshness |
| Account | `NF_Stripe_Customer_Id__c` | Text(255), External ID | Integration |
| Account | `NF_NetSuite_Customer_Id__c` | Text(64) | Integration |
| Account | `NF_Forge_Org_Ids__c` | Long Text | Semi-structured list / child object preferred if volume high |
| Contact | `NF_Golden_Contact_Id__c` | Text(40), External ID, Unique | MDM |
| Contact | `NF_Zendesk_User_Id__c` | Text(64) | Sample sync |

### 3.2 Device__c

| Field | Type | Notes |
| --- | --- | --- |
| `Name` | Auto number / serial display | |
| `Serial_Number__c` | Text, External ID, Unique | |
| `NF_Golden_Device_Id__c` | Text, External ID | |
| `Golden_Account__c` | Lookup(Account) | Required for agent RMA |
| `Firmware_Version__c` | Text | DQ validated |
| `Model__c` | Text / picklist | |
| `Tenant_Org_Id__c` | Text | ForgeObserve org |
| `Bind_Confidence__c` | Number | |
| `RMA_Status__c` | Picklist | None, Proposed, Open, Closed |
| `DQ_Status__c` | Picklist | Certified, Quarantine, Pending |
| `Registry_Device_Id__c` | Text | |

Record types: `Standard_Appliance`, `Eval_Unit` (optional).

### 3.3 Entitlement__c (or extend standard Entitlement)

| Field | Type | Notes |
| --- | --- | --- |
| `Account__c` | Master-Detail/Lookup | |
| `NF_Golden_Subscription_Id__c` | Text, External ID | |
| `Stripe_Subscription_Id__c` | Text, External ID | |
| `Tier__c` | Picklist | trial, pro, enterprise, … |
| `Seats__c` | Number | |
| `Billing_Status__c` | Picklist | active, past_due, trialing, canceled |
| `Renew_Date__c` | Date | |
| `Feature_Flags_Summary__c` | Long Text | Curated |
| `DQ_Status__c` | Picklist | |

**Do not** create fields for raw Stripe payment tokens on any agent-visible object.

### 3.4 Product2

| Field | Purpose |
| --- | --- |
| `NF_Golden_Sku_Id__c` | MDM |
| `NF_Stripe_Price_Id__c` | Match |
| `NF_NetSuite_Item_Id__c` | Match |
| `NF_Export_Controlled__c` | Checkbox |

### 3.5 Case enhancements

- Lookup `Device__c`
- Lookup `Entitlement__c`
- Formula/badge fields for `DQ_Status__c` from Device

---

## 4. Permission sets

| Permission set | Audience | Rights |
| --- | --- | --- |
| `NF_Integration_Minimal` | Integration user | CRUD on Device/Entitlement as needed; Read Account/Contact/Product; API |
| `NF_Steward_Ro` | Stewards | Read golden fields, DQ status |
| `NF_Support_Agent` | Service agents | Case + Device + Entitlement read; limited edit |
| `NF_AE_CSM` | Sales | Account 360 fields; Opportunities |
| `NF_Agentforce_Pilot` | Pilot users | Access to Agentforce agents + action permissions (no Payment-restricted) |

Assign via scripts in `salesforce/scripts/`.

---

## 5. Connected App and Named Credentials

1. Create Connected App `NF_IDMC_Integration` — OAuth, JWT bearer if used; scopes: `api`, `refresh_token`, `full` minimized per security review.
2. Create Named Credential `NF_CAI_Agent_API` pointing to CAI process base URL (filled in integrations phase).
3. External Credential store references secrets manager / named principal—no secret in git.
4. Remote site settings for CAI and any demo endpoints.

---

## 6. UI and Flow baseline

1. **Account Lightning page:** highlight golden ID, match score, related Entitlements, Devices.
2. **Case Lightning page:** Device + Entitlement components; Agentforce actions panel when enabled.
3. **Flow (optional):** `NF_Case_Suggest_Entitlement_Summary` — screen flow reading Entitlement__c (human-assist before agent).
4. Compact layouts include Serial Number and Billing Status.

---

## 7. Deploy commands

```bash
sf project deploy start --source-dir salesforce/force-app --target-org nf-uat
sf apex run --file salesforce/scripts/assign-permission-sets.apex --target-org nf-uat
```

Validate:

```bash
sf data query --query "SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName IN ('Device__c','Entitlement__c')" --target-org nf-uat
```

---

## 8. CDC and Platform Events

1. Subscribe CDC for Account, Contact, Device__c, Entitlement__c in IDMC (configured in IDMC setup).
2. Optional Platform Event `NF_Integration_Alert__e` for business-critical sync failures (ops).

---

## 9. Exit checklist

- [ ] Metadata deployed without errors
- [ ] Golden key fields External ID indexed
- [ ] Device__c and Entitlement__c accessible to integration user
- [ ] No payment token fields present
- [ ] Connected App + Named Credential stubs created
- [ ] CDC enabled on required entities
- [ ] Permission sets assigned to pilot personas
- [ ] Account/Case pages show Device & Entitlement
- [ ] Sample Accounts loaded (or ready for MDM initial load)

**Next:** [03-idmc-setup.md](./03-idmc-setup.md)

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
