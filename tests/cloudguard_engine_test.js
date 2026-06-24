// SPDX-License-Identifier: MPL-2.0

/**
 * CloudGuardEngine Tests — plan parsing, DNS record types, setting value
 * helpers, compliance scoring, zone filtering, severity helpers, exception
 * logic, and finding sort order.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  parsePlanTier,
  parseDnsRecordType,
  dnsRecordTypeLabel,
  jsonStr,
  jsonBool,
  jsonStrArray,
  parseZone,
  parseZonesJson,
  parseSettingValue,
  settingIdToCategory,
  parseSetting,
  parseSettingsJson,
  parseDnsRecord,
  parseDnsRecordsJson,
  serialiseModifiedSettings,
  settingValueToString,
  isSettingEnabled,
  evaluateSetting,
  computeComplianceScore,
  filterZones,
  sortZonesByName,
  checkEmailSecurityRecords,
  countRecordsByType,
  severityLabel,
  severityColour,
  findException,
  hasException,
  exceptionsForDomain,
  exceptionsForSetting,
  applyException,
  sortFindingsBySeverity,
} from "../src/core/CloudGuardEngine.res.js";

// -- parsePlanTier --

Deno.test("parsePlanTier parses enterprise tier", () => {
  assertEquals(parsePlanTier("Enterprise"), "Enterprise");
  assertEquals(parsePlanTier("enterprise plan"), "Enterprise");
});

Deno.test("parsePlanTier parses business tier", () => {
  assertEquals(parsePlanTier("Business"), "Business");
  assertEquals(parsePlanTier("business Plus"), "Business");
});

Deno.test("parsePlanTier parses pro tier", () => {
  assertEquals(parsePlanTier("Pro"), "Pro");
  assertEquals(parsePlanTier("professional"), "Pro");
});

Deno.test("parsePlanTier defaults to Free for unknown", () => {
  assertEquals(parsePlanTier("Free"), "Free");
  assertEquals(parsePlanTier("something else"), "Free");
  assertEquals(parsePlanTier(""), "Free");
});

// -- parseDnsRecordType --

Deno.test("parseDnsRecordType parses all 13 DNS record types", () => {
  assertEquals(parseDnsRecordType("A"), "A");
  assertEquals(parseDnsRecordType("AAAA"), "AAAA");
  assertEquals(parseDnsRecordType("CNAME"), "CNAME");
  assertEquals(parseDnsRecordType("MX"), "MX");
  assertEquals(parseDnsRecordType("TXT"), "TXT");
  assertEquals(parseDnsRecordType("SRV"), "SRV");
  assertEquals(parseDnsRecordType("NS"), "NS");
  assertEquals(parseDnsRecordType("CAA"), "CAA");
  assertEquals(parseDnsRecordType("TLSA"), "TLSA");
  assertEquals(parseDnsRecordType("HTTPS"), "HTTPS");
  assertEquals(parseDnsRecordType("SVCB"), "SVCB");
  assertEquals(parseDnsRecordType("PTR"), "PTR");
  assertEquals(parseDnsRecordType("LOC"), "LOC");
});

Deno.test("parseDnsRecordType is case-insensitive", () => {
  assertEquals(parseDnsRecordType("a"), "A");
  assertEquals(parseDnsRecordType("cname"), "CNAME");
  assertEquals(parseDnsRecordType("txt"), "TXT");
});

Deno.test("parseDnsRecordType returns undefined for unknown type", () => {
  assertEquals(parseDnsRecordType("UNKNOWN"), undefined);
  assertEquals(parseDnsRecordType(""), undefined);
});

// -- dnsRecordTypeLabel --

Deno.test("dnsRecordTypeLabel returns string labels for all types", () => {
  assertEquals(dnsRecordTypeLabel("A"), "A");
  assertEquals(dnsRecordTypeLabel("AAAA"), "AAAA");
  assertEquals(dnsRecordTypeLabel("CNAME"), "CNAME");
  assertEquals(dnsRecordTypeLabel("MX"), "MX");
  assertEquals(dnsRecordTypeLabel("TXT"), "TXT");
  assertEquals(dnsRecordTypeLabel("SRV"), "SRV");
  assertEquals(dnsRecordTypeLabel("NS"), "NS");
  assertEquals(dnsRecordTypeLabel("CAA"), "CAA");
  assertEquals(dnsRecordTypeLabel("TLSA"), "TLSA");
  assertEquals(dnsRecordTypeLabel("HTTPS"), "HTTPS");
  assertEquals(dnsRecordTypeLabel("SVCB"), "SVCB");
  assertEquals(dnsRecordTypeLabel("PTR"), "PTR");
  assertEquals(dnsRecordTypeLabel("LOC"), "LOC");
});

// -- jsonStr --

Deno.test("jsonStr extracts string from dict", () => {
  const obj = { name: "test" };
  assertEquals(jsonStr(obj, "name", "fallback"), "test");
});

Deno.test("jsonStr returns default when key missing", () => {
  const obj = {};
  assertEquals(jsonStr(obj, "name", "fallback"), "fallback");
});

Deno.test("jsonStr returns default when value is not a string", () => {
  const obj = { name: 42 };
  assertEquals(jsonStr(obj, "name", "fallback"), "fallback");
});

// -- jsonBool --

Deno.test("jsonBool extracts boolean from dict", () => {
  const obj = { active: true };
  assertEquals(jsonBool(obj, "active", false), true);
});

Deno.test("jsonBool returns default when key missing", () => {
  const obj = {};
  assertEquals(jsonBool(obj, "active", true), true);
});

Deno.test("jsonBool returns default when value is not a boolean", () => {
  const obj = { active: "yes" };
  assertEquals(jsonBool(obj, "active", false), false);
});

// -- jsonStrArray --

Deno.test("jsonStrArray extracts string array from dict", () => {
  const obj = { tags: ["a", "b", "c"] };
  assertEquals(jsonStrArray(obj, "tags"), ["a", "b", "c"]);
});

Deno.test("jsonStrArray returns empty array when key missing", () => {
  const obj = {};
  assertEquals(jsonStrArray(obj, "tags"), []);
});

Deno.test("jsonStrArray filters non-string elements", () => {
  const obj = { tags: ["a", 42, "b", null] };
  assertEquals(jsonStrArray(obj, "tags"), ["a", "b"]);
});

// -- parseZone --

Deno.test("parseZone parses a valid zone object", () => {
  const json = { id: "zone1", name: "example.com", status: "active", paused: false, name_servers: ["ns1.cf.com"] };
  const zone = parseZone(json);
  assert(zone !== undefined);
  assertEquals(zone.id, "zone1");
  assertEquals(zone.name, "example.com");
  assertEquals(zone.status, "active");
  assertEquals(zone.paused, false);
});

Deno.test("parseZone returns undefined for empty id or name", () => {
  assertEquals(parseZone({ id: "", name: "example.com" }), undefined);
  assertEquals(parseZone({ id: "z1", name: "" }), undefined);
});

Deno.test("parseZone returns undefined for non-object", () => {
  assertEquals(parseZone("not an object"), undefined);
  assertEquals(parseZone(42), undefined);
});

Deno.test("parseZone extracts plan tier from nested plan object", () => {
  const json = { id: "z1", name: "example.com", plan: { name: "Business Plus" } };
  const zone = parseZone(json);
  assert(zone !== undefined);
  assertEquals(zone.plan, "Business");
});

// -- parseZonesJson --

Deno.test("parseZonesJson parses a JSON array of zones", () => {
  const json = JSON.stringify([
    { id: "z1", name: "a.com" },
    { id: "z2", name: "b.com" },
  ]);
  const zones = parseZonesJson(json);
  assertEquals(zones.length, 2);
});

Deno.test("parseZonesJson handles CF API envelope", () => {
  const json = JSON.stringify({
    result: [{ id: "z1", name: "a.com" }],
    success: true,
  });
  const zones = parseZonesJson(json);
  assertEquals(zones.length, 1);
  assertEquals(zones[0].name, "a.com");
});

Deno.test("parseZonesJson returns empty for invalid JSON", () => {
  assertEquals(parseZonesJson("not json"), []);
  assertEquals(parseZonesJson(""), []);
});

// -- parseSettingValue --

Deno.test("parseSettingValue parses string values", () => {
  const v = parseSettingValue("on");
  assertEquals(v.TAG, "StringValue");
  assertEquals(v._0, "on");
});

Deno.test("parseSettingValue parses boolean values", () => {
  const v = parseSettingValue(true);
  assertEquals(v.TAG, "BoolValue");
  assertEquals(v._0, true);
});

Deno.test("parseSettingValue parses number values", () => {
  const v = parseSettingValue(42);
  assertEquals(v.TAG, "IntValue");
  assertEquals(v._0, 42);
});

Deno.test("parseSettingValue parses null as empty string", () => {
  const v = parseSettingValue(null);
  assertEquals(v.TAG, "StringValue");
  assertEquals(v._0, "");
});

// -- settingIdToCategory (heuristic fallback) --

Deno.test("settingIdToCategory maps ssl-related IDs to SslTls", () => {
  assertEquals(settingIdToCategory("always_use_https"), "SslTls");
});

Deno.test("settingIdToCategory maps security-related IDs to Waf", () => {
  assertEquals(settingIdToCategory("waf_custom_rule"), "Waf");
  assertEquals(settingIdToCategory("browser_check"), "Waf");
});

Deno.test("settingIdToCategory maps cache-related IDs to Performance", () => {
  assertEquals(settingIdToCategory("cache_level"), "Performance");
  assertEquals(settingIdToCategory("brotli"), "Performance");
});

Deno.test("settingIdToCategory maps network-related IDs to Network", () => {
  assertEquals(settingIdToCategory("ip_geolocation"), "Network");
  assertEquals(settingIdToCategory("websocket"), "Network");
});

Deno.test("settingIdToCategory defaults to SslTls for unknown IDs", () => {
  assertEquals(settingIdToCategory("completely_unknown_setting_xyz_123"), "SslTls");
});

// -- settingValueToString --

Deno.test("settingValueToString converts BoolValue to On/Off", () => {
  assertEquals(settingValueToString({ TAG: "BoolValue", _0: true }), "On");
  assertEquals(settingValueToString({ TAG: "BoolValue", _0: false }), "Off");
});

Deno.test("settingValueToString converts StringValue", () => {
  assertEquals(settingValueToString({ TAG: "StringValue", _0: "full" }), "full");
});

Deno.test("settingValueToString converts IntValue", () => {
  assertEquals(settingValueToString({ TAG: "IntValue", _0: 100 }), "100");
});

Deno.test("settingValueToString converts ObjectValue", () => {
  assertEquals(settingValueToString({ TAG: "ObjectValue", _0: '{"a":1}' }), '{"a":1}');
});

// -- isSettingEnabled --

Deno.test("isSettingEnabled checks BoolValue", () => {
  assertEquals(isSettingEnabled({ TAG: "BoolValue", _0: true }), true);
  assertEquals(isSettingEnabled({ TAG: "BoolValue", _0: false }), false);
});

Deno.test("isSettingEnabled checks StringValue on/true/1", () => {
  assertEquals(isSettingEnabled({ TAG: "StringValue", _0: "on" }), true);
  assertEquals(isSettingEnabled({ TAG: "StringValue", _0: "true" }), true);
  assertEquals(isSettingEnabled({ TAG: "StringValue", _0: "1" }), true);
  assertEquals(isSettingEnabled({ TAG: "StringValue", _0: "off" }), false);
});

Deno.test("isSettingEnabled checks IntValue > 0", () => {
  assertEquals(isSettingEnabled({ TAG: "IntValue", _0: 1 }), true);
  assertEquals(isSettingEnabled({ TAG: "IntValue", _0: 0 }), false);
});

Deno.test("isSettingEnabled treats ObjectValue as enabled", () => {
  assertEquals(isSettingEnabled({ TAG: "ObjectValue", _0: "{}" }), true);
});

// -- serialiseModifiedSettings --

Deno.test("serialiseModifiedSettings produces JSON for modified settings only", () => {
  const settings = [
    { id: "ssl", value: { TAG: "BoolValue", _0: true }, modified: true },
    { id: "cache", value: { TAG: "StringValue", _0: "full" }, modified: false },
    { id: "minify", value: { TAG: "IntValue", _0: 5 }, modified: true },
  ];
  const result = serialiseModifiedSettings(settings);
  assert(result.includes('"ssl"'));
  assert(result.includes('"on"'));
  assert(result.includes('"minify"'));
  assert(!result.includes('"cache"'));
});

Deno.test("serialiseModifiedSettings returns empty array for no modifications", () => {
  const settings = [{ id: "ssl", value: { TAG: "BoolValue", _0: true }, modified: false }];
  assertEquals(serialiseModifiedSettings(settings), "[]");
});

// -- evaluateSetting --

Deno.test("evaluateSetting returns undefined when values match", () => {
  const setting = {
    id: "ssl",
    value: { TAG: "BoolValue", _0: true },
    defaultValue: { TAG: "BoolValue", _0: true },
    category: "SslTls",
    editable: true,
  };
  const rule = { id: "ssl", severity: "High", expression: "SSL must be on" };
  assertEquals(evaluateSetting("example.com", setting, rule), undefined);
});

Deno.test("evaluateSetting returns finding when values differ", () => {
  const setting = {
    id: "ssl",
    value: { TAG: "BoolValue", _0: false },
    defaultValue: { TAG: "BoolValue", _0: true },
    category: "SslTls",
    editable: true,
  };
  const rule = { id: "ssl", severity: "High", expression: "SSL must be on" };
  const finding = evaluateSetting("example.com", setting, rule);
  assert(finding !== undefined);
  assertEquals(finding.domain, "example.com");
  assertEquals(finding.settingId, "ssl");
  assertEquals(finding.severity, "High");
  assertEquals(finding.autoFixable, true);
});

// -- computeComplianceScore --

Deno.test("computeComplianceScore returns perfect score when all pass", () => {
  const settings = [
    { id: "s1", value: { TAG: "BoolValue", _0: true }, defaultValue: { TAG: "BoolValue", _0: true } },
  ];
  const constraints = [{ id: "s1" }];
  const [passed, failed, score] = computeComplianceScore(settings, constraints);
  assertEquals(passed, 1);
  assertEquals(failed, 0);
  assertEquals(score, 1.0);
});

Deno.test("computeComplianceScore counts failures for missing settings", () => {
  const settings = [];
  const constraints = [{ id: "s1" }];
  const [passed, failed, _score] = computeComplianceScore(settings, constraints);
  assertEquals(passed, 0);
  assertEquals(failed, 1);
});

Deno.test("computeComplianceScore returns 0 for empty constraints", () => {
  const [passed, failed, score] = computeComplianceScore([], []);
  assertEquals(passed, 0);
  assertEquals(failed, 0);
  assertEquals(score, 0.0);
});

// -- filterZones --

Deno.test("filterZones returns all zones for empty search", () => {
  const zones = [{ name: "a.com" }, { name: "b.com" }];
  assertEquals(filterZones(zones, "").length, 2);
});

Deno.test("filterZones filters by domain name", () => {
  const zones = [{ name: "example.com" }, { name: "test.org" }];
  const result = filterZones(zones, "example");
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "example.com");
});

Deno.test("filterZones is case-insensitive", () => {
  const zones = [{ name: "Example.COM" }];
  assertEquals(filterZones(zones, "example").length, 1);
});

// -- sortZonesByName --

Deno.test("sortZonesByName sorts alphabetically", () => {
  const zones = [{ name: "c.com" }, { name: "a.com" }, { name: "b.com" }];
  const sorted = sortZonesByName(zones);
  assertEquals(sorted[0].name, "a.com");
  assertEquals(sorted[1].name, "b.com");
  assertEquals(sorted[2].name, "c.com");
});

Deno.test("sortZonesByName does not mutate original", () => {
  const zones = [{ name: "b.com" }, { name: "a.com" }];
  sortZonesByName(zones);
  assertEquals(zones[0].name, "b.com");
});

// -- checkEmailSecurityRecords --

Deno.test("checkEmailSecurityRecords reports all missing when empty", () => {
  const missing = checkEmailSecurityRecords([]);
  assertEquals(missing.length, 3);
  assert(missing.some(m => m.includes("SPF")));
  assert(missing.some(m => m.includes("DMARC")));
  assert(missing.some(m => m.includes("CAA")));
});

Deno.test("checkEmailSecurityRecords passes with correct records present", () => {
  const records = [
    { recordType: "TXT", content: "v=spf1 include:example.com ~all", name: "example.com" },
    { recordType: "TXT", content: "v=DMARC1; p=reject", name: "_dmarc.example.com" },
    { recordType: "CAA", content: "letsencrypt.org", name: "example.com" },
  ];
  const missing = checkEmailSecurityRecords(records);
  assertEquals(missing.length, 0);
});

// -- countRecordsByType --

Deno.test("countRecordsByType counts records by type label", () => {
  const records = [
    { recordType: "A" },
    { recordType: "A" },
    { recordType: "CNAME" },
  ];
  const counts = countRecordsByType(records);
  const aCount = counts.find(([k, _]) => k === "A");
  const cnameCount = counts.find(([k, _]) => k === "CNAME");
  assert(aCount !== undefined);
  assertEquals(aCount[1], 2);
  assert(cnameCount !== undefined);
  assertEquals(cnameCount[1], 1);
});

Deno.test("countRecordsByType returns empty for no records", () => {
  assertEquals(countRecordsByType([]).length, 0);
});

// -- severityLabel --

Deno.test("severityLabel returns uppercase labels", () => {
  assertEquals(severityLabel("Critical"), "CRITICAL");
  assertEquals(severityLabel("High"), "HIGH");
  assertEquals(severityLabel("Medium"), "MEDIUM");
  assertEquals(severityLabel("Low"), "LOW");
  assertEquals(severityLabel("Info"), "INFO");
});

// -- severityColour --

Deno.test("severityColour returns Tailwind classes", () => {
  assertEquals(severityColour("Critical"), "text-red-400");
  assertEquals(severityColour("High"), "text-orange-400");
  assertEquals(severityColour("Medium"), "text-yellow-400");
  assertEquals(severityColour("Low"), "text-blue-400");
  assertEquals(severityColour("Info"), "text-gray-400");
});

// -- findException --

Deno.test("findException returns matching exception", () => {
  const exceptions = [
    { domain: "a.com", settingId: "ssl", overrideValue: { TAG: "BoolValue", _0: false } },
    { domain: "b.com", settingId: "ssl", overrideValue: { TAG: "BoolValue", _0: true } },
  ];
  const found = findException(exceptions, "a.com", "ssl");
  assert(found !== undefined);
  assertEquals(found.domain, "a.com");
});

Deno.test("findException returns undefined when not found", () => {
  const exceptions = [{ domain: "a.com", settingId: "ssl" }];
  assertEquals(findException(exceptions, "b.com", "ssl"), undefined);
});

// -- hasException --

Deno.test("hasException returns true when exception exists", () => {
  const exceptions = [{ domain: "a.com", settingId: "ssl" }];
  assertEquals(hasException(exceptions, "a.com", "ssl"), true);
});

Deno.test("hasException returns false when no match", () => {
  const exceptions = [{ domain: "a.com", settingId: "ssl" }];
  assertEquals(hasException(exceptions, "a.com", "cache"), false);
});

// -- exceptionsForDomain --

Deno.test("exceptionsForDomain returns all exceptions for a domain", () => {
  const exceptions = [
    { domain: "a.com", settingId: "ssl" },
    { domain: "a.com", settingId: "cache" },
    { domain: "b.com", settingId: "ssl" },
  ];
  assertEquals(exceptionsForDomain(exceptions, "a.com").length, 2);
});

// -- exceptionsForSetting --

Deno.test("exceptionsForSetting returns all exceptions for a setting", () => {
  const exceptions = [
    { domain: "a.com", settingId: "ssl" },
    { domain: "b.com", settingId: "ssl" },
    { domain: "c.com", settingId: "cache" },
  ];
  assertEquals(exceptionsForSetting(exceptions, "ssl").length, 2);
});

// -- applyException --

Deno.test("applyException applies override value when exception exists", () => {
  const setting = { id: "ssl", value: { TAG: "BoolValue", _0: true }, modified: false };
  const exceptions = [{ domain: "a.com", settingId: "ssl", overrideValue: { TAG: "BoolValue", _0: false } }];
  const result = applyException(setting, exceptions, "a.com");
  assertEquals(result.value.TAG, "BoolValue");
  assertEquals(result.value._0, false);
  assertEquals(result.modified, true);
});

Deno.test("applyException returns setting unchanged when no exception", () => {
  const setting = { id: "ssl", value: { TAG: "BoolValue", _0: true }, modified: false };
  const result = applyException(setting, [], "a.com");
  assertEquals(result.value._0, true);
  assertEquals(result.modified, false);
});

// -- sortFindingsBySeverity --

Deno.test("sortFindingsBySeverity orders Critical first, Info last", () => {
  const findings = [
    { severity: "Info", settingId: "a" },
    { severity: "Critical", settingId: "b" },
    { severity: "Medium", settingId: "c" },
    { severity: "High", settingId: "d" },
    { severity: "Low", settingId: "e" },
  ];
  const sorted = sortFindingsBySeverity(findings);
  assertEquals(sorted[0].severity, "Critical");
  assertEquals(sorted[1].severity, "High");
  assertEquals(sorted[2].severity, "Medium");
  assertEquals(sorted[3].severity, "Low");
  assertEquals(sorted[4].severity, "Info");
});

Deno.test("sortFindingsBySeverity does not mutate original", () => {
  const findings = [
    { severity: "Low", settingId: "a" },
    { severity: "Critical", settingId: "b" },
  ];
  sortFindingsBySeverity(findings);
  assertEquals(findings[0].severity, "Low");
});
