# src/tea/ — Custom TEA Runtime

## Purpose

PanLL's permanent custom implementation of The Elm Architecture (TEA) for ReScript. This is NOT rescript-tea — it's a purpose-built runtime with 18 modules supporting keyed diffing, fragments, SVG, 80+ attributes, 30+ events, HTTP, JSON, keyboard, mouse, window, SSR, debug, and testing.

## Boundary

- **Imports**: Nothing (standalone runtime, no PanLL dependencies)
- **Used by**: Everything — all panels, all views, all subscriptions
- **Never replaced by**: rescript-tea@0.16.0 (incompatible API)

## Invariants

- This is a permanent fork, NOT a temporary shim
- `list{}` syntax for vdom children: `Tea_Html.div(list{}, list{...})`
- `Events.onClick` / `Events.onInput` for events (NOT `Events.onCheck`)
- `Attrs.style("property", "value")` takes two string args
- `Tea_Cmd.call(callbacks => ...)` for async commands

## Key Modules

| Module | Purpose |
|--------|---------|
| `Tea_App.res` | Application bootstrap (`standardProgram`) |
| `Tea_Html.res` | Virtual DOM elements and attributes |
| `Tea_Cmd.res` | Side-effect commands |
| `Tea_Sub.res` | Subscriptions (timers, events) |
| `Tea_Json.res` | JSON decoders for TEA |
| `Tea_Http.res` | HTTP request commands |
| `Tea_Test.res` | Testing utilities |
