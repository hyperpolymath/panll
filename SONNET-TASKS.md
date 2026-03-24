# SONNET-TASKS.md — PanLL Completion Tasks

> **Generated:** 2026-02-12 by Opus audit
> **Purpose:** Unambiguous instructions for Sonnet to complete all stubs, TODOs, and placeholder code.
> **Honest completion before this file:** ~72%

The project claims 95% completion (README.adoc, ROADMAP.adoc) and STATE.scm claims 100% for v0.1.0.
Reality: the frontend ReScript compiles and 36 Deno tests pass, but three Tauri backend
commands are stub/placeholder implementations, two core modules (OrbitalSync, Contractiles)
are fully coded but never wired into the update loop, AntiCrash validation is placeholder
pattern-matching instead of real symbolic checking, the Tea_Render module does full
re-render on every update instead of VDOM diffing, no ARIA accessibility exists anywhere,
the `rescript.json` uses a deprecated module format, the Subscriptions.res file (unused)
has a NoOp placeholder animation frame, duplicate keyboard subscription modules exist
(Keyboard.res vs KeyboardFixed.res and Subscriptions.res vs SubscriptionsFixed.res),
and test coverage only reaches TEA internals plus panic-attacker parsing -- zero tests
exist for Model, Msg, Update, View, Storage round-trip edge cases, AntiCrash, Contractiles,
or OrbitalSync.

---

## GROUND RULES FOR SONNET

1. Read this entire file before starting any task.
2. Do tasks in order listed. Earlier tasks unblock later ones.
3. After each task, run the verification command. If it fails, fix before moving on.
4. Do NOT mark done unless verification passes.
5. Update STATE.scm with honest completion percentages after each task.
6. Commit after each task: `fix(component): complete <description>`
7. Run tests after every 3 tasks.

---

## TASK 1: Fix deprecated ReScript module config (P0 - BLOCKING)

**Files:** `./rescript.json`

**Problem:** Line 11 uses `"module": "es6"` which is deprecated and produces a build
warning on every compile. The correct value is `"module": "esmodule"`.

**What to do:**
1. Open `rescript.json`.
2. On line 11, change `"module": "es6"` to `"module": "esmodule"`.
3. Run `node_modules/rescript/rescript clean` then `node_modules/rescript/rescript build`.
4. Confirm the deprecation warning is gone.

**Verification:**
```bash
cd .
node_modules/rescript/rescript clean && node_modules/rescript/rescript build 2>&1 | grep -c "es6"
# Expected output: 0 (no mentions of es6 deprecation warning)
```

---

## TASK 2: Remove duplicate subscription files (P1 - CODE HYGIENE)

**Files:**
- `./src/Subscriptions.res` (UNUSED - uses old `Keyboard` module)
- `./src/subscriptions/Keyboard.res` (UNUSED - parameter named `enabler` vs `dispatch`)

**Problem:** Two pairs of duplicate files exist:
- `Subscriptions.res` (uses `Keyboard.onKeyDown`) vs `SubscriptionsFixed.res` (uses `KeyboardFixed.onKeyDown`). Only `SubscriptionsFixed` is wired into `App.res` on line 29.
- `Keyboard.res` (uses `enabler` parameter name) vs `KeyboardFixed.res` (uses `dispatch` parameter name). Only `KeyboardFixed` is used by `SubscriptionsFixed.res`.
- `Subscriptions.res` line 43-49 also has a `Tea_Animationframe.onAnimationFrame` that dispatches `NoOp` -- pure waste.

**What to do:**
1. Delete `./src/Subscriptions.res`.
2. Delete `./src/subscriptions/Keyboard.res`.
3. Delete the corresponding compiled `.res.js` files:
   - `./src/Subscriptions.res.js`
   - `./src/subscriptions/Keyboard.res.js`
4. Confirm `App.res` line 29 references `SubscriptionsFixed.all` (it already does).
5. Rebuild ReScript.

**Verification:**
```bash
cd .
test ! -f src/Subscriptions.res && test ! -f src/subscriptions/Keyboard.res && echo "PASS: duplicates removed"
node_modules/rescript/rescript clean && node_modules/rescript/rescript build 2>&1 | tail -5
# Expected: build succeeds with no errors
deno task test 2>&1 | tail -3
# Expected: all tests pass
```

---

## TASK 3: Implement real `validate_inference` Tauri command (P0 - CORE)

**Files:** `./src-tauri/src/main.rs`

**Problem:** Lines 524-533. The `validate_inference` command does naive substring matching:
it checks if the token string *contains* any constraint string, which is backwards logic
(it rejects "type User = ..." if a constraint says "type"). The TODO on line 525 says
"Implement Echidna-based validation." While full Echidna integration is out of scope,
the current implementation is logically wrong and needs to be a proper constraint checker.

**What to do:**
1. Replace the body of `validate_inference` (lines 526-532) with actual validation logic:
   - Parse each constraint as a simple expression (support at minimum: type name
     declarations like `type Foo = ...`, boundary checks like `length > 0`, and
     forbidden-pattern checks like `!contains("eval(")`).
   - For forbidden-pattern constraints (prefixed with `!contains(`...`)`): reject the token
     if it contains the forbidden substring.
   - For type-name constraints (e.g., `type User`): validate that the token references
     a known type (basic keyword check).
   - For all other constraints: treat them as "must not contradict" -- if the token
     contains a logical negation of the constraint expression, reject it.
   - Return `Ok(true)` if all constraints pass, `Err(reason)` if any fail.
2. Add at least 3 unit tests in the `mod tests` block:
   - Test that a clean token passes with active constraints.
   - Test that a token containing a forbidden pattern is rejected.
   - Test that an empty constraint list always passes.

**Verification:**
```bash
cd ./src-tauri
cargo test validate -- --nocapture 2>&1 | tail -10
# Expected: test result: ok. 3+ passed
cargo check 2>&1 | tail -3
# Expected: no errors
```

---

## TASK 4: Implement real `get_vexation_index` Tauri command (P0 - CORE)

**Files:** `./src-tauri/src/main.rs`

**Problem:** Lines 537-540. `get_vexation_index` always returns `0.0`. The TODO on line 538
says "Implement actual stress indicator tracking." The Vexometer is a core product concept
(measuring operator cognitive friction) and returning a constant zero makes the entire
vexometer UI meaningless.

**What to do:**
1. Add a `lazy_static` or `std::sync::Mutex<VexationTracker>` struct at module level:
   ```rust
   struct VexationTracker {
       cancellations: u32,
       corrections: u32,
       last_update: std::time::Instant,
   }
   ```
2. Add a Tauri command `record_vexation_event` that accepts an event type string
   ("cancellation" or "correction") and increments the counter.
3. In `get_vexation_index`, compute the index as:
   `min(1.0, (cancellations * 0.15 + corrections * 0.08) * decay_factor)`
   where `decay_factor = max(0.1, 1.0 - elapsed_seconds / 120.0)` (decays over 2 minutes).
4. Register `record_vexation_event` in the `invoke_handler` macro on line 777.
5. Add a corresponding `TauriCmd.recordVexationEvent` in
   `./src/commands/TauriCmd.res` and wire
   `Vexometer(RecordCancellation)` and `Vexometer(RecordCorrection)` in
   `./src/Update.res` (currently lines 159-160 only
   increment the local counter but never talk to the backend).
6. Add 2 unit tests: one verifying initial index is 0.0, one verifying index rises
   after recording events.

**Verification:**
```bash
cd ./src-tauri
cargo test vexation -- --nocapture 2>&1 | tail -10
# Expected: test result: ok. 2+ passed
cargo check 2>&1 | tail -3
# Expected: no errors
cd .
node_modules/rescript/rescript build 2>&1 | tail -3
# Expected: no errors
```

---

## TASK 5: Implement real `submit_feedback` Tauri command (P0 - CORE)

**Files:** `./src-tauri/src/main.rs`

**Problem:** Lines 544-552. `submit_feedback` ignores all three pane state arguments
(prefixed with `_`) and just returns a formatted string. The TODO on line 550 says
"Implement feedback submission to community pool." There is no persistence whatsoever.

**What to do:**
1. Create a `feedback/` directory under `src-tauri/` at runtime (use `dirs::data_dir()`
   or `std::env::temp_dir()` joined with `panll/feedback/`).
2. Serialize the feedback as a JSON file with fields: `report_type`, `pane_l_state`,
   `pane_n_state`, `pane_w_state`, `timestamp`, and `id` (UUID or timestamp-based).
3. Write the file to the feedback directory with filename
   `feedback-{report_type}-{timestamp}.json`.
4. Return `Ok(format!("Feedback saved: {}", filepath))` on success.
5. Return `Err(reason)` if file write fails.
6. Add 2 unit tests:
   - Verify feedback JSON file is created with correct structure.
   - Verify error is returned for invalid filesystem conditions (if feasible).

**Verification:**
```bash
cd ./src-tauri
cargo test feedback -- --nocapture 2>&1 | tail -10
# Expected: test result: ok. 2+ passed
cargo check 2>&1 | tail -3
# Expected: no errors
```

---

## TASK 6: Wire OrbitalSync into the update loop (P1 - FEATURE COMPLETION)

**Files:**
- `./src/core/OrbitalSync.res`
- `./src/Update.res`
- `./src/Model.res`

**Problem:** `OrbitalSync.res` is a complete 172-line module with sync detection,
divergence calculation, stability computation, drift aura colour selection, and
humidity level computation. BUT it is never called from anywhere. The `Update.res`
module handles `Orbital(m)` messages (line 414) by directly setting fields, but never
calls `OrbitalSync.sync()` or `OrbitalSync.getHumidityLevel()` to automatically
compute orbital metrics from pane content changes.

**What to do:**
1. Add a `syncState` field to `Model.model` in `Model.res` (after line 176):
   ```rescript
   syncState: OrbitalSync.syncState,
   ```
2. Initialize it in `Model.init()` (after line 247):
   ```rescript
   syncState: OrbitalSync.init(),
   ```
3. In `Update.res`, after line 466 (after computing `finalModel`), add an orbital
   sync step that runs on every message except NoOp and SaveState:
   ```rescript
   let (newSyncState, newOrbital) = OrbitalSync.sync(finalModel, finalModel.syncState)
   let newHumidity = OrbitalSync.getHumidityLevel(finalModel)
   let syncedModel = {...finalModel, syncState: newSyncState, orbital: newOrbital, humidity: newHumidity}
   ```
4. Use `syncedModel` instead of `finalModel` in the return value on line 476.
5. Update `Storage.res` to include `syncState` in persistence (or skip it -- sync
   state is transient and can be re-initialized on load).

**Verification:**
```bash
cd .
node_modules/rescript/rescript clean && node_modules/rescript/rescript build 2>&1 | tail -5
# Expected: build succeeds
deno task test 2>&1 | tail -3
# Expected: all tests pass
```

---

## TASK 7: Wire Contractiles into the update loop (P1 - FEATURE COMPLETION)

**Files:**
- `./src/core/Contractiles.res`
- `./src/Update.res`
- `./src/Model.res`

**Problem:** `Contractiles.res` is a complete 163-line module with 4 built-in contracts
(orbital stability bound, vexation ceiling, divergence limit, autonomy bound), evaluation
logic, and adaptive elasticity adjustment. BUT it is never called from anywhere. The
model has no `contractiles` field, and no update logic evaluates or adapts contracts.

**What to do:**
1. Add a `contractiles` field to `Model.model` in `Model.res`:
   ```rescript
   contractiles: array<Contractiles.contractile>,
   ```
2. Initialize it in `Model.init()`:
   ```rescript
   contractiles: Contractiles.defaultContractiles(),
   ```
3. In `Update.res`, after the orbital sync step (from Task 6), evaluate all contractiles:
   ```rescript
   let evaluationResults = Contractiles.evaluateAll(syncedModel, syncedModel.contractiles)
   let adaptedContractiles = Array.map(syncedModel.contractiles, c => Contractiles.adaptContract(c, syncedModel))
   let contractedModel = {...syncedModel, contractiles: adaptedContractiles}
   ```
4. Optionally: if any contract is `Violated` and enforcement is `Strict`, set
   `antiCrash.halted = true` on the model.
5. Update `Storage.res` to skip contractiles (they are derived state, not user data).

**Verification:**
```bash
cd .
node_modules/rescript/rescript clean && node_modules/rescript/rescript build 2>&1 | tail -5
# Expected: build succeeds
deno task test 2>&1 | tail -3
# Expected: all tests pass
```

---

## TASK 8: Replace AntiCrash placeholder validation with real logic (P1 - CORE)

**Files:** `./src/core/AntiCrash.res`

**Problem:** Three validation functions use trivial string matching as placeholders:

1. `checkTypeConstraints` (lines 29-46): Checks if token content contains "undefined",
   "null", or "NaN". The TODO on line 30 says "Integrate with Echidna for formal type
   checking." The actual logic ignores the constraint expressions entirely -- it just
   searches for hardcoded bad strings.

2. `checkLogicConstraints` (lines 71-80): Only checks for the literal strings
   "true && false" and "!true && true". The TODO on line 72 says "Integrate with
   Echidna for SAT solving."

3. `checkSecurityConstraints` (lines 49-68): This one is actually reasonable -- it
   checks for dangerous code injection patterns. Keep it as-is.

**What to do:**
1. In `checkTypeConstraints`:
   - Parse each active constraint's `expression` field for type declarations
     (e.g., `type Foo = { bar: string }`).
   - Extract field names and types from the constraint expression.
   - If the token's content references a field with a wrong type (e.g., assigns a
     number to a string field), flag a `TypeMismatch`.
   - Keep the existing "undefined"/"null"/"NaN" checks as a fallback safety net.

2. In `checkLogicConstraints`:
   - Parse constraint expressions for simple boolean assertions (e.g., `x > 0`,
     `status == "active"`).
   - Check if the token content contains a direct contradiction (e.g., constraint
     says `x > 0` but token contains `x = -1`).
   - Support at least: equality checks, inequality checks, and boolean assertions.

3. Add a new test file `./tests/anti_crash_test.js` that
   tests the compiled output `src/core/AntiCrash.res.js`:
   - Test: high-confidence clean token passes validation.
   - Test: token containing "eval(" is rejected by security check.
   - Test: token with low confidence (<0.7) requires review.
   - Test: token containing "undefined" is rejected by type check.
   - Test: processToken with disabled antiCrash passes everything.
   - Test: processToken with halted state blocks everything.

**Verification:**
```bash
cd .
node_modules/rescript/rescript build 2>&1 | tail -3
deno test --no-check --allow-read --allow-env tests/anti_crash_test.js 2>&1 | tail -5
# Expected: 6 tests passed
```

---

## TASK 9: Add tests for OrbitalSync module (P1 - TESTING)

**Files:** Create `./tests/orbital_sync_test.js`

**Problem:** OrbitalSync has zero test coverage. It computes divergence, stability,
drift aura colour, and humidity level -- all core product metrics -- with no tests.

**What to do:**
1. Create `tests/orbital_sync_test.js` importing from `src/core/OrbitalSync.res.js`.
2. Test `simpleHash`: empty string returns "empty", non-empty returns length-first-last format.
3. Test `calculateDivergence`: two empty strings return 0.0, one empty returns 1.0,
   equal-length strings return 0.0, different-length strings return proportional value.
4. Test `calculateStability`: zero divergence and zero latency return 1.0, high divergence
   returns low stability.
5. Test `getDriftAuraColour`: stability >= 0.7 returns "indigo", below returns "amber".
6. Test `getHumidityLevel`: high vexation or low stability returns Low, moderate returns
   Medium, calm state returns High.

**Verification:**
```bash
cd .
deno test --no-check --allow-read --allow-env tests/orbital_sync_test.js 2>&1 | tail -5
# Expected: 5+ tests passed, 0 failed
```

---

## TASK 10: Add tests for Contractiles module (P1 - TESTING)

**Files:** Create `./tests/contractiles_test.js`

**Problem:** Contractiles has zero test coverage. It defines 4 built-in contracts,
evaluation logic, and adaptive elasticity -- all untested.

**What to do:**
1. Create `tests/contractiles_test.js` importing from `src/core/Contractiles.res.js`.
2. Test `defaultContractiles`: returns array of 4 contractiles.
3. Test `orbitalStabilityContract`: stability above threshold returns Satisfied,
   below returns Violated with message.
4. Test `vexationCeilingContract`: index below ceiling is Satisfied, above is Violated.
5. Test `evaluateAll`: with a default model, all contracts should be Satisfied
   (default model has stability 1.0, vexation 0.0, divergence 0.0, autonomy 0.0).
6. Test `adaptContract`: higher vexation increases elasticity.

**Verification:**
```bash
cd .
deno test --no-check --allow-read --allow-env tests/contractiles_test.js 2>&1 | tail -5
# Expected: 5+ tests passed, 0 failed
```

---

## TASK 11: Add tests for Update module (P1 - TESTING)

**Files:** Create `./tests/update_test.js`

**Problem:** The Update module is the heart of the TEA architecture -- it processes
every message and transitions the model. It has ZERO test coverage. Zero.

**What to do:**
1. Create `tests/update_test.js` importing from `src/Update.res.js` and `src/Model.res.js`.
2. Test `updatePaneL` with `AddConstraint`: constraint array grows by 1.
3. Test `updatePaneL` with `RemoveConstraint`: constraint is removed.
4. Test `updatePaneL` with `ToggleConstraint`: active flag flips.
5. Test `updatePaneN` with `ReceiveToken`: token array grows by 1.
6. Test `updatePaneN` with `ClearTokens`: token array becomes empty.
7. Test `updateVexometer` with `RecordCancellation`: counter increments.
8. Test `updateVexometer` with `ResetVexometer`: all fields reset to defaults.
9. Test `updateView` with `TogglePaneL`: paneLVisible flips.
10. Test `shouldAutoSave`: returns true for PaneL(AddConstraint) and false for NoOp.
11. Test main `update` function: `NoOp` returns model unchanged with `Tea_Cmd.none`.
12. Test main `update` function: `SaveState` calls Storage.save (mock localStorage).

**Verification:**
```bash
cd .
deno test --no-check --allow-read --allow-env tests/update_test.js 2>&1 | tail -5
# Expected: 10+ tests passed, 0 failed
```

---

## TASK 12: Add ARIA accessibility attributes to all UI components (P2 - A11Y)

**Files:**
- `./src/components/PaneL.res`
- `./src/components/PaneN.res`
- `./src/components/PaneW.res`
- `./src/components/Vexometer.res`
- `./src/components/FeedbackOTron.res`
- `./src/tea/Tea_Vdom.res`

**Problem:** Zero ARIA attributes exist anywhere in the codebase. The ROADMAP.adoc
(line 47) lists "Accessibility improvements (ARIA labels)" as a v0.2.0 Should Have.
No `role`, `aria-label`, `aria-live`, `aria-expanded`, or `aria-hidden` attributes
are present on any element.

**What to do:**
1. First, add `aria` attribute support to `Tea_Vdom.res`. Add after line 41:
   ```rescript
   let ariaLabel = (label: string): attribute<'msg> => Property("aria-label", label)
   let ariaLive = (mode: string): attribute<'msg> => Property("aria-live", mode)
   let ariaExpanded = (b: bool): attribute<'msg> => Property("aria-expanded", b ? "true" : "false")
   let ariaHidden = (b: bool): attribute<'msg> => Property("aria-hidden", b ? "true" : "false")
   let role = (r: string): attribute<'msg> => Property("role", r)
   ```
2. Export them in `Tea_Html.res` `Attrs` module.
3. In `PaneL.res`:
   - Add `role("region")` and `ariaLabel("Symbolic Mass Panel")` to the outer div (line 104).
   - Add `role("list")` to the constraint list container.
   - Add `ariaLabel("Tractatus Editor")` to the textarea (line 87).
4. In `PaneN.res`:
   - Add `role("region")` and `ariaLabel("Neural Stream Panel")` to the outer div (line 162).
   - Add `role("status")` and `ariaLive("polite")` to the inference status indicator.
   - Add `role("progressbar")` to the autonomy bar.
5. In `PaneW.res`:
   - Add `role("region")` and `ariaLabel("Task Barycentre Panel")` to the outer div (line 756).
   - Add `ariaExpanded(state.securityMenuExpanded)` to the security tools toggle.
   - Add `role("dialog")` and `ariaLabel("Security Tools Dialog")` to the dialog overlay.
6. In `Vexometer.res`:
   - Add `role("meter")` and `ariaLabel("Vexation Index")` to the progress bar.
   - Add `ariaLive("polite")` to the status text.
7. In `FeedbackOTron.res`:
   - Add `role("dialog")` and `ariaLabel("Feedback Form")` to the modal overlay (line 92).
   - Add `role("radiogroup")` to the report type button container.

**Verification:**
```bash
cd .
node_modules/rescript/rescript clean && node_modules/rescript/rescript build 2>&1 | tail -5
# Expected: build succeeds
grep -c "aria-label\|role\|aria-live\|aria-expanded" src/components/*.res
# Expected: at least 10 total matches across files
deno task test 2>&1 | tail -3
# Expected: all tests pass
```

---

## TASK 13: Implement VDOM diffing in Tea_Render instead of full re-render (P2 - PERFORMANCE)

**Files:** `./src/tea/Tea_Render.res`

**Problem:** The `update` function on line 169-175 calls `render()` which does a full
re-render: `containerObj["innerHTML"] = ""` (line 116) followed by creating all DOM nodes
from scratch. This destroys and recreates the entire DOM tree on every single message,
which is extremely wasteful and will cause focus loss, scroll position loss, and
animation flicker.

**What to do:**
1. Add a `previousVdom` field to `renderState`:
   ```rescript
   mutable previousVdom: option<t<'msg>>,
   ```
2. Implement a `diff` function that compares old and new VDOM trees:
   - If both are `Text` nodes with same content: no-op.
   - If both are `Text` nodes with different content: update `textContent`.
   - If both are `Element` nodes with same tag: patch attributes and recurse on children.
   - If nodes differ in type/tag: replace the DOM node entirely.
3. Implement `patchAttributes` to add/remove/update attributes between old and new.
4. Implement `patchChildren` to handle child list changes (add, remove, reorder).
5. Update the `update` function to call `diff` instead of `render` when `previousVdom`
   is Some.
6. Store `previousVdom = Some(vdom)` after each render/diff cycle.

**Verification:**
```bash
cd .
node_modules/rescript/rescript clean && node_modules/rescript/rescript build 2>&1 | tail -5
# Expected: build succeeds
deno task test 2>&1 | tail -3
# Expected: all tests pass (existing Tea_Render tests still work)
```

---

## TASK 14: Update ROADMAP.adoc to reflect actual status (P2 - DOCS)

**Files:** `./ROADMAP.adoc`

**Problem:** The roadmap (lines 38-41) lists "State persistence" and "Keyboard shortcuts"
as TODO items under v0.2.0, but both are already implemented (`src/Storage.res` and
`src/SubscriptionsFixed.res`). The completion percentage on line 10 claims "95% Complete"
which is inflated.

**What to do:**
1. On line 10, change `95% Complete` to `80% Complete`.
2. Under v0.2.0 "Must Have" (lines 38-41):
   - Change `[ ] State persistence (localStorage/Tauri)` to `[x] State persistence (localStorage) -- implemented in src/Storage.res`.
   - Change `[ ] Basic settings management` to remain TODO.
3. Under v0.2.0 "Should Have" (lines 44-48):
   - Change `[ ] Keyboard shortcuts fully implemented` to `[x] Keyboard shortcuts implemented (Ctrl+Shift+L/N/B/W) -- src/SubscriptionsFixed.res`.
4. Add a note under "Completed in v0.1.0" section:
   ```
   * [x] State persistence via localStorage
   * [x] Keyboard shortcuts (Ctrl+Shift+L/N/B/W)
   * [x] Event-chain import from panic-attacker
   * [x] BEAM API scaffold (HTTP/GraphQL/gRPC)
   ```

**Verification:**
```bash
cd .
grep -c "\[x\] State persistence" ROADMAP.adoc
# Expected: 1
grep -c "\[x\] Keyboard shortcuts" ROADMAP.adoc
# Expected: 1
grep "80%" ROADMAP.adoc | head -1
# Expected: line containing "80% Complete"
```

---

## TASK 15: Update README.adoc completion badge and status (P2 - DOCS)

**Files:** `./README.adoc`

**Problem:** Line 9 claims `completion-95%25` in the badge. Line 11 claims `33 passing`
tests but there are actually 36. Line 146 says "95% complete". These are inaccurate.

**What to do:**
1. Line 9: Change `completion-95%25-brightgreen` to `completion-80%25-green`.
2. Line 11: Change `33%20passing%20(719ms)` to `36%20passing`.
3. Line 146: Change `95% complete` to `80% complete`.
4. Line 148-157: Add entries for implemented features:
   - State persistence (localStorage)
   - BEAM API scaffold (HTTP/GraphQL/gRPC)

**Verification:**
```bash
cd .
grep -c "80%" README.adoc
# Expected: at least 2
grep -c "36" README.adoc
# Expected: at least 1 (test count)
```

---

## TASK 16: Fix the PanllBeam module boilerplate (P3 - CLEANUP)

**Files:** `./beam/panll_beam/lib/panll_beam.ex`

**Problem:** The root module `PanllBeam` (lines 1-18) still has the default Phoenix
`hello/0` function that returns `:world`. This is mix generator boilerplate that was
never replaced with actual module documentation or API.

**What to do:**
1. Replace the `hello/0` function with proper module documentation:
   ```elixir
   defmodule PanllBeam do
     @moduledoc """
     PanLL BEAM Runtime - protocol-selectable API surface for the PanLL eNSAID.

     Supports HTTP, GraphQL, and gRPC via the `PANLL_BEAM_APIS` environment variable.
     """
   end
   ```
2. Remove the `@doc` for hello and the function itself.

**Verification:**
```bash
cd ./beam/panll_beam
grep -c "hello" lib/panll_beam.ex
# Expected: 0
mix compile 2>&1 | tail -3
# Expected: compiles without errors
```

---

## TASK 17: Add tests for EventChain edge cases (P2 - TESTING)

**Files:** Modify `./tests/panic_attacker_event_chain_test.js`

**Problem:** Only 3 tests exist for the event-chain parser. Missing: empty event_chain
array, missing fields on individual events, extra unknown fields, numeric vs string id
coercion.

**What to do:**
1. Add test: empty `event_chain` array returns `Ok` with `events: []` and no error.
2. Add test: event with missing `id` field defaults to `""`.
3. Add test: event with missing `duration_ms` defaults to `0.0`.
4. Add test: payload with extra unknown top-level fields is still parsed successfully.
5. Add test: completely empty JSON object `{}` returns `Ok` with empty events array.

**Verification:**
```bash
cd .
deno test --no-check --allow-read --allow-env tests/panic_attacker_event_chain_test.js 2>&1 | tail -5
# Expected: 8 tests passed (3 original + 5 new), 0 failed
```

---

## TASK 18: Add Storage round-trip tests for edge cases (P2 - TESTING)

**Files:** Modify `./tests/storage_timeline_roundtrip_test.js`

**Problem:** Only 1 test exists for storage round-trip. Missing: empty model round-trip,
model with constraints, viewMode persistence, humidity persistence.

**What to do:**
1. Add test: default `Model.init()` survives `save`/`load` round-trip with all
   defaults intact.
2. Add test: model with 3 constraints survives round-trip; constraint `id`, `expression`,
   `active`, and `pinned` fields are all preserved.
3. Add test: `viewMode: "Zen"` round-trips correctly (not defaulting to DarkStart).
4. Add test: `humidity: "Low"` round-trips correctly.
5. Add test: `clear()` followed by `load()` returns `undefined`/`None`.

**Verification:**
```bash
cd .
deno test --no-check --allow-read --allow-env tests/storage_timeline_roundtrip_test.js 2>&1 | tail -5
# Expected: 6 tests passed (1 original + 5 new), 0 failed
```

---

## TASK 19: Update STATE.scm with honest completion percentages (P1 - METADATA)

**Files:** `./.machine_readable/STATE.scm`

**Problem:** Line 22 claims `(completion-percentage 100)` for v0.1.0. This is false.
Line 23 says `(phase "release")`. The project is not release-ready.

**What to do:**
1. Line 22: Change `(completion-percentage 100)` to `(completion-percentage 80)`.
2. Line 23: Change `(phase "release")` to `(phase "development")`.
3. Line 24: Change `(current-focus "v0.1.0 production release")` to
   `(current-focus "Complete backend stubs, wire OrbitalSync/Contractiles, add tests")`.
4. Update BLOCK-3 severity from "low" to "high" (line 133-136) since the stubs
   affect core product functionality.
5. Add a new session entry:
   ```scheme
   ((session-id "2026-02-12-opus-audit")
    (date "2026-02-12")
    (agent "Claude Opus 4.6")
    (focus "Honest audit and SONNET-TASKS.md generation")
    (outcomes
      ("Honest completion assessment: 72-80% (not 95-100%)")
      ("Identified 3 backend command stubs in src-tauri/src/main.rs")
      ("Identified 2 unwired core modules: OrbitalSync, Contractiles")
      ("Identified 0 ARIA attributes across all UI components")
      ("Identified Tea_Render doing full re-render instead of VDOM diff")
      ("Created SONNET-TASKS.md with 19 prioritized completion tasks")))
   ```

**Verification:**
```bash
cd .
grep "completion-percentage 80" .machine_readable/STATE.scm
# Expected: 1 match
grep "phase.*development" .machine_readable/STATE.scm
# Expected: 1 match
```

---

## FINAL VERIFICATION

After completing all 19 tasks, run:

```bash
cd .

# 1. ReScript compiles clean
node_modules/rescript/rescript clean && node_modules/rescript/rescript build 2>&1

# 2. All Deno tests pass
deno task test 2>&1

# 3. Rust backend compiles clean
cd src-tauri && cargo check 2>&1

# 4. Rust tests pass
cargo test 2>&1

# 5. No deprecated module config
cd .
grep '"es6"' rescript.json
# Expected: no output

# 6. No duplicate subscription files
test ! -f src/Subscriptions.res && test ! -f src/subscriptions/Keyboard.res && echo "CLEAN"

# 7. ARIA attributes present
grep -r "aria-label" src/components/*.res | wc -l
# Expected: >= 5

# 8. STATE.scm is honest
grep "completion-percentage 80" .machine_readable/STATE.scm && echo "HONEST"

# 9. Test count increased
deno task test 2>&1 | grep -E "passed|failed" | tail -1
# Expected: 50+ passed, 0 failed
```

**After all verifications pass, update STATE.scm completion-percentage to the new honest
value (should be around 90-92% after completing all tasks in this file).**
