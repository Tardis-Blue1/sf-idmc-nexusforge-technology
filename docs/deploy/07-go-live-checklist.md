# Deploy 07 — Go-Live Checklist

**Solutions:** Salesforce Sales Cloud, Service Cloud, Data Cloud, and Agentforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce (CDI, CAI, MDM, DQ, Catalog, Governance)

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 07 — Go-Live Checklist |
| Version | 1.0 |
| Depends on | Deploy 01–06 complete; [acceptance/scenarios.md](../acceptance/scenarios.md) passed in UAT |

---

## 1. Purpose

Gate production (or production-like pilot) cutover for integrations, MDM publication, certified data products, and two Agentforce use cases. No go-live without acceptance pack sign-off and CISO policy confirmation.

---

## 2. Entry criteria

- [ ] Prerequisites prod secrets slotted (separate from non-prod)
- [ ] Salesforce production (or designated pilot org) metadata deployed
- [ ] IDMC prod connections validated
- [ ] UAT acceptance scenarios 1–5 **passed** with evidence links
- [ ] Hypercare roster named (see §7)
- [ ] Rollback plan reviewed (§6)

---

## 3. Pre-cutover technical checklist

### 3.1 Salesforce

- [ ] Golden key fields deployed; External IDs indexed
- [ ] Integration user locked to `NF_Integration_Minimal`
- [ ] Named Credentials point to **prod** CAI URLs
- [ ] CDC enabled
- [ ] Agentforce pilot permission set limited to named users
- [ ] No Payment-restricted custom fields on agent layouts

### 3.2 IDMC

- [ ] CDI/CAI promoted via change control (export diff reviewed)
- [ ] MDM match rules version tagged; baseline match rate recorded
- [ ] DQ gates active; break-glass procedure documented
- [ ] Catalog products certified in prod
- [ ] `POL-AGENT-DENY-STRIPE-TOKEN` active
- [ ] Secure Agent healthy (if used)
- [ ] Alerts wired to prod ops channel

### 3.3 Domain systems

- [ ] Stripe **prod** webhook endpoint + signing secret rotated
- [ ] NetSuite prod token scoped
- [ ] ForgeObserve / Device Registry prod allowlists include IDMC egress
- [ ] Snowflake prod metrics schema ready
- [ ] Zendesk sample allowlist only (no full history)

### 3.4 Security

- [ ] Secrets scanned—repo clean
- [ ] Okta prod groups assigned
- [ ] Tenant isolation tests executed against prod-like data
- [ ] CISO sign-off on agent deny list

---

## 4. Cutover sequence (recommended maintenance window)

| Step | Action | Owner | Abort if |
| --- | --- | --- | --- |
| 1 | Announce freeze on match-rule edits | CDO | — |
| 2 | Enable Stripe prod webhook (shadow log 30 min) | Integration | Signature failures |
| 3 | Enable golden publish to prod Salesforce | IDMC | Duplicate spike |
| 4 | Enable ForgeObserve + Device events | Product Eng | Isolation test fail |
| 5 | Enable NetSuite CDC | RevOps | Legal name thrash |
| 6 | Certify data products | Steward | DQ critical fails |
| 7 | Enable Agentforce assist for pilot cohort | SF Admin | Policy deny misconfigured |
| 8 | Smoke scenarios 1–3 in prod | QA | Any fail |
| 9 | Open hypercare | Ops | — |

Keep Zendesk and ARR brief at lower risk; enable after CX agents stable if sequencing required.

---

## 5. Immediate post-go-live verification (T+2h)

- [ ] Subscription test (or controlled real) lag P50 &lt;5 min
- [ ] Match rate dashboard populated
- [ ] Zero critical DQ bypasses
- [ ] Agent deny audit on synthetic token probe
- [ ] No Sev-1 pages uncleared
- [ ] Executive sponsor notified of status

---

## 6. Rollback

| Capability | Rollback |
| --- | --- |
| Stripe webhook | Disable endpoint; drain DLQ; revert to manual RevOps reconcile |
| Golden publish | Pause CDI/CAI publish; Salesforce retains last good keys |
| Agentforce | Disable agent / remove permission set; macros remain |
| Device events | Pause CAI; RMA manual |
| MDM match rule | Revert to prior tagged version; reindex suspects |

Decision authority: Enterprise Architect + CTO delegate.

---

## 7. Hypercare (14 days)

| Role | Coverage |
| --- | --- |
| Integration on-call | 24×7 week 1 for Stripe path |
| MDM steward | Business hours + pager for device bind conflicts |
| Salesforce admin | Agentforce config |
| CISO contact | Policy incidents |
| Product Eng | ForgeObserve / Registry |

Daily standup: lag, match %, DQ, agent allow/deny, Sev tickets.

---

## 8. Sign-off

| Role | Name | Date | Signature |
| --- | --- | --- | --- |
| Enterprise Architect | | | |
| CDO | | | |
| CISO | | | |
| VP CX or CRO (pilot owner) | | | |
| Platform Ops | | | |

**Next:** [08-operations-runbook.md](./08-operations-runbook.md)

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
