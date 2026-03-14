// SPDX-License-Identifier: PMPL-1.0-or-later
// Seam test: validates CartridgeAbi.res matches cartridge-schema.json.
// This is a compile-time + runtime seam — if CartridgeAbi.res drifts from the
// schema (or the schema drifts from BoJ's actual ABI), this test catches it.
// Inspired by BoJ's seams.zig pattern (ABI/FFI integration contract tests).

import { strict as assert } from "node:assert"
import { readFileSync } from "node:fs"
import { test } from "node:test"
import * as CartridgeAbi from "../src/generated/CartridgeAbi.res.mjs"

const schema = JSON.parse(
  readFileSync(new URL("../src/abi/cartridge-schema.json", import.meta.url), "utf-8")
)

// ── Seam 1: Cartridge count ─────────────────────────────────────────────────
test("seam: cartridge count matches schema", () => {
  const schemaCount = Object.keys(schema.cartridges).length
  assert.equal(
    CartridgeAbi.cartridgeCount,
    schemaCount,
    `CartridgeAbi.cartridgeCount (${CartridgeAbi.cartridgeCount}) != schema (${schemaCount})`
  )
})

// ── Seam 2: Every schema cartridge has a valid variant ──────────────────────
test("seam: every schema cartridge round-trips through fromString/toString", () => {
  for (const name of Object.keys(schema.cartridges)) {
    const parsed = CartridgeAbi.cartridgeFromString(name)
    assert.notEqual(parsed, undefined, `cartridgeFromString("${name}") returned None`)
    // Unwrap the Some() — ReScript option encoding
    const variant = parsed
    if (variant !== undefined) {
      const roundTripped = CartridgeAbi.cartridgeToString(variant)
      assert.equal(roundTripped, name, `round-trip failed: ${name} -> ${roundTripped}`)
    }
  }
})

// ── Seam 3: toWire produces valid (cartridge, tool) pairs ───────────────────
test("seam: toWire output cartridge names are all in schema", () => {
  // Test a representative invocation from each cartridge
  const testCases = [
    CartridgeAbi.$$invocation.Agent(CartridgeAbi.$$agentTool.Reset),
    CartridgeAbi.$$invocation.Database(CartridgeAbi.$$databaseTool.Connect),
    CartridgeAbi.$$invocation.Nesy(CartridgeAbi.$$nesyTool.Harmonize),
    CartridgeAbi.$$invocation.Lsp(CartridgeAbi.$$lspTool.CreateSession),
    CartridgeAbi.$$invocation.Dap(CartridgeAbi.$$dapTool.Launch),
    CartridgeAbi.$$invocation.Bsp(CartridgeAbi.$$bspTool.Build),
    CartridgeAbi.$$invocation.Proof(CartridgeAbi.$$proofTool.Verify),
    CartridgeAbi.$$invocation.Secrets(CartridgeAbi.$$secretsTool.Unseal),
  ]

  for (const inv of testCases) {
    const [cartName, toolName] = CartridgeAbi.toWire(inv)
    assert.ok(
      cartName in schema.cartridges,
      `toWire produced unknown cartridge: ${cartName}`
    )
    assert.ok(
      toolName in schema.cartridges[cartName].tools,
      `toWire produced unknown tool: ${cartName}/${toolName}`
    )
  }
})

// ── Seam 4: Tool count integrity ────────────────────────────────────────────
test("seam: total tool count matches schema", () => {
  let schemaToolCount = 0
  for (const cart of Object.values(schema.cartridges)) {
    schemaToolCount += Object.keys(cart.tools).length
  }
  assert.equal(
    CartridgeAbi.toolCount,
    schemaToolCount,
    `CartridgeAbi.toolCount (${CartridgeAbi.toolCount}) != schema (${schemaToolCount})`
  )
})

// ── Seam 5: Tier assignment matches schema ──────────────────────────────────
test("seam: tier assignments match schema", () => {
  for (const [name, def] of Object.entries(schema.cartridges)) {
    const variant = CartridgeAbi.cartridgeFromString(name)
    if (variant !== undefined) {
      const tier = CartridgeAbi.cartridgeTier(variant)
      // ReScript variant encoding — check tag name
      const tierName = typeof tier === "object" && tier !== null
        ? Object.keys(tier)[0]?.toLowerCase()
        : String(tier).toLowerCase()
      // Simple check: shield cartridges must be shield in schema
      if (def.tier === "shield") {
        assert.ok(
          tierName === "shield" || String(tier) === "Shield",
          `${name} should be Shield tier but got ${tier}`
        )
      }
    }
  }
})

// ── Seam 6: No duplicate tool names within a cartridge ──────────────────────
test("seam: no duplicate tool names in schema", () => {
  for (const [name, def] of Object.entries(schema.cartridges)) {
    const tools = Object.keys(def.tools)
    const unique = new Set(tools)
    assert.equal(
      tools.length,
      unique.size,
      `${name} has duplicate tool names`
    )
  }
})

// ── Seam 7: Schema version is semver ────────────────────────────────────────
test("seam: schema version is valid semver", () => {
  assert.match(schema.version, /^\d+\.\d+\.\d+$/, "Schema version must be semver")
})

// ── Seam 8: Every cartridge has at least one tool ───────────────────────────
test("seam: every cartridge exposes at least one tool", () => {
  for (const [name, def] of Object.entries(schema.cartridges)) {
    assert.ok(
      Object.keys(def.tools).length > 0,
      `${name} has zero tools`
    )
  }
})

// ── Seam 9: Protocol list is non-empty for all cartridges ───────────────────
test("seam: every cartridge supports at least one protocol", () => {
  for (const [name, def] of Object.entries(schema.cartridges)) {
    assert.ok(
      def.protocols.length > 0,
      `${name} has zero protocols`
    )
    // All protocols must be in the global list
    for (const proto of def.protocols) {
      assert.ok(
        schema.protocols.includes(proto),
        `${name} has unknown protocol: ${proto}`
      )
    }
  }
})
