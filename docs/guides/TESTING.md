<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TESTING.md — Testing guide for PanLL -->
<!-- Last updated: 2026-03-09 -->

# Testing Guide

PanLL has two test suites: Deno tests for the ReScript frontend engines and
Cargo tests for the Rust backend modules.

## Running Tests

### Frontend (Deno)

```bash
# Run all tests
deno task test

# Run all tests (equivalent explicit command)
deno test --no-check --allow-read --allow-env tests/

# Watch mode — re-runs on file changes
deno task test:watch

# With coverage report
deno task test:coverage
```

### Backend (Rust)

```bash
cd src-tauri && cargo test
```

## Frontend Test Architecture

Frontend tests import **compiled** `.res.js` files from engine modules and
exercise pure functions. No browser or Tauri runtime is needed.

### Import Pattern

```javascript
import { someFunction } from "../src/core/XxxEngine.res.js";
```

Tests import from the compiled JavaScript output of ReScript engines. The
`--no-check` flag is required because Deno would otherwise try to type-check
the `.res.js` files (which have no type annotations).

### What Engines Test

Engine files (`src/core/XxxEngine.res`) contain **pure functions** — state
transitions, data formatting, filtering, validation. They have no side effects
and no Tauri dependencies, making them straightforward to test.

Typical test patterns:
- Initial state construction
- State transition correctness (applying messages to models)
- Filtering and search logic
- Data formatting and serialization
- Edge cases (empty arrays, missing fields, boundary values)

### How to Add a New Test File

1. Create `tests/xxx_engine_test.js` (snake_case, matching the engine name)
2. Import functions from the compiled engine:
   ```javascript
   import { functionName } from "../src/core/XxxEngine.res.js";
   ```
3. Use `Deno.test()` with descriptive names:
   ```javascript
   Deno.test("XxxEngine - describes what is being tested", () => {
     // Arrange
     const input = { /* ... */ };
     // Act
     const result = functionName(input);
     // Assert
     assertEquals(result, expected);
   });
   ```
4. Run: `deno task test`

### Permissions

Tests use two Deno permissions:
- `--allow-read` — reading compiled `.res.js` files from `src/`
- `--allow-env` — some engines read environment variables for configuration

## Backend Test Architecture

Rust tests use the standard `#[cfg(test)]` module pattern. There are 18 Rust
source files with test modules, primarily in the command modules under
`src-tauri/src/<module>/commands.rs`.

### Modules with Rust Tests

| Module | File |
|--------|------|
| main | `src-tauri/src/main.rs` |
| coprocessor | `src-tauri/src/coprocessor/commands.rs` |
| k9 | `src-tauri/src/k9/commands.rs` |
| a2ml | `src-tauri/src/a2ml/commands.rs` |
| observability | `src-tauri/src/observability/commands.rs` |
| governance | `src-tauri/src/governance/commands.rs` |
| umoja | `src-tauri/src/umoja/commands.rs` |
| release_manager | `src-tauri/src/release_manager/commands.rs` |
| dlc_workshop | `src-tauri/src/dlc_workshop/commands.rs` |
| level_architect | `src-tauri/src/level_architect/commands.rs` |
| multiplayer_monitor | `src-tauri/src/multiplayer_monitor/commands.rs` |
| network_topology | `src-tauri/src/network_topology/commands.rs` |
| valence_shell | `src-tauri/src/valence_shell/commands.rs` |
| vm_inspector | `src-tauri/src/vm_inspector/commands.rs` |
| game_preview | `src-tauri/src/game_preview/commands.rs` |
| typell | `src-tauri/src/typell/commands.rs` |
| boj | `src-tauri/src/boj/commands.rs` |
| overlay | `src-tauri/src/overlay/commands.rs` |

## Coverage Matrix

### Frontend Test Files (45 files)

| Test File | Engine / Module Covered |
|-----------|------------------------|
| `aerie_engine_test.js` | AerieEngine |
| `ai_engine_test.js` | AiEngine |
| `anti_crash_test.js` | AntiCrashModel / validation |
| `automation_router_engine_test.js` | AutomationRouterEngine |
| `boj_engine_test.js` | BojEngine |
| `clade_browser_engine_test.js` | CladeBrowserEngine |
| `cloudguard_engine_test.js` | CloudGuardEngine |
| `connection_manager_test.js` | Connection management utilities |
| `contractiles_test.js` | Contractile validation |
| `coprocessors_engine_test.js` | CoprocessorsEngine |
| `echidna_update_test.js` | ECHIDNA update integration |
| `ensaid_config_engine_test.js` | EnsaidConfigEngine |
| `event_chain_persistence_test.js` | Event chain storage |
| `farm_engine_test.js` | FarmEngine |
| `game_preview_engine_test.js` | GamePreviewEngine |
| `governance_engine_test.js` | GovernanceEngine |
| `keybindings_engine_test.js` | KeybindingsEngine |
| `level_architect_engine_test.js` | LevelArchitectEngine |
| `minter_engine_test.js` | MinterEngine |
| `mylang_engine_test.js` | MyLangEngine |
| `network_topology_engine_test.js` | NetworkTopologyEngine |
| `orbital_sync_test.js` | Orbital sync utilities |
| `panel_registry_test.js` | PanelRegistry |
| `panic_attacker_capability_test.js` | panic-attack capability detection |
| `panic_attacker_event_chain_test.js` | panic-attack event chain parsing |
| `panic_attacker_mode_test.js` | panic-attack mode selection |
| `plaza_engine_test.js` | PlazaEngine |
| `protocol_squisher_engine_test.js` | ProtocolSquisherEngine |
| `safedom_bench_test.js` | SafeDOM benchmarks |
| `safedom_test.js` | SafeDOM sanitization |
| `seam_engine_test.js` | SeamEngine |
| `storage_timeline_roundtrip_test.js` | Storage / timeline persistence |
| `tea_app_test.js` | Tea_App lifecycle |
| `tea_cmd_test.js` | Tea_Cmd side effects |
| `tea_render_test.js` | Tea_Render DOM output |
| `tea_sub_test.js` | Tea_Sub subscriptions |
| `tentacles_engine_test.js` | TentaclesEngine |
| `typell_engine_test.js` | TypeLLEngine |
| `undo_engine_test.js` | UndoEngine |
| `update_integration_test.js` | Update loop integration |
| `update_test.js` | Update function unit tests |
| `vab_engine_test.js` | VabEngine |
| `valence_shell_engine_test.js` | ValenceShellEngine |
| `vm_inspector_engine_test.js` | VmInspectorEngine |
| `workspace_engine_test.js` | WorkspaceEngine |

### Engines Without Dedicated Test Files

The following engines in `src/core/` do not have matching test files in `tests/`:

| Engine | Reason |
|--------|--------|
| BuildDashboardEngine | IDApTIK-specific, tested via integration |
| CaptureEngine | File I/O heavy, tested via Rust backend |
| DlcWorkshopEngine | IDApTIK-specific, tested via Rust backend |
| EditorBridgeEngine | LSP protocol, tested via Rust backend |
| FleetEngine | External API dependent |
| HypatiaEngine | External API dependent |
| InterfacesEngine | Filesystem scanning |
| MigrationEngine | CLI integration |
| MultiplayerMonitorEngine | WebSocket dependent |
| ObservabilityEngine | SARIF/OTel export |
| PlaygroundsEngine | NQC proxy dependent |
| ProvenanceEngine | Git blame parsing |
| ProvisionerEngine | Configuration management |
| ReleaseManagerEngine | IDApTIK-specific |
| RepoLoaderEngine | Filesystem scanning |
| ReposystemEngine | Filesystem scanning |
| SecurityEngine | Vault/2FA integration |
| StatusBarEngine | UI utility |
| VoiceTagEngine | Filesystem I/O |
| A2mlEngine | Manifest parsing (tested via Rust) |
| K9Engine | Contractile validation (tested via Rust) |

## Test Counts

| Suite | Files | Approximate Tests |
|-------|-------|-------------------|
| Deno (frontend) | 45 | ~979 |
| Cargo (backend) | 18 | ~164 |
| **Total** | **63** | **~1,143** |
