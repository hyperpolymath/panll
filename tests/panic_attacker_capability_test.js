// SPDX-License-Identifier: PMPL-1.0-or-later

import { assertEquals } from "jsr:@std/assert";
import { parse } from "../src/core/PanicAttackerCapability.res.js";

Deno.test("PanicAttackerCapability.parse - accepts full payload", () => {
  const payload = JSON.stringify({
    mode: "full",
    supports_panll: true,
    supports_ambush: true,
    binary: "/var/mnt/eclipse/repos/panic-attacker/target/debug/panic-attack",
    detail: "panic-attack panll export is available"
  });

  const result = parse(payload);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.mode, "full");
  assertEquals(
    result._0.binary,
    "/var/mnt/eclipse/repos/panic-attacker/target/debug/panic-attack"
  );
  assertEquals(result._0.detail, "panic-attack panll export is available");
});

Deno.test("PanicAttackerCapability.parse - defaults mode when omitted", () => {
  const payload = JSON.stringify({
    detail: "missing mode field"
  });

  const result = parse(payload);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.mode, "unavailable");
  assertEquals(result._0.binary, undefined);
  assertEquals(result._0.detail, "missing mode field");
});

Deno.test("PanicAttackerCapability.parse - rejects malformed JSON", () => {
  const result = parse("{bad json");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

