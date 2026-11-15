# NexusForge Systems — Informatica IDMC Config-as-Code

Customer delivery package for **NexusForge Systems** (ForgeObserve SaaS + ForgeEdge hardware).

This directory holds **Informatica** Intelligent Data Management Cloud (**IDMC**) configuration-as-code: Cloud Application Integration (CAI) process definitions, Cloud Data Integration (CDI) mapping specs, MDM models/match/survivorship, Data Quality rule packs, and Catalog / governance policies.

## Platform labeling

| Platform | Role |
| --- | --- |
| **Informatica** IDMC | Integration fabric, MDM system of reference, DQ gates, Catalog & agent policies |
| **Salesforce** | System of engagement; receives golden keys and entitlement/device sync |

## Layout

| Path | Contents |
| --- | --- |
| `cai/` | CAI process defs (Stripe, Device Registry, Zendesk, Agent write-back) |
| `cdi/` | CDI mapping specs for Account, Contact, Device, Subscription, Product |
| `mdm/` | Customer/Contact/Product/Device/Subscription models, match, survivorship, hierarchy |
| `dq/` | Completeness, validity, uniqueness, referential-integrity packs |
| `catalog/` | Data products and agent consumption policies |

## Secrets

Connection credentials, OAuth client secrets, and Secure Agent keys are **not** stored here. Reference secret ARNs / vault paths from `infra/terraform` and inject at deploy time.

## Import notes

YAML files are human-readable specs for IDMC Asset Management / CI import adapters. Map each file to the corresponding IDMC project asset in non-prod first; validate correlation ID propagation on every CAI process.
