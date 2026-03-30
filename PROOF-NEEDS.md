# PROOF-NEEDS.md — panll

## Current State

- **src/abi/**: YES — contains `cartridge-schema.json` and `README.md` (no Idris2 files)
- **Dangerous patterns**: 0 in own code (164 references are all in UI display code that shows believe_me/Admitted counts from OTHER repos)
- **LOC**: ~138,000 (ReScript + Rust)
- **ABI layer**: Schema-only, no Idris2 proofs

## What Needs Proving

| Component | What | Why |
|-----------|------|-----|
| Cartridge schema validation | Cartridge loading validates against schema correctly | Malformed cartridges crash panels or produce wrong output |
| PCC constraint propagator | Constraint propagation is sound and complete | PanLL Constraint Checker is the build-time safety net |
| PCC ReScript scanner | Scanner correctly identifies all constraint violations | Missed violations bypass safety checks |
| Verification Dashboard accuracy | Dashboard accurately reflects actual proof state | Displaying wrong verification state gives false confidence |
| Provenance engine | Provenance tracking is complete and unforgeable | Provenance gaps break audit trail |
| Gossamer coprocessor commands | Command dispatch is total (no unhandled commands) | Unhandled commands silently fail |
| Wiring Inspector | Wiring analysis correctly identifies all connections | Missing wires mean broken panel communication |

## Recommended Prover

**Idris2** — Replace schema-only ABI with proper Idris2 types. PCC constraint propagation is a natural fit for formal verification. The Rust PCC tool (`tools/pcc/`) should have soundness proofs.

## Priority

**MEDIUM** — PanLL is the developer panel system. PCC soundness is the highest-value proof (it checks constraints across the ecosystem). The Verification Dashboard must accurately reflect proof state to avoid false confidence.
