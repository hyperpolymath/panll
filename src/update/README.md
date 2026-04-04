# src/update/ — TEA Sub-Updaters

## Purpose

Contains pure state transition functions for each domain. The main `Update.res` dispatcher routes messages to the appropriate sub-updater. Each sub-updater returns `(model, Tea_Cmd.t<msg>)`.

## Boundary

- **Imports**: `Model`, `Msg`, domain-specific `XxxCmd` modules
- **Used by**: `Update.res` (the only consumer)
- **Dependency direction**: update → commands → RuntimeBridge

## Invariants

- Sub-updaters are pure: `(model, domainMsg) => (model, Tea_Cmd.t<msg>)`
- Side effects are encoded as `Tea_Cmd.t` values, never executed directly
- The only imperative call in the update layer is `Storage.save()` in `SaveState`

## Naming Convention

`Update{Domain}.res` — e.g. `UpdateService.res`, `UpdateSettings.res`, `UpdateAerie.res`

## Adding a New Sub-Updater

1. Create `src/update/UpdateNewDomain.res` with `let updateNewDomain = (model, subMsg) => ...`
2. Open `Model` and `Msg` at the top
3. Handle every variant of `newDomainMsg` exhaustively
4. Add dispatch in `src/Update.res`: `| NewDomain(subMsg) => UpdateNewDomain.updateNewDomain(model, subMsg)`
5. Consider adding to `shouldAutoSave` exclusion if the domain has its own persistence
