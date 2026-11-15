# NexusForge Systems — Salesforce Metadata

Customer delivery package for **NexusForge Systems** (ForgeObserve SaaS + ForgeEdge hardware).

This directory contains deployable **Salesforce** Sales Cloud / Service Cloud metadata that aligns CRM engagement objects with golden keys published by **Informatica** Intelligent Data Management Cloud (IDMC) MDM.

## Platform labeling

| Platform | Role in this package |
| --- | --- |
| **Salesforce** | System of engagement (Account, Contact, Case, Device, Entitlement, Product SKU) |
| **Informatica** IDMC | System of reference for masters; CAI Named Credential target for agent write-back |

## Contents

- Custom objects: `Device__c`, `Entitlement__c`, `ProductSKU__c`
- Account / Contact golden-key and crosswalk fields
- Permission sets: Agent Read, Integration User, Data Steward
- Apex upsert helpers with idempotent golden-key logic
- Named Credential placeholder for IDMC CAI API
- Sample Flow: Case → Device entitlement check

## Prerequisites

- Salesforce CLI (`sf`) authenticated to a non-prod scratch or sandbox org
- Named Credential URL and auth configured via org secrets (never commit credentials)

## Deploy

```bash
./scripts/deploy.sh --target-org <alias>
./scripts/assign-perms.sh --target-org <alias> --user <username>
```

## Security

No API keys, tokens, or connection secrets are stored in this repository. Wire Named Credentials and External Credentials in the target org or via CI secrets injection.
