# src/model/ — Domain Type Modules

## Purpose

Contains all domain-specific type definitions for PanLL's TEA architecture. Each model module defines the types (records, variants, aliases) for one domain slice. The composition root `Model.res` re-exports all types via `include`.

## Boundary

- **Imports**: Nothing (leaf modules, no dependencies on other PanLL code)
- **Exported by**: `Model.res` via `include XxxModel`
- **Used by**: `src/msg/`, `src/update/`, `src/core/`, `src/commands/`, `src/components/`

## Invariants

- Model modules are pure type definitions — no functions, no side effects
- All variant types must be exhaustively matched throughout the codebase
- New fields added to the `model` record in `Model.res` must have init values in `init()`

## Naming Convention

`{Domain}Model.res` — e.g. `BurbleModel.res`, `ServiceModel.res`, `VeriSimModel.res`

## Adding a New Module

1. Create `src/model/NewDomainModel.res` with types
2. Add `include NewDomainModel` to `src/Model.res`
3. Add any new fields to the `model` record in `Model.res`
4. Add init values in the `init()` function in `Model.res`
5. Run `npx rescript build` — compiler errors show every place needing updates
