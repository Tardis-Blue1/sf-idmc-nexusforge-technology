/**
 * NexusForge Systems — Agentic Customer & Product Data Platform demo
 * Salesforce Account 360 + Agentforce action simulator with IDMC governance.
 */
(function () {
  "use strict";

  const state = {
    account: null,
    scenarios: null,
    selectedScenarioId: null,
    dqReleased: false,
    audit: [],
  };

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  async function loadData() {
    const [account, scenarios] = await Promise.all([
      fetch("./src/data/account-360.json").then((r) => r.json()),
      fetch("./src/data/agent-scenarios.json").then((r) => r.json()),
    ]);
    state.account = account;
    state.scenarios = scenarios;
  }

  function money(n) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      maximumFractionDigits: 0,
    }).format(n);
  }

  function badge(status) {
    const map = {
      Active: "ok",
      Certified: "ok",
      Current: "ok",
      Healthy: "ok",
      Quarantined: "deny",
      Degraded: "warn",
      Medium: "warn",
    };
    const kind = map[status] || "info";
    return `<span class="badge badge--${kind}">${status}</span>`;
  }

  function renderAccount() {
    const a = state.account.account;
    const root = $("#account-panel");
    root.innerHTML = `
      <p class="eyebrow">Salesforce · Account 360 · MDM golden key</p>
      <h2>${a.name}</h2>
      <p style="margin:0;color:var(--muted);font-size:0.9rem">
        ${a.type} · ${a.industry} · ${a.region}<br/>
        Golden key <code style="font-family:var(--font-mono);font-size:0.8rem">${a.goldenKey}</code>
        · SF <code style="font-family:var(--font-mono);font-size:0.8rem">${a.salesforceId}</code>
      </p>
      <div class="hierarchy" aria-label="Account hierarchy">
        <span class="node">${a.hierarchy.parent}</span>
        <span class="arrow">→</span>
        <span class="node">${a.hierarchy.billingEntity}</span>
        <span class="arrow">→</span>
        <span class="node">${a.hierarchy.productOrg}</span>
      </div>
      <dl class="meta-grid">
        <div class="meta"><dt>ARR</dt><dd>${money(a.arr)}</dd></div>
        <div class="meta"><dt>Health score</dt><dd>${a.healthScore}</dd></div>
        <div class="meta"><dt>Entitlement risk</dt><dd>${a.entitlementRisk}</dd></div>
        <div class="meta"><dt>Billing status</dt><dd>${a.billingStatus} <span class="badge badge--ok">certified</span></dd></div>
        <div class="meta"><dt>CSM</dt><dd>${a.csm}</dd></div>
        <div class="meta"><dt>AE</dt><dd>${a.ae}</dd></div>
      </dl>
    `;

    const sub = state.account.subscription;
    $("#subscription-panel").innerHTML = `
      <h3>Subscription · ForgeObserve</h3>
      <table class="table">
        <tbody>
          <tr><th>Product</th><td>${sub.product}</td></tr>
          <tr><th>Tier</th><td><strong>${sub.tier}</strong> <span class="badge badge--teal">upgraded from ${sub.previousTier}</span></td></tr>
          <tr><th>Seats</th><td>${sub.seats}</td></tr>
          <tr><th>Renewal</th><td>${sub.renewalDate}</td></tr>
          <tr><th>Stripe sub (ref)</th><td><code>${sub.stripeSubscriptionId}</code></td></tr>
          <tr><th>Flags</th><td>${sub.featureFlags.map((f) => `<span class="badge badge--info">${f}</span>`).join(" ")}</td></tr>
        </tbody>
      </table>
      <p style="margin:0.75rem 0 0;font-size:0.8rem;color:var(--muted)">
        MDM merge: ${state.account.account.mergedFrom.map((m) => m.source).join(" + ")} → golden Account.
      </p>
    `;

    $("#entitlements-panel").innerHTML = `
      <h3>Entitlements · dp.entitlement.active</h3>
      <table class="table">
        <thead><tr><th>ID</th><th>Name</th><th>Qty</th><th>Status</th></tr></thead>
        <tbody>
          ${state.account.entitlements
            .map(
              (e) => `<tr>
              <td>${e.id}</td>
              <td>${e.name}<br/><span class="badge badge--teal">${e.source}</span></td>
              <td>${e.quantity}</td>
              <td>${badge(e.status)}</td>
            </tr>`
            )
            .join("")}
        </tbody>
      </table>
    `;

    renderDevices();
    renderProducts();
  }

  function renderDevices() {
    const devices = state.account.devices.map((d) => {
      const dq =
        d.serial === "FE-AUS-77821" && state.dqReleased
          ? { ...d, dqStatus: "Certified", dqReason: null, health: "Healthy", firmware: "3.5.0" }
          : d;
      return dq;
    });

    $("#devices-panel").innerHTML = `
      <h3>Devices · ForgeEdge fleet · dp.device.fleet</h3>
      <table class="table">
        <thead>
          <tr><th>Serial</th><th>Model</th><th>Firmware</th><th>Health</th><th>DQ</th><th>Match</th></tr>
        </thead>
        <tbody>
          ${devices
            .map(
              (d) => `<tr>
              <td><code>${d.serial}</code></td>
              <td>${d.model}</td>
              <td>${d.firmware}</td>
              <td>${badge(d.health)}</td>
              <td>${badge(d.dqStatus)}${d.dqReason ? `<br/><span style="font-size:0.72rem;color:var(--muted)">${d.dqReason}</span>` : ""}</td>
              <td>${(d.matchConfidence * 100).toFixed(1)}%</td>
            </tr>`
            )
            .join("")}
        </tbody>
      </table>
      <p style="margin:0.75rem 0 0;font-size:0.8rem;color:var(--muted)">
        IDMC DQ gate: quarantined devices block Agentforce RMA write until steward release.
        ${state.dqReleased ? '<span class="badge badge--ok">Steward released FE-AUS-77821</span>' : ""}
      </p>
    `;
  }

  function renderProducts() {
    $("#products-panel").innerHTML = `
      <h3>Informatica IDMC · Catalog data products</h3>
      <table class="table">
        <thead><tr><th>Product</th><th>Owner</th><th>Sensitivity</th><th>Agent</th></tr></thead>
        <tbody>
          ${state.account.dataProducts
            .map(
              (p) => `<tr>
              <td><code>${p.id}</code></td>
              <td>${p.owner}</td>
              <td>${p.sensitivity}</td>
              <td>${p.agentReadable ? badge("Active") : '<span class="badge badge--deny">DENY</span>'}</td>
            </tr>`
            )
            .join("")}
        </tbody>
      </table>
    `;
  }

  function renderScenarioList() {
    const list = $("#scenario-list");
    list.innerHTML = state.scenarios.scenarios
      .map(
        (s) => `<li>
        <button type="button" class="scenario-btn${state.selectedScenarioId === s.id ? " is-active" : ""}" data-id="${s.id}">
          <strong>${s.label}</strong>
          <span>${s.description}</span>
        </button>
      </li>`
      )
      .join("");

    $$(".scenario-btn", list).forEach((btn) => {
      btn.addEventListener("click", () => {
        state.selectedScenarioId = btn.dataset.id;
        renderScenarioList();
        $("#run-btn").disabled = false;
        $("#result-panel").className = "result-panel";
        $("#result-panel").innerHTML = `<p style="margin:0;color:var(--muted)">Selected: <strong>${btn.querySelector("strong").textContent}</strong>. Click Run agent action.</p>`;
      });
    });
  }

  function correlationId() {
    return `corr-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  }

  function pushAudit(entry) {
    state.audit.unshift(entry);
    const ul = $("#audit-log");
    ul.innerHTML = state.audit
      .slice(0, 12)
      .map((e) => `<li>[${e.ts}] <strong>${e.decision}</strong> · ${e.detail}</li>`)
      .join("");
  }

  function evaluateScenario(scenario) {
    const corr = correlationId();
    const ts = new Date().toISOString();

    if (scenario.id === "read-raw-billing-token") {
      return {
        decision: "DENY",
        className: "is-deny",
        title: "Governance DENY — raw billing token",
        body: `Policy POL-AGENT-NO-RAW-TOKEN blocked field ${scenario.field} on ${scenario.dataProduct}.`,
        detail: {
          action: scenario.action,
          field: scenario.field,
          policy: "POL-AGENT-NO-RAW-TOKEN",
          effect: "deny",
          fallback: scenario.fallback,
          certifiedAlternative: {
            product: "dp.billing.status",
            billing_status: state.account.account.billingStatus,
            renewal_date: state.account.subscription.renewalDate,
          },
          correlationId: corr,
          lineage: "Stripe → IDMC CDI → Catalog policy → Agentforce tool (blocked)",
        },
        audit: { ts, decision: "DENY", detail: `raw token · ${corr}` },
      };
    }

    if (scenario.id === "open-rma-quarantined" && !state.dqReleased) {
      return {
        decision: "ESCALATE",
        className: "is-escalate",
        title: "DQ gate — escalate to steward",
        body: `Device ${scenario.serial} is Quarantined. Agentforce cannot open RMA until IDMC DQ release.`,
        detail: {
          action: scenario.action,
          serial: scenario.serial,
          policy: "POL-DQ-GATE",
          effect: "deny_until_certified",
          hitlRequired: true,
          correlationId: corr,
        },
        audit: { ts, decision: "ESCALATE", detail: `RMA blocked DQ · ${scenario.serial} · ${corr}` },
        offerRelease: true,
      };
    }

    if (scenario.id === "open-rma-certified" || (scenario.id === "open-rma-quarantined" && state.dqReleased)) {
      if (!state.dqReleased && scenario.assumeDqReleased) {
        state.dqReleased = true;
        renderDevices();
      }
      return {
        decision: "ALLOW",
        className: "is-allow",
        title: "RMA allowed via governed CAI",
        body: `Proactive RMA opened for ${scenario.serial} on golden Account ${state.account.account.goldenKey}.`,
        detail: {
          action: "open_rma",
          serial: scenario.serial,
          accountGoldenKey: state.account.account.goldenKey,
          entitlement: "ENT-1003 Premium RMA — next-business-day",
          writeBack: "IDMC CAI → Device Registry + Service Cloud Case",
          correlationId: corr,
          lineage: "Device Registry → CDI → DQ certify → MDM → Data Cloud → Agentforce → CAI write",
        },
        audit: { ts, decision: "ALLOW", detail: `RMA ${scenario.serial} · ${corr}` },
      };
    }

    if (scenario.id === "cross-account-rebind") {
      return {
        decision: "HITL",
        className: "is-hitl",
        title: "Human-in-the-loop required",
        body: `Cross-Account rebind of ${scenario.serial} to ${scenario.targetAccount} blocked pending steward approval.`,
        detail: {
          action: scenario.action,
          policy: "POL-CROSS-ACCT-HITL",
          effect: "require_hitl",
          currentAccount: state.account.account.goldenKey,
          targetAccount: scenario.targetAccount,
          correlationId: corr,
          note: "Wrong-Account rebind is a security and revenue incident if autonomous.",
        },
        audit: { ts, decision: "HITL", detail: `rebind blocked · ${corr}` },
      };
    }

    // Default allow paths (renewal brief, entitlement triage)
    return {
      decision: "ALLOW",
      className: "is-allow",
      title: "Action allowed — certified products",
      body: scenario.description,
      detail: {
        action: scenario.action,
        requires: scenario.requires || [],
        grounding: "Data Cloud unified profile + IDMC certified products",
        account: state.account.account.goldenKey,
        billing_status: state.account.account.billingStatus,
        tier: state.account.subscription.tier,
        correlationId: corr,
      },
      audit: { ts, decision: "ALLOW", detail: `${scenario.action} · ${corr}` },
    };
  }

  function runSelected() {
    const scenario = state.scenarios.scenarios.find((s) => s.id === state.selectedScenarioId);
    if (!scenario) return;

    const result = evaluateScenario(scenario);
    const panel = $("#result-panel");
    panel.className = `result-panel ${result.className}`;
    panel.innerHTML = `
      <p class="eyebrow">Agentforce · Informatica IDMC policy runtime</p>
      <h4>${result.title}</h4>
      <p style="margin:0 0 0.5rem">${result.body}</p>
      <span class="badge badge--${result.decision === "ALLOW" ? "ok" : result.decision === "DENY" ? "deny" : "warn"}">${result.decision}</span>
      <pre>${JSON.stringify(result.detail, null, 2)}</pre>
      ${
        result.offerRelease
          ? `<button type="button" class="run-btn" id="release-btn" style="background:var(--inf-teal)">Simulate steward DQ release</button>`
          : ""
      }
    `;
    pushAudit(result.audit);

    const releaseBtn = $("#release-btn");
    if (releaseBtn) {
      releaseBtn.addEventListener("click", () => {
        state.dqReleased = true;
        renderDevices();
        pushAudit({
          ts: new Date().toISOString(),
          decision: "STEWARD",
          detail: "DQ release FE-AUS-77821 · firmware certified 3.5.0",
        });
        state.selectedScenarioId = "open-rma-certified";
        renderScenarioList();
        runSelected();
      });
    }
  }

  async function init() {
    try {
      await loadData();
      renderAccount();
      renderScenarioList();
      $("#run-btn").addEventListener("click", runSelected);
      $("#result-panel").innerHTML =
        '<p style="margin:0;color:var(--muted)">Select a scenario, then run the Agentforce action to see Salesforce + Informatica IDMC governance decisions.</p>';
    } catch (err) {
      console.error(err);
      $("#account-panel").innerHTML = `<p style="color:var(--deny)">Failed to load demo data. Serve the demo-app directory over HTTP (see README).</p><pre>${String(err)}</pre>`;
    }
  }

  document.addEventListener("DOMContentLoaded", init);
})();
