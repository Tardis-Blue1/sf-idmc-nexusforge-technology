"""Integration tests: CAI process defs require correlation ID wiring."""
from __future__ import annotations

from pathlib import Path
import re

import yaml

CAI_DIR = Path(__file__).resolve().parents[2] / "idmc" / "cai"


def _load(name: str) -> dict:
    # Strip comment-only preamble friendliness: PyYAML handles # comments
    return yaml.safe_load((CAI_DIR / name).read_text())


def test_all_cai_processes_define_correlation():
    files = sorted(CAI_DIR.glob("*.yaml"))
    assert files, "expected CAI YAML process defs"
    for path in files:
        doc = _load(path.name)
        assert doc["kind"] == "CAIProcess"
        corr = doc["spec"]["correlation"]
        assert "header" in corr
        assert corr["header"] == "X-NexusForge-Correlation-Id"


def test_agent_writeback_requires_correlation_header():
    doc = _load("agent-writeback-api.yaml")
    assert doc["spec"]["correlation"]["required"] is True
    steps = {s["id"]: s for s in doc["spec"]["steps"]}
    assert steps["validate_correlation"]["on_missing"] == "reject_400"


def test_stripe_sync_propagates_correlation():
    doc = _load("stripe-subscription-sync.yaml")
    targets = doc["spec"]["correlation"]["propagate_to"]
    assert "salesforce" in targets
    assert "mdm" in targets
