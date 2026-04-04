# src/panels/ — Panel Composition Root Views

## Purpose

Contains the top-level panel composition views that arrange components into the three-panel layout (Panel-L Symbolic, Panel-N Neural, Panel-W World). Panel registry and lifecycle management.

## Boundary

- **Imports**: `Model`, `Msg`, `src/components/` panel views
- **Used by**: `View.res`
- **Dependency direction**: panels → components → Tea_Html
