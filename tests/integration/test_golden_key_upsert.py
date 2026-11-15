"""Integration tests: golden-key upsert idempotency (mocked Salesforce/MDM behavior)."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, Optional
import uuid


@dataclass
class UpsertResult:
    record_id: str
    created: bool
    golden_key: str
    correlation_id: str


@dataclass
class MockMDMKeyService:
    """Mirrors NexusForgeMDMKeyService idempotent golden-key logic."""

    accounts: Dict[str, dict] = field(default_factory=dict)
    devices: Dict[str, dict] = field(default_factory=dict)

    def upsert_account(
        self,
        golden_key: str,
        name: str,
        forge_org: Optional[str] = None,
        correlation_id: Optional[str] = None,
    ) -> UpsertResult:
        cid = correlation_id or f"nf-{uuid.uuid4()}"
        existing = None
        if golden_key in self.accounts:
            existing = self.accounts[golden_key]
        else:
            for row in self.accounts.values():
                if forge_org and row.get("forge_org") == forge_org:
                    existing = row
                    break
        if existing:
            existing["name"] = name or existing["name"]
            existing["forge_org"] = forge_org or existing.get("forge_org")
            return UpsertResult(existing["id"], False, existing["golden_key"], cid)
        rid = f"001{len(self.accounts)+1:03d}"
        row = {"id": rid, "golden_key": golden_key, "name": name, "forge_org": forge_org}
        self.accounts[golden_key] = row
        return UpsertResult(rid, True, golden_key, cid)

    def upsert_device(
        self,
        golden_key: str,
        serial: str,
        correlation_id: Optional[str] = None,
    ) -> UpsertResult:
        cid = correlation_id or f"nf-{uuid.uuid4()}"
        existing = self.devices.get(golden_key)
        if not existing:
            for row in self.devices.values():
                if row["serial"] == serial:
                    existing = row
                    break
        if existing:
            existing["serial"] = serial
            if golden_key and not existing.get("golden_key"):
                existing["golden_key"] = golden_key
            return UpsertResult(existing["id"], False, existing["golden_key"], cid)
        rid = f"a01{len(self.devices)+1:03d}"
        row = {"id": rid, "golden_key": golden_key, "serial": serial}
        self.devices[golden_key] = row
        return UpsertResult(rid, True, golden_key, cid)


def test_account_upsert_idempotent_by_golden_key():
    svc = MockMDMKeyService()
    r1 = svc.upsert_account("GAK-1", "Acme", "org_1", "cid-1")
    r2 = svc.upsert_account("GAK-1", "Acme Updated", "org_1", "cid-2")
    assert r1.created is True
    assert r2.created is False
    assert r1.record_id == r2.record_id
    assert len(svc.accounts) == 1


def test_account_upsert_idempotent_by_forge_org_when_key_added():
    svc = MockMDMKeyService()
    r1 = svc.upsert_account("GAK-TMP", "Acme", "org_1")
    # Second call same forge org + same golden key stays single row
    r2 = svc.upsert_account("GAK-TMP", "Acme", "org_1")
    assert r1.record_id == r2.record_id
    assert r2.created is False


def test_device_upsert_idempotent_by_serial():
    svc = MockMDMKeyService()
    r1 = svc.upsert_device("GDK-1", "FE-1", "cid-a")
    r2 = svc.upsert_device("GDK-1", "FE-1", "cid-b")
    assert r1.created and not r2.created
    assert r1.record_id == r2.record_id


def test_correlation_id_present_on_upsert():
    svc = MockMDMKeyService()
    r = svc.upsert_account("GAK-2", "Beta", correlation_id="nf-corr-fixed")
    assert r.correlation_id == "nf-corr-fixed"
    r2 = svc.upsert_device("GDK-2", "FE-2")
    assert r2.correlation_id.startswith("nf-")
