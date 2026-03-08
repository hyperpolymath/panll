// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * VabEngine Tests — dependency checking, capability computation, warning
 * counting, warning labels, warning severity, and capability categories.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  checkDependencies,
  capabilityCategories,
  computeCapabilities,
  countWarnings,
  warningLabel,
  warningSeverity,
} from "../src/core/VabEngine.res.js";

// -- capabilityCategories --

Deno.test("capabilityCategories has expected number of entries", () => {
  assert(capabilityCategories.length >= 19, `Expected at least 19 categories, got ${capabilityCategories.length}`);
});

Deno.test("capabilityCategories entries are [name, tags] tuples", () => {
  for (const entry of capabilityCategories) {
    assert(Array.isArray(entry), "Entry should be an array");
    assertEquals(entry.length, 2, "Entry should have 2 elements");
    assert(typeof entry[0] === "string", "First element should be a string name");
    assert(Array.isArray(entry[1]), "Second element should be an array of tags");
    assert(entry[1].length > 0, `Tags for ${entry[0]} should not be empty`);
  }
});

Deno.test("capabilityCategories includes HTTP serving", () => {
  const http = capabilityCategories.find(([name, _]) => name === "HTTP serving");
  assert(http !== undefined);
  assert(http[1].includes("http"));
});

Deno.test("capabilityCategories includes Encryption (TLS)", () => {
  const tls = capabilityCategories.find(([name, _]) => name === "Encryption (TLS)");
  assert(tls !== undefined);
  assert(tls[1].includes("tls"));
});

Deno.test("capabilityCategories includes AI / neurosymbolic", () => {
  const ai = capabilityCategories.find(([name, _]) => name === "AI / neurosymbolic");
  assert(ai !== undefined);
  assert(ai[1].includes("neurosymbolic"));
});

// -- countWarnings --

Deno.test("countWarnings counts required, recommended, and security warnings", () => {
  const warnings = [
    { TAG: "MissingRequired", _0: "a", _1: "b" },
    { TAG: "MissingRequired", _0: "c", _1: "d" },
    { TAG: "MissingRecommended", _0: "e", _1: "f" },
    { TAG: "SecurityWarning", _0: "msg" },
    { TAG: "PortConflict", _0: 80, _1: "a", _2: "b" },
  ];
  const [required, recommended, security] = countWarnings(warnings);
  assertEquals(required, 3);  // 2 MissingRequired + 1 PortConflict
  assertEquals(recommended, 1);
  assertEquals(security, 1);
});

Deno.test("countWarnings returns zeros for empty array", () => {
  const [required, recommended, security] = countWarnings([]);
  assertEquals(required, 0);
  assertEquals(recommended, 0);
  assertEquals(security, 0);
});

// -- warningSeverity --

Deno.test("warningSeverity returns error for MissingRequired", () => {
  assertEquals(warningSeverity({ TAG: "MissingRequired", _0: "a", _1: "b" }), "error");
});

Deno.test("warningSeverity returns error for PortConflict", () => {
  assertEquals(warningSeverity({ TAG: "PortConflict", _0: 80, _1: "a", _2: "b" }), "error");
});

Deno.test("warningSeverity returns warning for SecurityWarning", () => {
  assertEquals(warningSeverity({ TAG: "SecurityWarning", _0: "msg" }), "warning");
});

Deno.test("warningSeverity returns info for MissingRecommended", () => {
  assertEquals(warningSeverity({ TAG: "MissingRecommended", _0: "a", _1: "b" }), "info");
});

// -- warningLabel --

Deno.test("warningLabel formats MissingRequired with catalog names", () => {
  const catalog = [
    { id: "proven-http", name: "HTTP Server" },
    { id: "proven-tls", name: "TLS Engine" },
  ];
  const label = warningLabel({ TAG: "MissingRequired", _0: "proven-http", _1: "proven-tls" }, catalog);
  assertEquals(label, "HTTP Server requires TLS Engine");
});

Deno.test("warningLabel falls back to ID when not in catalog", () => {
  const label = warningLabel({ TAG: "MissingRequired", _0: "unknown-a", _1: "unknown-b" }, []);
  assertEquals(label, "unknown-a requires unknown-b");
});

Deno.test("warningLabel formats MissingRecommended", () => {
  const label = warningLabel({ TAG: "MissingRecommended", _0: "comp-a", _1: "comp-b" }, []);
  assertEquals(label, "comp-a recommends comp-b");
});

Deno.test("warningLabel returns message for SecurityWarning", () => {
  const msg = "No audit logger detected";
  assertEquals(warningLabel({ TAG: "SecurityWarning", _0: msg }, []), msg);
});

Deno.test("warningLabel formats PortConflict", () => {
  const catalog = [
    { id: "comp-a", name: "Service A" },
    { id: "comp-b", name: "Service B" },
  ];
  const label = warningLabel({ TAG: "PortConflict", _0: 443, _1: "comp-a", _2: "comp-b" }, catalog);
  assertEquals(label, "Port 443 conflict: Service A vs Service B");
});

// -- checkDependencies --

Deno.test("checkDependencies returns empty for empty assembly", () => {
  const warnings = checkDependencies([], []);
  assertEquals(warnings.length, 0);
});

Deno.test("checkDependencies reports missing required dependency", () => {
  const catalog = [
    { id: "http", name: "HTTP", dependencies: ["tls"], softDependencies: [], ports: [], capabilities: [] },
    { id: "tls", name: "TLS", dependencies: [], softDependencies: [], ports: [], capabilities: [] },
  ];
  const warnings = checkDependencies(["http"], catalog);
  assert(warnings.length >= 1);
  const missing = warnings.find(w => w.TAG === "MissingRequired");
  assert(missing !== undefined);
  assertEquals(missing._0, "http");
  assertEquals(missing._1, "tls");
});

Deno.test("checkDependencies no warning when dependency present", () => {
  const catalog = [
    { id: "http", name: "HTTP", dependencies: ["tls"], softDependencies: [], ports: [], capabilities: [] },
    { id: "tls", name: "TLS", dependencies: [], softDependencies: [], ports: [], capabilities: [] },
  ];
  const warnings = checkDependencies(["http", "tls"], catalog);
  const missing = warnings.filter(w => w.TAG === "MissingRequired");
  assertEquals(missing.length, 0);
});

Deno.test("checkDependencies reports missing soft dependency", () => {
  const catalog = [
    { id: "http", name: "HTTP", dependencies: [], softDependencies: ["cache"], ports: [], capabilities: [] },
  ];
  const warnings = checkDependencies(["http"], catalog);
  const recommended = warnings.find(w => w.TAG === "MissingRecommended");
  assert(recommended !== undefined);
  assertEquals(recommended._0, "http");
  assertEquals(recommended._1, "cache");
});

Deno.test("checkDependencies reports port conflicts", () => {
  const catalog = [
    { id: "svc-a", name: "A", dependencies: [], softDependencies: [], ports: [80], capabilities: [] },
    { id: "svc-b", name: "B", dependencies: [], softDependencies: [], ports: [80], capabilities: [] },
  ];
  const warnings = checkDependencies(["svc-a", "svc-b"], catalog);
  const conflict = warnings.find(w => w.TAG === "PortConflict");
  assert(conflict !== undefined);
  assertEquals(conflict._0, 80);
});

Deno.test("checkDependencies reports security warnings for 3+ components without audit", () => {
  const catalog = [
    { id: "a", name: "A", dependencies: [], softDependencies: [], ports: [], capabilities: [] },
    { id: "b", name: "B", dependencies: [], softDependencies: [], ports: [], capabilities: [] },
    { id: "c", name: "C", dependencies: [], softDependencies: [], ports: [], capabilities: [] },
  ];
  const warnings = checkDependencies(["a", "b", "c"], catalog);
  const security = warnings.filter(w => w.TAG === "SecurityWarning");
  assert(security.length >= 1);
  assert(security.some(w => w._0.includes("audit")));
});

Deno.test("checkDependencies reports security warning for TLS ports without TLS engine", () => {
  const catalog = [
    { id: "a", name: "A", dependencies: [], softDependencies: [], ports: [443], capabilities: [] },
  ];
  const warnings = checkDependencies(["a"], catalog);
  const tlsWarning = warnings.find(w => w.TAG === "SecurityWarning" && w._0.includes("TLS"));
  assert(tlsWarning !== undefined);
});

Deno.test("checkDependencies no TLS warning when TLS engine present", () => {
  const catalog = [
    { id: "a", name: "A", dependencies: [], softDependencies: [], ports: [443], capabilities: [] },
    { id: "proven-tls", name: "TLS", dependencies: [], softDependencies: [], ports: [], capabilities: [] },
  ];
  const warnings = checkDependencies(["a", "proven-tls"], catalog);
  const tlsWarning = warnings.find(w => w.TAG === "SecurityWarning" && w._0.includes("TLS"));
  assertEquals(tlsWarning, undefined);
});

// -- computeCapabilities --

Deno.test("computeCapabilities marks CanDo when capability tag present", () => {
  const catalog = [
    { id: "http-svc", name: "HTTP", dependencies: [], softDependencies: [], ports: [], capabilities: ["http"] },
  ];
  const caps = computeCapabilities(["http-svc"], catalog, []);
  const httpCap = caps.find(c => c._0 === "HTTP serving");
  assert(httpCap !== undefined);
  assertEquals(httpCap.TAG, "CanDo");
});

Deno.test("computeCapabilities marks CannotDo when no tags match", () => {
  const caps = computeCapabilities([], [], []);
  assert(caps.length > 0);
  // All should be CannotDo when no components assembled
  for (const cap of caps) {
    assertEquals(cap.TAG, "CannotDo");
  }
});

Deno.test("computeCapabilities returns one entry per category", () => {
  const caps = computeCapabilities([], [], []);
  assertEquals(caps.length, capabilityCategories.length);
});
