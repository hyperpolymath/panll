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

// ===========================================================================
// Phase 2: Interactive Sessions & Tactic Suggestions
// ===========================================================================

Deno.test("ECHIDNA: CreateSession sets sessionLoading=true", () => {
  const model = initModel();
  // Set proof input so session creation has a goal
  const withInput = {
    ...model,
    echidna: { ...model.echidna, proofInput: "forall x, x + 0 = x" },
  };
  const msg = echidnaMsg("CreateSession");
  const [newModel, _cmd] = Update.update(withInput, msg);

  assertEquals(newModel.echidna.sessionLoading, true);
  assertEquals(newModel.echidna.proofError, undefined);
});

Deno.test("ECHIDNA: SessionCreated(Ok) parses session state", () => {
  const model = initModel();
  const json = JSON.stringify({
    id: "sess-abc-123",
    prover: "lean4",
    goal: "forall x, x + 0 = x",
    status: "in_progress",
    goals: ["x + 0 = x", "0 + x = x"],
    proof_script: [],
    complete: false,
    tactics_applied: [],
    time_elapsed: 0.5,
    error_message: null,
  });
  const withLoading = {
    ...model,
    echidna: { ...model.echidna, sessionLoading: true },
  };
  const msg = echidnaMsg({ TAG: "SessionCreated", _0: { TAG: "Ok", _0: json } });
  const [newModel, _cmd] = Update.update(withLoading, msg);

  assertEquals(newModel.echidna.sessionLoading, false);
  assertEquals(newModel.echidna.session.sessionId, "sess-abc-123");
  assertEquals(newModel.echidna.session.prover, "lean4");
  assertEquals(newModel.echidna.session.goals.length, 2);
  assertEquals(newModel.echidna.session.goals[0], "x + 0 = x");
  assertEquals(newModel.echidna.session.status, "InProgress");
  assertEquals(newModel.echidna.session.complete, false);
  assertEquals(newModel.echidna.session.timeElapsed, 0.5);
  assertEquals(newModel.echidna.proofError, undefined);
});

Deno.test("ECHIDNA: SessionCreated(Error) sets proofError and clears sessionLoading", () => {
  const model = initModel();
  const withLoading = {
    ...model,
    echidna: { ...model.echidna, sessionLoading: true },
  };
  const msg = echidnaMsg({
    TAG: "SessionCreated",
    _0: { TAG: "Error", _0: "Prover not available" },
  });
  const [newModel, _cmd] = Update.update(withLoading, msg);

  assertEquals(newModel.echidna.sessionLoading, false);
  assertEquals(newModel.echidna.proofError, "Prover not available");
  assertEquals(newModel.echidna.session, undefined);
});

Deno.test("ECHIDNA: ApplyTactic dispatches without model change", () => {
  const model = initModel();
  const withSession = {
    ...model,
    echidna: {
      ...model.echidna,
      session: {
        sessionId: "sess-xyz",
        prover: "z3",
        goal: "P -> P",
        status: "InProgress",
        goals: ["P -> P"],
        proofScript: [],
        complete: false,
        tacticsApplied: [],
        timeElapsed: 0.0,
        errorMessage: undefined,
      },
    },
  };
  // ApplyTactic has two payload args: name, args
  const msg = echidnaMsg({ TAG: "ApplyTactic", _0: "intro", _1: ["h"] });
  const [newModel, _cmd] = Update.update(withSession, msg);

  // Model unchanged on dispatch — only issues a command
  assertEquals(newModel.echidna.session.sessionId, "sess-xyz");
  assertEquals(newModel.echidna.session.goals.length, 1);
});

Deno.test("ECHIDNA: TacticApplied(Ok) updates session goals and proofScript", () => {
  const model = initModel();
  const withSession = {
    ...model,
    echidna: {
      ...model.echidna,
      session: {
        sessionId: "sess-xyz",
        prover: "z3",
        goal: "P -> P",
        status: "InProgress",
        goals: ["P -> P"],
        proofScript: [],
        complete: false,
        tacticsApplied: [],
        timeElapsed: 0.0,
        errorMessage: undefined,
      },
    },
  };
  const json = JSON.stringify({
    success: true,
    proof_state: {
      id: "sess-xyz",
      prover: "z3",
      goal: "P -> P",
      status: "in_progress",
      goals: ["P"],
      proof_script: ["intro h"],
      complete: false,
      tactics_applied: ["intro h"],
      time_elapsed: 1.2,
      error_message: null,
    },
  });
  const msg = echidnaMsg({ TAG: "TacticApplied", _0: { TAG: "Ok", _0: json } });
  const [newModel, _cmd] = Update.update(withSession, msg);

  assertEquals(newModel.echidna.session.goals.length, 1);
  assertEquals(newModel.echidna.session.goals[0], "P");
  assertEquals(newModel.echidna.session.proofScript.length, 1);
  assertEquals(newModel.echidna.session.proofScript[0], "intro h");
  assertEquals(newModel.echidna.proofError, undefined);
});

Deno.test("ECHIDNA: TacticApplied(Error) sets proofError", () => {
  const model = initModel();
  const withSession = {
    ...model,
    echidna: {
      ...model.echidna,
      session: {
        sessionId: "sess-xyz",
        prover: "z3",
        goal: "P -> P",
        status: "InProgress",
        goals: ["P -> P"],
        proofScript: [],
        complete: false,
        tacticsApplied: [],
        timeElapsed: 0.0,
        errorMessage: undefined,
      },
    },
  };
  const msg = echidnaMsg({
    TAG: "TacticApplied",
    _0: { TAG: "Error", _0: "Tactic failed: no such tactic" },
  });
  const [newModel, _cmd] = Update.update(withSession, msg);

  assertEquals(newModel.echidna.proofError, "Tactic failed: no such tactic");
});

Deno.test("ECHIDNA: GetSessionState dispatches without model change", () => {
  const model = initModel();
  const withSession = {
    ...model,
    echidna: {
      ...model.echidna,
      session: {
        sessionId: "sess-xyz",
        prover: "z3",
        goal: "P -> P",
        status: "InProgress",
        goals: ["P"],
        proofScript: ["intro h"],
        complete: false,
        tacticsApplied: ["intro h"],
        timeElapsed: 1.0,
        errorMessage: undefined,
      },
    },
  };
  const msg = echidnaMsg("GetSessionState");
  const [newModel, _cmd] = Update.update(withSession, msg);

  // No model change on dispatch
  assertEquals(newModel.echidna.session.sessionId, "sess-xyz");
});

Deno.test("ECHIDNA: SessionStateLoaded(Ok) updates session", () => {
  const model = initModel();
  const withSession = {
    ...model,
    echidna: {
      ...model.echidna,
      session: {
        sessionId: "sess-xyz",
        prover: "z3",
        goal: "P -> P",
        status: "InProgress",
        goals: ["P -> P"],
        proofScript: [],
        complete: false,
        tacticsApplied: [],
        timeElapsed: 0.0,
        errorMessage: undefined,
      },
    },
  };
  const json = JSON.stringify({
    id: "sess-xyz",
    prover: "z3",
    goal: "P -> P",
    status: "success",
    goals: [],
    proof_script: ["intro h", "exact h"],
    complete: true,
    tactics_applied: ["intro h", "exact h"],
    time_elapsed: 2.3,
    error_message: null,
  });
  const msg = echidnaMsg({ TAG: "SessionStateLoaded", _0: { TAG: "Ok", _0: json } });
  const [newModel, _cmd] = Update.update(withSession, msg);

  assertEquals(newModel.echidna.session.complete, true);
  assertEquals(newModel.echidna.session.goals.length, 0);
  assertEquals(newModel.echidna.session.proofScript.length, 2);
  assertEquals(newModel.echidna.session.status, "ProofSuccess");
});

Deno.test("ECHIDNA: RequestTacticSuggestions dispatches without model change", () => {
  const model = initModel();
  const withSession = {
    ...model,
    echidna: {
      ...model.echidna,
      session: {
        sessionId: "sess-xyz",
        prover: "z3",
        goal: "P -> P",
        status: "InProgress",
        goals: ["P"],
        proofScript: [],
        complete: false,
        tacticsApplied: [],
        timeElapsed: 0.0,
        errorMessage: undefined,
      },
    },
  };
  const msg = echidnaMsg("RequestTacticSuggestions");
  const [newModel, _cmd] = Update.update(withSession, msg);

  // No model change on dispatch
  assertEquals(newModel.echidna.tacticSuggestions.length, 0);
});

Deno.test("ECHIDNA: TacticSuggestionsLoaded(Ok) populates suggestions with name and confidence", () => {
  const model = initModel();
  const json = JSON.stringify([
    { name: "intro", args: ["x"], description: "Introduce hypothesis", confidence: 0.92, aspect_tags: ["basic"] },
    { name: "apply", args: [], description: "Apply a lemma", confidence: 0.78, aspect_tags: [] },
  ]);
  const msg = echidnaMsg({ TAG: "TacticSuggestionsLoaded", _0: { TAG: "Ok", _0: json } });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.tacticSuggestions.length, 2);
  assertEquals(newModel.echidna.tacticSuggestions[0].tactic, "intro");
  assertEquals(newModel.echidna.tacticSuggestions[0].confidence, 0.92);
  assertEquals(newModel.echidna.tacticSuggestions[0].args.length, 1);
  assertEquals(newModel.echidna.tacticSuggestions[0].args[0], "x");
  assertEquals(newModel.echidna.tacticSuggestions[1].tactic, "apply");
  assertEquals(newModel.echidna.tacticSuggestions[1].confidence, 0.78);
});

Deno.test("ECHIDNA: TacticSuggestionsLoaded(Error) clears suggestions", () => {
  const model = initModel();
  const withSuggestions = {
    ...model,
    echidna: {
      ...model.echidna,
      tacticSuggestions: [{ tactic: "old", args: [], confidence: 0.5, aspectTags: [], description: "" }],
    },
  };
  const msg = echidnaMsg({
    TAG: "TacticSuggestionsLoaded",
    _0: { TAG: "Error", _0: "ML advisor unavailable" },
  });
  const [newModel, _cmd] = Update.update(withSuggestions, msg);

  assertEquals(newModel.echidna.tacticSuggestions.length, 0);
});

Deno.test("ECHIDNA: CancelSession clears session state", () => {
  const model = initModel();
  const withSession = {
    ...model,
    echidna: {
      ...model.echidna,
      session: {
        sessionId: "sess-xyz",
        prover: "z3",
        goal: "P -> P",
        status: "InProgress",
        goals: ["P"],
        proofScript: ["intro h"],
        complete: false,
        tacticsApplied: ["intro h"],
        timeElapsed: 1.0,
        errorMessage: undefined,
      },
      tacticSuggestions: [{ tactic: "exact", args: ["h"], confidence: 0.95, aspectTags: [], description: "" }],
      tacticInput: "some tactic",
      sessionLoading: true,
    },
  };
  const msg = echidnaMsg("CancelSession");
  const [newModel, _cmd] = Update.update(withSession, msg);

  assertEquals(newModel.echidna.session, undefined);
  assertEquals(newModel.echidna.tacticSuggestions.length, 0);
  assertEquals(newModel.echidna.tacticInput, "");
  assertEquals(newModel.echidna.sessionLoading, false);
  assertEquals(newModel.echidna.proofError, undefined);
});

Deno.test("ECHIDNA: UpdateTacticInput sets tacticInput text", () => {
  const model = initModel();
  const msg = echidnaMsg({ TAG: "UpdateTacticInput", _0: "intro x" });
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.echidna.tacticInput, "intro x");
});
