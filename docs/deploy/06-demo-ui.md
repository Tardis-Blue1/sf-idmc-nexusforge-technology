# Deploy 06 — Demo UI

**Solutions:** Salesforce · Informatica Intelligent Data Management Cloud (IDMC) — Informatica by Salesforce · thin NexusForge demo application exercising Account 360 and Agentforce action simulation against governed APIs

| Field | Value |
| --- | --- |
| Customer | NexusForge Systems, Inc. (fictional) |
| Document | Deploy 06 — Demo UI |
| Version | 1.0 |
| Depends on | [05-data-cloud-agentforce.md](./05-data-cloud-agentforce.md) |
| Code | `demo-app/` |

---

## 1. Purpose

Run the thin demo UI that proves trusted data paths for executives and UAT: Account 360 (golden customer, entitlements, devices), agent action simulator (including policy deny and DQ quarantine), and buy-vs-build lineage/match-rate panels. The UI is **not** a production CX portal; it is a delivery artifact for the architecture engagement.

---

## 2. Features to verify

| Screen | Demonstrates |
| --- | --- |
| Account 360 | `dp.customer.golden` + hierarchy |
| Entitlements panel | `dp.entitlement.active`; billing_status; no tokens |
| Device fleet | `dp.device.fleet`; quarantine badge |
| Agent simulator | Tool calls with correlation ID; allow/deny |
| Trust metrics | Match rate, DQ fail, lineage snippet (scenario 5) |
| Branding chrome | Salesforce + Informatica labeling |

---

## 3. Configuration

1. Copy env template:
   ```bash
   cp demo-app/.env.example demo-app/.env.local
   ```
2. Set:
   - `CAI_BASE_URL` — Named Credential equivalent for local
   - `CAI_CLIENT_ID` / secret via env (not committed)
   - `SF_INSTANCE_URL` optional for deep links
   - `DEMO_MODE=sandbox`
3. Ensure Payment-restricted fields are never requested by UI code paths except the explicit “deny demo” button used in acceptance scenario 3.

---

## 4. Install and run (non-prod)

```bash
cd demo-app
npm install
npm run dev -- --host 127.0.0.1 --port 5173
```

Or static preview after build:

```bash
npm run build
npm run preview -- --host 127.0.0.1 --port 5173
```

Restrict access via VPN / IP allowlist. Do not expose to public internet.

---

## 5. Wiring checklist

- [ ] Account search by golden ID and name returns hierarchy
- [ ] Entitlement tier updates after Stripe test upgrade (within SLA)
- [ ] Device list shows DQ_Status; quarantined device disables “Open RMA”
- [ ] Agent simulator “Request raw billing token” → denied with audit ID displayed
- [ ] Agent simulator “Propose RMA” on certified device → draft ID
- [ ] Match rate / lineage panel loads metrics from Snowflake or mocked certified API
- [ ] Header/footer show Salesforce + Informatica + fictional disclaimer

---

## 6. Sample demo script (15 minutes)

1. Open enterprise Account with PLG duplicate history → show golden merge.  
2. Trigger Stripe upgrade in test → watch entitlement refresh.  
3. Open device in quarantine → show agent escalate path.  
4. Fire token deny.  
5. Show match-rate / lineage vs “DIY pipeline would not include this.”  
6. Optional: jump to Salesforce Case/Account deep link.

---

## 7. Troubleshooting

| Symptom | Check |
| --- | --- |
| Empty Account 360 | CAI auth; golden publish job |
| Stale entitlement | Stripe CAI lag dashboard |
| RMA enabled on quarantine | CAI filter bug—block demo; fix DQ gate |
| CORS errors | Remote site / CAI CORS for demo origin |
| Missing branding | Official marks under `branding/logos/` per README |

---

## 8. Exit checklist

- [ ] Demo UI runs against non-prod CAI
- [ ] All five acceptance scenarios can be driven from UI + Salesforce as documented
- [ ] Secrets absent from repo and browser bundles
- [ ] Disclaimer visible on every page footer
- [ ] Champions trained on demo script

**Next:** [07-go-live-checklist.md](./07-go-live-checklist.md)

---

*Disclaimer: NexusForge Systems is a fictional customer created for Salesforce and Informatica (Informatica by Salesforce / IDMC) architecture demonstration purposes. This material is not an endorsement by, or affiliation with, any named third-party company.*
