# NexusForge Systems — Tests

Executable checks for the Salesforce + Informatica IDMC agentic data platform delivery.

## Layout

| Path | Purpose |
| --- | --- |
| `integration/` | Golden-key upsert idempotency and correlation ID presence (mocked) |
| `acceptance/` | Stepwise acceptance scenarios (integration, MDM, governance deny, RMA) |
| `fixtures/` | Sample JSON from `infra/scripts/seed-sample-data.sh` |

## Run

```bash
# Optional fixtures
../infra/scripts/seed-sample-data.sh

# Integration (pytest)
pip install pytest pyyaml
pytest tests/integration -q

# Acceptance
pytest tests/acceptance -q
# or
./tests/acceptance/run_scenarios.sh
```

No live Salesforce or Informatica credentials are required for the default mock suite.
