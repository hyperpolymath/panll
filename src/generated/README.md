# src/generated/ — Auto-Generated Modules

SPDX-License-Identifier: PMPL-1.0-or-later

**DO NOT EDIT FILES IN THIS DIRECTORY MANUALLY.**

These modules are generated from ABI schemas and will be overwritten by the
generation tooling.

## Files

- **CartridgeAbi.res** — Typed cartridge and tool definitions generated from
  `src/abi/cartridge-schema.json`. Provides compile-time safety for BoJ
  cartridge invocations — any typo in cartridge or tool name becomes a
  compiler error.

## Regeneration

```bash
deno task gen:cartridge-abi
```
