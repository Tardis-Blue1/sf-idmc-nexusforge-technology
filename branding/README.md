# Branding — Salesforce & Informatica (NexusForge Systems)

This engagement uses **official Salesforce** and **Informatica** (Informatica from Salesforce / IDMC) product naming and logo marks on customer-facing artifacts: architecture SVGs, demo UI chrome, and documentation headers.

## Official logo assets

Licensed / Brand Central marks live in **[`branding/logos/`](logos/)**:

| Slot | Path | Notes |
| --- | --- | --- |
| Salesforce Cloud (primary) | `branding/logos/salesforce-cloud-logo.svg` (+ PNG) | Default mark |
| Salesforce Horizontal | `branding/logos/salesforce-horizontal-logo.svg` (+ normalized PNG) | Tight / wide layouts |
| Informatica | `branding/logos/informatica-logo.svg` (+ normalized PNG) | Corporate mark |
| Informatica from Salesforce | `branding/logos/informatica-from-salesforce-logo.svg` (+ PNG/JPG) | Official relationship lockup |

Source URLs, retrieval date, and usage notes: [`branding/logos/README.md`](logos/README.md) and [`branding/logos/SOURCES.md`](logos/SOURCES.md).

Do **not** invent unofficial trademark artwork. Prefer SVG; use `*-normalized.png` when a raster is required.

## Deprecated placeholders

Older text-mark placeholders remain under `branding/placeholders/` for history only. New work must reference `branding/logos/`.

## Diagram & demo wiring

1. Architecture SVG corner stamps use `<image href="../../branding/logos/...">` (Cloud + Informatica from Salesforce lockup).
2. Demo UI chrome in `demo-app/` loads PNGs from `../branding/logos/`.
3. README header embeds normalized PNGs from `branding/logos/`.

## Naming conventions on artifacts

- Use **Salesforce**, **Sales Cloud**, **Service Cloud**, **Data Cloud**, **Agentforce** as applicable.
- Use **Informatica**, **Informatica Intelligent Data Management Cloud (IDMC)**, and product areas **CDI**, **CAI**, **MDM**, **Data Quality**, **Catalog**, **Governance**.
- Prefer **“Informatica from Salesforce”** wording where corporate context is needed (matches the official lockup).

## Disclaimer

NexusForge Systems is a **fictional customer** created for architecture demonstration. Artifacts in this repository are not an endorsement by Salesforce, Informatica, or any named third-party product vendors referenced in integration examples (e.g., Stripe, NetSuite, Zendesk). Official logos must only be used under applicable license and brand guidelines.
