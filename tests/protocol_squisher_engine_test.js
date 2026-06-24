// SPDX-License-Identifier: MPL-2.0

/**
 * ProtocolSquisherEngine Tests — format labels, transport classes, parsing,
 * analysis JSON decoding, IR constraint extraction, and default state.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  formatLabel,
  allFormats,
  transportClassLabel,
  transportClassColour,
  categoryLabel,
  allCategories,
  parseFormat,
  parseTransportClass,
  parseAnalysis,
  extractIrConstraints,
  defaultState,
} from "../src/core/ProtocolSquisherEngine.res.js";

// -- formatLabel --

Deno.test("formatLabel returns correct strings for all formats", () => {
  assertEquals(formatLabel("Protobuf"), "Protobuf");
  assertEquals(formatLabel("Avro"), "Avro");
  assertEquals(formatLabel("FlatBuffers"), "FlatBuffers");
  assertEquals(formatLabel("CapnProto"), "Cap'n Proto");
  assertEquals(formatLabel("Thrift"), "Thrift");
  assertEquals(formatLabel("MessagePack"), "MessagePack");
  assertEquals(formatLabel("Bebop"), "Bebop");
  assertEquals(formatLabel("JsonSchema"), "JSON Schema");
  assertEquals(formatLabel("GraphQL"), "GraphQL");
  assertEquals(formatLabel("Toml"), "TOML");
  assertEquals(formatLabel("RustFormat"), "Rust");
  assertEquals(formatLabel("ReScriptFormat"), "ReScript");
  assertEquals(formatLabel("PythonFormat"), "Python");
});

// -- allFormats --

Deno.test("allFormats has 17 entries", () => {
  assertEquals(allFormats.length, 17);
});

Deno.test("allFormats contains all expected format variants", () => {
  const expected = [
    "Protobuf", "Avro", "FlatBuffers", "CapnProto", "Thrift",
    "MessagePack", "Bebop", "JsonSchema", "GraphQL", "Toml",
    "RustFormat", "ReScriptFormat", "PythonFormat",
    "XMI", "ArchiMateExchange", "BPMN_XML", "SBVR",
  ];
  for (const fmt of expected) {
    assert(allFormats.includes(fmt), `allFormats missing ${fmt}`);
  }
});

// -- transportClassLabel --

Deno.test("transportClassLabel returns correct strings", () => {
  assertEquals(transportClassLabel("Concorde"), "Concorde");
  assertEquals(transportClassLabel("Business"), "Business");
  assertEquals(transportClassLabel("Economy"), "Economy");
  assertEquals(transportClassLabel("Wheelbarrow"), "Wheelbarrow");
});

// -- transportClassColour --

Deno.test("transportClassColour returns Tailwind classes for each class", () => {
  assertEquals(transportClassColour("Concorde"), "text-emerald-400 bg-emerald-900/30");
  assertEquals(transportClassColour("Business"), "text-blue-400 bg-blue-900/30");
  assertEquals(transportClassColour("Economy"), "text-amber-400 bg-amber-900/30");
  assertEquals(transportClassColour("Wheelbarrow"), "text-red-400 bg-red-900/30");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("PsAnalyse"), "Analyse");
  assertEquals(categoryLabel("PsCompare"), "Compare");
  assertEquals(categoryLabel("PsResults"), "Results");
  assertEquals(categoryLabel("PsGuide"), "Guide");
});

// -- allCategories --

Deno.test("allCategories has 4 entries", () => {
  assertEquals(allCategories.length, 4);
});

Deno.test("allCategories contains all expected categories", () => {
  const expected = ["PsAnalyse", "PsCompare", "PsResults", "PsGuide"];
  for (const cat of expected) {
    assert(allCategories.includes(cat), `allCategories missing ${cat}`);
  }
});

// -- parseFormat --

Deno.test("parseFormat parses canonical format names", () => {
  assertEquals(parseFormat("protobuf"), "Protobuf");
  assertEquals(parseFormat("avro"), "Avro");
  assertEquals(parseFormat("flatbuffers"), "FlatBuffers");
  assertEquals(parseFormat("capnproto"), "CapnProto");
  assertEquals(parseFormat("thrift"), "Thrift");
  assertEquals(parseFormat("messagepack"), "MessagePack");
  assertEquals(parseFormat("bebop"), "Bebop");
  assertEquals(parseFormat("graphql"), "GraphQL");
  assertEquals(parseFormat("toml"), "Toml");
  assertEquals(parseFormat("rust"), "RustFormat");
  assertEquals(parseFormat("rescript"), "ReScriptFormat");
  assertEquals(parseFormat("python"), "PythonFormat");
});

Deno.test("parseFormat handles short aliases", () => {
  assertEquals(parseFormat("proto"), "Protobuf");
  assertEquals(parseFormat("flatbuf"), "FlatBuffers");
  assertEquals(parseFormat("capnp"), "CapnProto");
  assertEquals(parseFormat("msgpack"), "MessagePack");
  assertEquals(parseFormat("gql"), "GraphQL");
});

Deno.test("parseFormat handles JSON Schema variants", () => {
  assertEquals(parseFormat("jsonschema"), "JsonSchema");
  assertEquals(parseFormat("json-schema"), "JsonSchema");
  assertEquals(parseFormat("json_schema"), "JsonSchema");
});

Deno.test("parseFormat is case-insensitive", () => {
  assertEquals(parseFormat("PROTOBUF"), "Protobuf");
  assertEquals(parseFormat("Avro"), "Avro");
  assertEquals(parseFormat("GrApHqL"), "GraphQL");
});

Deno.test("parseFormat falls back to JsonSchema for unknown input", () => {
  assertEquals(parseFormat("unknown"), "JsonSchema");
  assertEquals(parseFormat(""), "JsonSchema");
  assertEquals(parseFormat("xml"), "JsonSchema");
});

// -- parseTransportClass --

Deno.test("parseTransportClass parses known classes", () => {
  assertEquals(parseTransportClass("concorde"), "Concorde");
  assertEquals(parseTransportClass("business"), "Business");
  assertEquals(parseTransportClass("economy"), "Economy");
  assertEquals(parseTransportClass("wheelbarrow"), "Wheelbarrow");
});

Deno.test("parseTransportClass is case-insensitive", () => {
  assertEquals(parseTransportClass("CONCORDE"), "Concorde");
  assertEquals(parseTransportClass("Business"), "Business");
  assertEquals(parseTransportClass("WHEELBARROW"), "Wheelbarrow");
});

Deno.test("parseTransportClass falls back to Economy for unknown input", () => {
  assertEquals(parseTransportClass("unknown"), "Economy");
  assertEquals(parseTransportClass(""), "Economy");
  assertEquals(parseTransportClass("first-class"), "Economy");
});

// -- parseAnalysis --

Deno.test("parseAnalysis parses valid JSON with all fields", () => {
  const json = JSON.stringify({
    file_path: "/schemas/user.proto",
    format: "protobuf",
    transport_class: "concorde",
    summary: "Efficient binary format",
    overhead_ratio: 0.85,
    field_count: 12,
    has_recursion: false,
  });
  const result = parseAnalysis(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.filePath, "/schemas/user.proto");
  assertEquals(result._0.format, "Protobuf");
  assertEquals(result._0.transportClass, "Concorde");
  assertEquals(result._0.summary, "Efficient binary format");
  assertEquals(result._0.overheadRatio, 0.85);
  assertEquals(result._0.fieldCount, 12);
  assertEquals(result._0.hasRecursion, false);
});

Deno.test("parseAnalysis handles missing fields with defaults", () => {
  const json = JSON.stringify({});
  const result = parseAnalysis(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.filePath, "");
  assertEquals(result._0.format, "JsonSchema"); // empty string fallback
  assertEquals(result._0.transportClass, "Economy"); // empty string fallback
  assertEquals(result._0.summary, "");
  assertEquals(result._0.overheadRatio, 0.0);
  assertEquals(result._0.fieldCount, 0);
  assertEquals(result._0.hasRecursion, false);
});

Deno.test("parseAnalysis returns Error for invalid JSON", () => {
  const result = parseAnalysis("not valid json {{{");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

Deno.test("parseAnalysis returns Ok with defaults for non-object JSON", () => {
  const result = parseAnalysis('"just a string"');
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.filePath, "");
});

Deno.test("parseAnalysis returns Ok with defaults for JSON array", () => {
  const result = parseAnalysis("[1, 2, 3]");
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.filePath, "");
});

Deno.test("parseAnalysis handles recursion flag true", () => {
  const json = JSON.stringify({
    file_path: "recursive.avro",
    format: "avro",
    transport_class: "wheelbarrow",
    summary: "Has recursive types",
    overhead_ratio: 2.1,
    field_count: 60,
    has_recursion: true,
  });
  const result = parseAnalysis(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.hasRecursion, true);
  assertEquals(result._0.transportClass, "Wheelbarrow");
  assertEquals(result._0.fieldCount, 60);
});

// -- extractIrConstraints --

Deno.test("extractIrConstraints always includes transport class constraint", () => {
  const analysis = {
    filePath: "test.proto",
    format: "Protobuf",
    transportClass: "Concorde",
    summary: "test",
    overheadRatio: 1.0,
    fieldCount: 10,
    hasRecursion: false,
  };
  const constraints = extractIrConstraints(analysis);
  assertEquals(constraints.length, 1);
  assertEquals(constraints[0], "transport_class(test.proto) = Concorde");
});

Deno.test("extractIrConstraints adds overhead constraint when ratio > 1.5", () => {
  const analysis = {
    filePath: "bloated.avro",
    format: "Avro",
    transportClass: "Economy",
    summary: "High overhead",
    overheadRatio: 2.3,
    fieldCount: 10,
    hasRecursion: false,
  };
  const constraints = extractIrConstraints(analysis);
  assertEquals(constraints.length, 2);
  assert(constraints[1].includes("overhead_bound(bloated.avro) <= 1.5"));
  assert(constraints[1].includes("2.3"));
});

Deno.test("extractIrConstraints does not add overhead constraint when ratio <= 1.5", () => {
  const analysis = {
    filePath: "lean.proto",
    format: "Protobuf",
    transportClass: "Concorde",
    summary: "Lean",
    overheadRatio: 1.5,
    fieldCount: 10,
    hasRecursion: false,
  };
  const constraints = extractIrConstraints(analysis);
  assertEquals(constraints.length, 1);
});

Deno.test("extractIrConstraints adds recursion constraint when hasRecursion is true", () => {
  const analysis = {
    filePath: "recursive.thrift",
    format: "Thrift",
    transportClass: "Business",
    summary: "Recursive",
    overheadRatio: 1.0,
    fieldCount: 10,
    hasRecursion: true,
  };
  const constraints = extractIrConstraints(analysis);
  assertEquals(constraints.length, 2);
  assertEquals(constraints[1], "recursion_depth(recursive.thrift) is bounded");
});

Deno.test("extractIrConstraints adds field count constraint when fieldCount > 50", () => {
  const analysis = {
    filePath: "large.gql",
    format: "GraphQL",
    transportClass: "Wheelbarrow",
    summary: "Too many fields",
    overheadRatio: 1.0,
    fieldCount: 75,
    hasRecursion: false,
  };
  const constraints = extractIrConstraints(analysis);
  assertEquals(constraints.length, 2);
  assert(constraints[1].includes("field_count(large.gql) <= 50"));
  assert(constraints[1].includes("75"));
});

Deno.test("extractIrConstraints does not add field count constraint at exactly 50", () => {
  const analysis = {
    filePath: "boundary.proto",
    format: "Protobuf",
    transportClass: "Economy",
    summary: "Boundary",
    overheadRatio: 1.0,
    fieldCount: 50,
    hasRecursion: false,
  };
  const constraints = extractIrConstraints(analysis);
  assertEquals(constraints.length, 1);
});

Deno.test("extractIrConstraints adds all constraints for worst-case schema", () => {
  const analysis = {
    filePath: "worst.msgpack",
    format: "MessagePack",
    transportClass: "Wheelbarrow",
    summary: "Everything wrong",
    overheadRatio: 3.0,
    fieldCount: 100,
    hasRecursion: true,
  };
  const constraints = extractIrConstraints(analysis);
  assertEquals(constraints.length, 4);
  assert(constraints[0].includes("transport_class(worst.msgpack) = Wheelbarrow"));
  assert(constraints[1].includes("overhead_bound"));
  assert(constraints[2].includes("recursion_depth"));
  assert(constraints[3].includes("field_count"));
});

// -- defaultState --

Deno.test("defaultState has expected initial values", () => {
  assertEquals(defaultState.cliAvailable, false);
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.error, undefined);
  assertEquals(defaultState.activeCategory, "PsAnalyse");
  assertEquals(defaultState.analyseInput, "");
  assertEquals(defaultState.compareLeftInput, "");
  assertEquals(defaultState.compareRightInput, "");
  assertEquals(defaultState.lastAnalysis, undefined);
  assertEquals(defaultState.lastComparison, undefined);
  assertEquals(defaultState.analysisHistory.length, 0);
  assertEquals(defaultState.lastTypeCheck, undefined);
  assertEquals(defaultState.irConstraints.length, 0);
  assertEquals(defaultState.transportDisplayActive, false);
});
