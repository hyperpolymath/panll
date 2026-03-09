// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * K9Engine Tests — validation, generation, hunt permissions, summaries
 */

import { assertEquals } from "jsr:@std/assert";
import {
  validateContractile,
  generateKennelSchema,
  generateYardContract,
  cartridgeToKennelFields,
  checkHuntPermission,
  summariseContractile,
} from "../src/core/K9Engine.res.js";

// -- validateContractile --

Deno.test("validateContractile flags empty content", () => {
  const result = validateContractile("");
  assertEquals(result.isValid, false);
  assertEquals(result.errors.some(e => e.includes("Empty")), true);
});

Deno.test("validateContractile flags missing pedigree", () => {
  const result = validateContractile("leash = 'Kennel");
  assertEquals(result.isValid, false);
  assertEquals(result.errors.some(e => e.includes("pedigree")), true);
});

Deno.test("validateContractile valid Kennel file", () => {
  const content = `K9!
pedigree = {
  name = "test"
}
leash = 'Kennel`;
  const result = validateContractile(content);
  assertEquals(result.isValid, true);
  assertEquals(result.securityLevel, "Kennel");
});

Deno.test("validateContractile Hunt requires side_effects and signature", () => {
  const content = `pedigree = {
  name = "hunt-test"
}
leash = 'Hunt`;
  const result = validateContractile(content);
  assertEquals(result.isValid, false);
  assertEquals(result.errors.some(e => e.includes("side_effects")), true);
  assertEquals(result.errors.some(e => e.includes("signature_required")), true);
});

Deno.test("validateContractile extracts name from content", () => {
  const content = `pedigree = { }
name = "my-module"
leash = 'Kennel`;
  const result = validateContractile(content);
  assertEquals(result.name, "my-module");
});

Deno.test("validateContractile extracts name from path fallback", () => {
  const result = validateContractile("pedigree = {}\nleash = 'Kennel", "/path/to/widget.k9.ncl");
  assertEquals(result.name, "widget");
});

// -- generateKennelSchema --

Deno.test("generateKennelSchema produces valid output", () => {
  const fields = [["name", "String", '"MyPanel"'], ["enabled", "Bool", "true"]];
  const result = generateKennelSchema("MyPanel", fields);
  assertEquals(result.includes("K9!"), true);
  assertEquals(result.includes("MyPanel"), true);
  assertEquals(result.includes("kennel"), true);
  assertEquals(result.includes("PMPL-1.0-or-later"), true);
});

// -- generateYardContract --

Deno.test("generateYardContract produces valid output", () => {
  const result = generateYardContract("echo", ["REST", "gRPC"], 8080, 9090, 4000, "D");
  assertEquals(result.includes("K9!"), true);
  assertEquals(result.includes("echo"), true);
  assertEquals(result.includes("Yard"), true);
  assertEquals(result.includes('"REST"'), true);
  assertEquals(result.includes("8080"), true);
});

// -- cartridgeToKennelFields --

Deno.test("cartridgeToKennelFields returns 6 fields", () => {
  const fields = cartridgeToKennelFields("echo", ["REST", "gRPC"]);
  assertEquals(fields.length, 6);
  assertEquals(fields[0][0], "name");
  assertEquals(fields[0][2], '"echo"');
  assertEquals(fields[2][0], "protocols");
});

// -- checkHuntPermission --

Deno.test("checkHuntPermission allowed when all conditions met", () => {
  const [allowed, msg] = checkHuntPermission("hunt", true, "signature_required = true");
  assertEquals(allowed, true);
  assertEquals(msg.includes("permitted"), true);
});

Deno.test("checkHuntPermission denied when isolation disallows", () => {
  const [allowed, _msg] = checkHuntPermission("kennel", true, "signature_required = true");
  assertEquals(allowed, false);
});

Deno.test("checkHuntPermission denied when no signing", () => {
  const [allowed, _msg] = checkHuntPermission("hunt", false, "signature_required = true");
  assertEquals(allowed, false);
});

Deno.test("checkHuntPermission denied when no signature declaration", () => {
  const [allowed, _msg] = checkHuntPermission("full", true, "leash = 'Hunt");
  assertEquals(allowed, false);
});

// -- summariseContractile --

Deno.test("summariseContractile produces summary string", () => {
  const contractile = {
    path: "/path/to/file.k9.ncl",
    name: "test",
    securityLevel: "Kennel",
    isValid: true,
    errors: [],
  };
  const summary = summariseContractile(contractile);
  assertEquals(summary.includes("test"), true);
  assertEquals(summary.includes("Kennel"), true);
  assertEquals(summary.includes("Valid"), true);
});
