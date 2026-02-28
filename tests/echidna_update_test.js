// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ECHIDNA update module tests — verifies the ECHIDNA sub-updater logic
 * for health checks, prover loading, proof results, UI toggles, and
 * Phase 2 stubs.
 *
 * ReScript variant compilation rules:
 * - Zero-arg variants in mixed types compile to STRINGS (e.g., "CheckHealth")
 * - Payload variants compile to objects (e.g., { TAG: "HealthOk", _0: value })
 * - Model fields use exact ReScript names (proofInput, not proof_input)
 */

import { assertEquals } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";

// Helper: wrap an echidnaMsg inside the unified Echidna variant.
const echidnaMsg = (subMsg) => ({ TAG: "Echidna", _0: subMsg });

Deno.test("ECHIDNA: CheckHealth dispatch leaves model unchanged", () => {
  const model = initModel();
  const msg = echidnaMsg("CheckHealth");
  const [newModel, _cmd] = Update.update(model, msg);

  // CheckHealth issues a command but doesn't change model state.
  assertEquals(newModel.echidna.connected, false);
  assertEquals(newModel.echidna.version, undefined);
});

Deno.test("ECHIDNA: HealthOk sets connected and version", () => {
  const model = initModel();
  const json = '{"status":"ok","version":"0.4.2"}';
  const msg = echidnaMsg({ TAG: "HealthOk", _0: json });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.connected, true);
  assertEquals(newModel.echidna.version, "0.4.2");
  assertEquals(newModel.echidna.proofError, undefined);
});

Deno.test("ECHIDNA: HealthError sets disconnected and error", () => {
  const model = initModel();
  const msg = echidnaMsg({ TAG: "HealthError", _0: "Connection refused" });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.connected, false);
  assertEquals(newModel.echidna.version, undefined);
  assertEquals(newModel.echidna.proofError, "Connection refused");
});

Deno.test("ECHIDNA: ProversLoaded parses prover list", () => {
  const model = initModel();
  const json = '[{"name":"z3","tier":"SMT","complexity":"NP"},{"name":"cvc5","tier":"SMT","complexity":"PSPACE"}]';
  const msg = echidnaMsg({ TAG: "ProversLoaded", _0: { TAG: "Ok", _0: json } });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.provers.length, 2);
  assertEquals(newModel.echidna.provers[0].name, "z3");
  assertEquals(newModel.echidna.provers[0].tier, "SMT");
  assertEquals(newModel.echidna.provers[1].name, "cvc5");
});

Deno.test("ECHIDNA: ProversLoaded handles empty array", () => {
  const model = initModel();
  const msg = echidnaMsg({ TAG: "ProversLoaded", _0: { TAG: "Ok", _0: "[]" } });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.provers.length, 0);
});

Deno.test("ECHIDNA: ProversLoaded handles malformed JSON", () => {
  const model = initModel();
  const msg = echidnaMsg({ TAG: "ProversLoaded", _0: { TAG: "Ok", _0: "not json" } });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.provers.length, 0);
});

Deno.test("ECHIDNA: ProofResult parses dispatch result with trust level", () => {
  const model = initModel();
  const json = JSON.stringify({
    verified: true,
    trust_level: 4,
    provers_used: ["z3", "cvc5"],
    proof_time_ms: 42.5,
    goals_remaining: 0,
    axiom_report: [
      { axiom_name: "funext", danger_level: "noted", description: "Functional extensionality" }
    ],
    certificate_hash: "sha256:abc123",
    message: "All goals discharged",
    cross_checked: "cross_checked",
  });
  const msg = echidnaMsg({ TAG: "ProofResult", _0: { TAG: "Ok", _0: json } });
  const [newModel, _cmd] = Update.update(model, msg);

  const result = newModel.echidna.lastProofResult;
  assertEquals(result.verified, true);
  // TrustLevel4 compiles to "TrustLevel4" (zero-arg in variant type)
  assertEquals(result.trustLevel, "TrustLevel4");
  assertEquals(result.proversUsed.length, 2);
  assertEquals(result.proofTimeMs, 42.5);
  assertEquals(result.goalsRemaining, 0);
  assertEquals(result.axiomReport.length, 1);
  assertEquals(result.axiomReport[0].axiomName, "funext");
  assertEquals(result.certificateHash, "sha256:abc123");
  assertEquals(result.crossChecked, "CrossChecked");
  assertEquals(newModel.echidna.proofLoading, false);
});

Deno.test("ECHIDNA: ToggleMenu flips menuExpanded", () => {
  const model = initModel();
  assertEquals(model.echidna.menuExpanded, false);

  const msg = echidnaMsg("ToggleMenu");
  const [newModel, _cmd] = Update.update(model, msg);
  assertEquals(newModel.echidna.menuExpanded, true);

  const [newModel2, _cmd2] = Update.update(newModel, msg);
  assertEquals(newModel2.echidna.menuExpanded, false);
});

Deno.test("ECHIDNA: UpdateProofInput sets proofInput text", () => {
  const model = initModel();
  const msg = echidnaMsg({ TAG: "UpdateProofInput", _0: "theorem add_comm" });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.proofInput, "theorem add_comm");
});

Deno.test("ECHIDNA: SelectProver sets selectedProver", () => {
  const model = initModel();
  const msg = echidnaMsg({ TAG: "SelectProver", _0: "z3" });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.selectedProver, "z3");
});

Deno.test("ECHIDNA: ClearProofResult resets result and error", () => {
  const model = initModel();
  // Inject a proof result and error into the model
  const withResult = {
    ...model,
    echidna: {
      ...model.echidna,
      lastProofResult: { verified: false, trustLevel: "TrustLevel1" },
      proofError: "Something failed",
    }
  };
  const msg = echidnaMsg("ClearProofResult");
  const [newModel, _cmd] = Update.update(withResult, msg);

  assertEquals(newModel.echidna.lastProofResult, undefined);
  assertEquals(newModel.echidna.proofError, undefined);
});
