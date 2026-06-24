// SPDX-License-Identifier: MPL-2.0

/**
 * CloudGuard Sub-panels Tests — settings grid data, policy catalog entries,
 * DNS defaults, category counts, plan availability filtering, and catalog
 * lookup helpers.
 */

import { assertEquals, assert, assertExists } from "jsr:@std/assert";
import {
  allSettings,
  findById,
  byCategory,
  availableOnPlan,
  categoryCounts,
  categoryLabel,
  planLabel,
  sslTlsSettings,
  wafSettings,
  performanceSettings,
  networkSettings,
  dnsInfoSettings,
  emailSecSettings,
  pagesSettings,
  dnssecSettings,
} from "../src/core/CloudGuardCatalog.res.js";
import {
  defaultConstraints,
  enabledConstraints,
  constraintsByCategory,
  findConstraint,
} from "../src/core/CloudGuardPolicy.res.js";
import {
  settingIdToCategory,
  severityLabel,
  severityColour,
  parsePlanTier,
  dnsRecordTypeLabel,
} from "../src/core/CloudGuardEngine.res.js";

// -- CloudGuardCatalog: settings grid data --

Deno.test("allSettings contains entries from all categories", () => {
  assert(allSettings.length > 30, "Expected at least 30 settings across all categories");
});

Deno.test("findById returns SSL setting for 'ssl'", () => {
  const entry = findById("ssl");
  assertExists(entry);
  assertEquals(entry.id, "ssl");
  assertEquals(entry.category, "SslTls");
  assertEquals(entry.label, "SSL Mode");
});

Deno.test("findById returns undefined for unknown id", () => {
  const entry = findById("nonexistent_setting_xyz");
  assertEquals(entry, undefined);
});

Deno.test("byCategory returns only SslTls settings", () => {
  const sslSettings = byCategory("SslTls");
  assert(sslSettings.length > 0);
  for (const s of sslSettings) {
    assertEquals(s.category, "SslTls");
  }
});

Deno.test("byCategory Waf returns WAF settings", () => {
  const waf = byCategory("Waf");
  assert(waf.length > 0);
  const ids = waf.map(s => s.id);
  assert(ids.includes("browser_check"));
});

Deno.test("categoryCounts returns 10 categories", () => {
  const counts = categoryCounts();
  assertEquals(counts.length, 10);
  const catNames = counts.map(c => c[0]);
  assert(catNames.includes("SslTls"));
  assert(catNames.includes("Waf"));
  assert(catNames.includes("Performance"));
  assert(catNames.includes("Network"));
});

Deno.test("categoryLabel maps known categories", () => {
  assertEquals(categoryLabel("SslTls"), "SSL/TLS");
  assertEquals(categoryLabel("Waf"), "WAF");
  assertEquals(categoryLabel("Performance"), "Performance");
  assertEquals(categoryLabel("Dns"), "DNS");
  assertEquals(categoryLabel("Dnssec"), "DNSSEC");
  assertEquals(categoryLabel("EmailSec"), "Email Security");
  assertEquals(categoryLabel("BotDefense"), "Bot Defense");
});

Deno.test("planLabel maps all tiers", () => {
  assertEquals(planLabel("Free"), "Free");
  assertEquals(planLabel("Pro"), "Pro");
  assertEquals(planLabel("Business"), "Business");
  assertEquals(planLabel("Enterprise"), "Enterprise");
});

// -- Plan availability filtering --

Deno.test("availableOnPlan Enterprise returns all settings", () => {
  const all = availableOnPlan("Enterprise");
  assertEquals(all.length, allSettings.length);
});

Deno.test("availableOnPlan Free excludes Pro-only settings", () => {
  const free = availableOnPlan("Free");
  const enterprise = availableOnPlan("Enterprise");
  assert(free.length < enterprise.length, "Free plan should have fewer settings than Enterprise");
});

// -- DNS defaults --

Deno.test("dnsInfoSettings contains cname_flattening", () => {
  const ids = dnsInfoSettings.map(s => s.id);
  assert(ids.includes("cname_flattening"));
});

Deno.test("sslTlsSettings default for ssl is full_strict", () => {
  const ssl = sslTlsSettings.find(s => s.id === "ssl");
  assertExists(ssl);
  assertEquals(ssl.defaultValue._0, "full_strict");
});

// -- Policy catalog entries --

Deno.test("defaultConstraints contains critical SSL rules", () => {
  const sslRule = defaultConstraints.find(c => c.id === "ssl");
  assertExists(sslRule);
  assertEquals(sslRule.severity, "Critical");
  assertEquals(sslRule.category, "SslTls");
});

Deno.test("enabledConstraints returns only enabled rules", () => {
  const enabled = enabledConstraints();
  for (const c of enabled) {
    assert(c.enabled);
  }
});

Deno.test("constraintsByCategory SslTls returns SSL constraints", () => {
  const sslConstraints = constraintsByCategory("SslTls");
  assert(sslConstraints.length > 0);
  for (const c of sslConstraints) {
    assertEquals(c.category, "SslTls");
  }
});

Deno.test("findConstraint returns matching constraint", () => {
  const rule = findConstraint("always_use_https");
  assertExists(rule);
  assertEquals(rule.severity, "Critical");
});

// -- Engine helpers used by sub-panels --

Deno.test("settingIdToCategory maps ssl-related ids to SslTls", () => {
  assertEquals(settingIdToCategory("ssl"), "SslTls");
  assertEquals(settingIdToCategory("always_use_https"), "SslTls");
});

Deno.test("severityLabel maps all severity levels", () => {
  assertEquals(severityLabel("Critical"), "CRITICAL");
  assertEquals(severityLabel("High"), "HIGH");
  assertEquals(severityLabel("Medium"), "MEDIUM");
  assertEquals(severityLabel("Low"), "LOW");
  assertEquals(severityLabel("Info"), "INFO");
});

Deno.test("severityColour returns Tailwind classes", () => {
  assert(severityColour("Critical").includes("red"));
  assert(severityColour("High").includes("orange"));
  assert(severityColour("Info").includes("gray"));
});
