# NexusForge demo app

Thin static UI for the **NexusForge Systems** engagement: **Agentic Customer & Product Data Platform** on **Salesforce** (Sales Cloud, Service Cloud, Data Cloud, Agentforce) and **Informatica IDMC** (integration, MDM, DQ, Catalog, Governance).

## What it shows

- **Account 360** for a golden MDM Account (Northwind Robotics Holdings — sample)
- Subscription / entitlements / ForgeEdge devices
- IDMC Catalog data products (agent-readable vs denied)
- **Agentforce action simulator** with:
  - Governance **DENY** on raw Stripe billing token
  - Fallback to certified `billing_status`
  - Device **RMA** blocked while DQ quarantine is active, then allowed after steward release
  - Cross-Account rebind requiring human-in-the-loop
  - Audit trail with correlation IDs

## Quickstart

From this directory (`demo-app/`):

```bash
# Option A — npx serve (Node 18+)
npm start
# → http://localhost:4173

# Option B — Python
python3 -m http.server 4173
# → http://localhost:4173
```

Open `http://localhost:4173/` (serves `index.html`). Do not open the HTML file via `file://` — `fetch` of JSON requires HTTP.

## Layout

- `index.html` — Account 360 + agent simulator
- `package.json` — npm start / serve / python scripts
- `README.md`
- `public/index.html` — redirect note to `../index.html`
- `src/app.js`
- `src/styles/main.css`
- `src/data/account-360.json`
- `src/data/agent-scenarios.json`

## Branding

Header chrome uses labeled **Salesforce** and **Informatica / IDMC** placeholder marks (not official logo binaries). Swap licensed assets per `/branding/README.md`.

## Disclaimer

NexusForge Systems is a fictional customer for architecture demonstration. Not an endorsement by Salesforce, Informatica, or named third-party integration vendors.
