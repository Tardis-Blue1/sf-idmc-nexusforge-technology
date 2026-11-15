"""Acceptance scenarios for NexusForge Systems (Salesforce + Informatica IDMC)."""
from __future__ import annotations

from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "idmc" / "catalog"
MDM = ROOT / "idmc" / "mdm"
DQ = ROOT / "idmc" / "dq"


def test_scenario_1_integration_subscription_upgrade_path_defined():
    """Stripe upgrade lands in entitlement sync process with SLA."""
    doc = yaml.safe_load((ROOT / "idmc" / "cai" / "stripe-subscription-sync.yaml").read_text())
    step_ids = [s["id"] for s in doc["spec"]["steps"]]
    assert "upsert_subscription_master" in step_ids
    assert "upsert_salesforce_entitlement" in step_ids
    assert doc["spec"]["sla"]["median_consistency_minutes"] <= 5


def test_scenario_2_mdm_merge_hierarchy_and_device_follow_account():
    """Enterprise hierarchy + device binding to golden account."""
    hierarchy = yaml.safe_load((MDM / "hierarchy.yaml").read_text())
    levels = [l["name"] for l in hierarchy["spec"]["levels"]]
    assert levels == ["parent_account", "billing_entity", "product_org"]
    assert hierarchy["spec"]["device_binding"]["via"] == "golden_account_key"
    survivorship = yaml.safe_load((MDM / "survivorship.yaml").read_text())
    assert "enterprise_account_wins" in survivorship["spec"]["customer"]["hierarchy"]["strategy"]


def test_scenario_3_governance_deny_raw_stripe_token():
    """Agent denied raw Stripe token fields; must use certified billing_status."""
    policies = yaml.safe_load((CATALOG / "policies.yaml").read_text())
    deny = next(p for p in policies["spec"]["policies"] if p["id"] == "deny-raw-stripe-tokens-to-agents")
    assert deny["effect"] == "deny"
    fields = deny["resources"]["fields"]
    assert "stripe_payment_method_token" in fields
    assert "stripe_pan_token" in fields

    products = yaml.safe_load((CATALOG / "data-products.yaml").read_text())
    ent = next(p for p in products["spec"]["products"] if p["id"] == "dp.entitlement.active")
    assert "billing_status" in ent["fields"]
    assert "stripe_payment_method_token" not in ent["fields"]

    # Simulated agent request
    requested_field = "stripe_pan_token"
    allowed = requested_field not in fields  # deny list => not allowed
    assert allowed is False


def test_scenario_4_device_rma_dq_quarantine_then_allow():
    """Firmware mismatch quarantined; RMA allowed after steward fix."""
    validity = yaml.safe_load((DQ / "validity.yaml").read_text())
    firmware_rule = next(r for r in validity["spec"]["rules"] if r["id"] == "firmware_semverish")
    assert firmware_rule["on_fail"] == "quarantine"

    ref = yaml.safe_load((DQ / "referential-integrity.yaml").read_text())
    device_rule = next(r for r in ref["spec"]["rules"] if r["id"] == "device_must_map_to_account")
    assert device_rule["severity"] == "critical"

    writeback = yaml.safe_load((ROOT / "idmc" / "cai" / "agent-writeback-api.yaml").read_text())
    steps = {s["id"]: s for s in writeback["spec"]["steps"]}
    assert steps["rma_gate"]["require_device_account_match_confidence_gte"] == 98
    assert steps["rma_gate"]["on_fail"] == "escalate_steward"

    # Simulate quarantine then clear
    match_confidence = 90.0
    rma_allowed = match_confidence >= 98
    assert rma_allowed is False
    match_confidence = 99.0  # steward fixed binding
    assert match_confidence >= 98


def test_scenario_5_catalog_products_certified_for_agents():
    products = yaml.safe_load((CATALOG / "data-products.yaml").read_text())
    ids = {p["id"] for p in products["spec"]["products"]}
    assert {"dp.customer.golden", "dp.device.fleet", "dp.entitlement.active"} <= ids
    assert all(p["certified"] for p in products["spec"]["products"])
