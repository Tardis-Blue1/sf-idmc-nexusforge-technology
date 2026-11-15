# Branding — Salesforce & Informatica (NexusForge Systems)

This engagement uses **official Salesforce** and **Informatica** (Informatica by Salesforce / IDMC) product naming on all customer-facing artifacts: architecture SVGs, demo UI chrome, and documentation headers.

## Logo assets (licensed)

Official logo binary files are **not** committed to this repository. Place licensed assets here after obtaining them through Salesforce / Informatica brand channels:

| Slot | Target path | Notes |
| --- | --- | --- |
| Salesforce logo | `branding/official/salesforce-logo.svg` (or `.png`) | Prefer SVG; keep clear space per brand guidelines |
| Informatica / IDMC logo | `branding/official/informatica-logo.svg` (or `.png`) | Prefer SVG; use IDMC lockup when specified |

Create the `branding/official/` directory when adding real assets. Do **not** invent unofficial trademark artwork.

## Placeholders (current)

Until licensed files are available, diagrams and the demo UI reference:

- `branding/placeholders/salesforce-logo-placeholder.svg`
- `branding/placeholders/informatica-logo-placeholder.svg`

These are clearly labeled **PLACEHOLDER** text marks (wordmarks in brand-adjacent colors). They are not official logos.

## How to swap placeholders for official logos

1. Obtain licensed Salesforce and Informatica logo files for architecture / presentation use.
2. Copy them into `branding/official/` using the names above (or update paths below).
3. Update SVG corner stamps: replace `<image href="...placeholders/...">` (or the placeholder group) with the official file path, or paste the official SVG markup into the stamp region.
4. Update demo UI chrome in `demo-app/` — search for `placeholders/` and point `src` / CSS background URLs at `branding/official/`.
5. Re-export or re-open SVGs in a viewer to confirm sizing and clear space.
6. Remove or leave placeholders unused; keep this README updated with the chosen paths.

## Naming conventions on artifacts

- Use **Salesforce**, **Sales Cloud**, **Service Cloud**, **Data Cloud**, **Agentforce** as applicable.
- Use **Informatica**, **Informatica Intelligent Data Management Cloud (IDMC)**, and product areas **CDI**, **CAI**, **MDM**, **Data Quality**, **Catalog**, **Governance**.
- Prefer “Informatica by Salesforce” wording where corporate context is needed.

## Disclaimer

NexusForge Systems is a **fictional customer** created for architecture demonstration. Artifacts in this repository are not an endorsement by Salesforce, Informatica, or any named third-party product vendors referenced in integration examples (e.g., Stripe, NetSuite, Zendesk). Official logos must only be used under applicable license and brand guidelines.
