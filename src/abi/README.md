# src/abi/ — ABI Schema Definitions

SPDX-License-Identifier: PMPL-1.0-or-later

This directory contains the **source-of-truth ABI schemas** that define the
contract between PanLL and external systems (primarily the BoJ cartridge server).

## Files

- **cartridge-schema.json** — Complete BoJ cartridge ABI schema extracted from
  Idris2 ABI definitions + Zig FFI exports + V-lang adapter endpoints. Defines
  all 21 cartridges, their tools, parameters, states, protocols, and tiers.

## How It's Used

1. **CartridgeAbi.res** (in `src/generated/`) is generated from this schema
2. **ppx_typell** validates compile-time invocations against this schema
3. **Seam tests** (in `tests/cartridge_abi_seam_test.js`) validate that
   CartridgeAbi.res matches this schema at test time
4. **BoJ seams.zig** (in boj-server) validates the BoJ catalogue matches
   the cartridge count and protocol assignments declared here

## Regeneration

```bash
deno task gen:cartridge-abi
```

This reads `cartridge-schema.json` and regenerates `src/generated/CartridgeAbi.res`.
