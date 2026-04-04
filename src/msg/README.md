# src/msg/ — TEA Message Modules

## Purpose

Contains all message type definitions for PanLL's TEA update loop. Each module defines the message variants for one domain. The composition root `Msg.res` re-exports all types via `include` and defines the unified `type msg`.

## Boundary

- **Imports**: `Model` (for types referenced in message payloads)
- **Exported by**: `Msg.res` via `include XxxMsg`
- **Used by**: `src/update/`, `src/commands/`, `src/components/`

## Invariants

- Message modules define `type xxxMsg` variants only — no functions
- Every variant must have a handler in the corresponding `UpdateXxx.res`
- Adding a variant to `type msg` in `Msg.res` requires a dispatch case in `Update.res`

## Naming Convention

`{Domain}Msg.res` — e.g. `ServiceMsg.res`, `IdentityMsg.res`, `BurbleMsg.res`

## Adding a New Module

1. Create `src/msg/NewDomainMsg.res` with `type newDomainMsg = ...`
2. Add `include NewDomainMsg` to `src/Msg.res`
3. Add `| NewDomain(newDomainMsg)` to the unified `type msg` in `Msg.res`
4. Create the corresponding updater in `src/update/UpdateNewDomain.res`
5. Add dispatch in `src/Update.res`: `| NewDomain(subMsg) => UpdateNewDomain.update(model, subMsg)`
