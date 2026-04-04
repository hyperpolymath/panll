# src/components/ — Panel View Components

## Purpose

Contains the view functions for all 108 PanLL panels. Each component renders a panel's UI using the custom TEA virtual DOM (`Tea_Html`). Components are pure functions: `model -> Tea_Html.t<msg>`.

## Boundary

- **Imports**: `Model`, `Msg`, `Tea_Html`, `Attrs`, `Events`
- **Used by**: `View.res` (the main view dispatcher)
- **Does NOT import**: `Update`, `Storage`, `RuntimeBridge`, or commands

## Invariants

- Components are pure view functions — no side effects, no state mutation
- Use `list{}` for vdom children: `Tea_Html.div(list{}, list{...})`
- Use `Events.onClick` / `Events.onInput` for event handlers
- Say "panel" never "pane" in all labels and comments
- All components must support keyboard navigation (`onActivate` callback)

## Naming Convention

`{PanelName}.res` — matches the panel name in the panel switcher.
