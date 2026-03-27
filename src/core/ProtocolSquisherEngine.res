// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Protocol-Squisher Engine — pure computation for format analysis.
///
/// Provides labels, colours, parsing, and display helpers for the view layer.
/// No side effects — all Tauri/CLI interaction is in ProtocolSquisherCmd.

open ProtocolSquisherModel

/// Human-readable label for a schema format.
let formatLabel = (fmt: schemaFormat): string =>
  switch fmt {
  | Protobuf => "Protobuf"
  | Avro => "Avro"
  | FlatBuffers => "FlatBuffers"
  | CapnProto => "Cap'n Proto"
  | Thrift => "Thrift"
  | MessagePack => "MessagePack"
  | Bebop => "Bebop"
  | JsonSchema => "JSON Schema"
  | GraphQL => "GraphQL"
  | Toml => "TOML"
  | RustFormat => "Rust"
  | ReScriptFormat => "ReScript"
  | PythonFormat => "Python"
  | XMI => "XMI (OMG)"
  | ArchiMateExchange => "ArchiMate Exchange"
  | BPMN_XML => "BPMN 2.0 XML"
  | SBVR => "SBVR"
  }

/// All supported formats.
let allFormats: array<schemaFormat> = [
  Protobuf,
  Avro,
  FlatBuffers,
  CapnProto,
  Thrift,
  MessagePack,
  Bebop,
  JsonSchema,
  GraphQL,
  Toml,
  RustFormat,
  ReScriptFormat,
  PythonFormat,
  XMI,
  ArchiMateExchange,
  BPMN_XML,
  SBVR,
]

/// Human-readable label for a transport class.
let transportClassLabel = (tc: transportClass): string =>
  switch tc {
  | Concorde => "Concorde"
  | Business => "Business"
  | Economy => "Economy"
  | Wheelbarrow => "Wheelbarrow"
  }

/// Tailwind colour class for a transport class badge.
let transportClassColour = (tc: transportClass): string =>
  switch tc {
  | Concorde => "text-emerald-400 bg-emerald-900/30"
  | Business => "text-blue-400 bg-blue-900/30"
  | Economy => "text-amber-400 bg-amber-900/30"
  | Wheelbarrow => "text-red-400 bg-red-900/30"
  }

/// Category tab label.
let categoryLabel = (cat: protocolSquisherCategory): string =>
  switch cat {
  | PsAnalyse => "Analyse"
  | PsCompare => "Compare"
  | PsResults => "Results"
  | PsGuide => "Guide"
  }

/// All category tabs.
let allCategories: array<protocolSquisherCategory> = [PsAnalyse, PsCompare, PsResults, PsGuide]

/// Parse a format string from CLI output.
let parseFormat = (s: string): schemaFormat =>
  switch String.toLowerCase(s) {
  | "protobuf" | "proto" => Protobuf
  | "avro" => Avro
  | "flatbuffers" | "flatbuf" => FlatBuffers
  | "capnproto" | "capnp" => CapnProto
  | "thrift" => Thrift
  | "messagepack" | "msgpack" => MessagePack
  | "bebop" => Bebop
  | "jsonschema" | "json-schema" | "json_schema" => JsonSchema
  | "graphql" | "gql" => GraphQL
  | "toml" => Toml
  | "rust" => RustFormat
  | "rescript" => ReScriptFormat
  | "python" => PythonFormat
  | "xmi" | "xml-metadata-interchange" => XMI
  | "archimate" | "archimate-exchange" => ArchiMateExchange
  | "bpmn" | "bpmn-xml" | "bpmn2" => BPMN_XML
  | "sbvr" => SBVR
  | _ => JsonSchema
  }

/// Parse a transport class string from CLI output.
let parseTransportClass = (s: string): transportClass =>
  switch String.toLowerCase(s) {
  | "concorde" => Concorde
  | "business" => Business
  | "economy" => Economy
  | "wheelbarrow" => Wheelbarrow
  | _ => Economy
  }

/// Tea_Json decoder for an analysis result.
let analysisDecoder: Tea_Json.decoder<analysisResult> = {
  open Decoders
  map7(
    (
      filePath,
      formatStr,
      transportStr,
      summary,
      overheadRatio,
      fieldCount,
      hasRecursion,
    ): analysisResult => {
      filePath,
      format: parseFormat(formatStr),
      transportClass: parseTransportClass(transportStr),
      summary,
      overheadRatio,
      fieldCount,
      hasRecursion,
    },
    stringField("file_path"),
    stringField("format"),
    stringField("transport_class"),
    stringField("summary"),
    floatField("overhead_ratio"),
    intField("field_count"),
    boolField("has_recursion"),
  )
}

/// Parse an analysis result from JSON.
let parseAnalysis = (json: string): result<analysisResult, string> =>
  Decoders.decode(analysisDecoder, json)

/// Tea_Json decoder for a schema compatibility comparison result.
let comparisonDecoder: Tea_Json.decoder<schemaCompatibilityResult> = {
  open Decoders
  map7(
    (
      leftPath,
      rightPath,
      leftFmt,
      rightFmt,
      compatible,
      adapterCost,
      notes,
    ): schemaCompatibilityResult => {
      leftPath,
      rightPath,
      leftFormat: parseFormat(leftFmt),
      rightFormat: parseFormat(rightFmt),
      compatible,
      adapterCost,
      notes,
    },
    stringField("left_path"),
    stringField("right_path"),
    stringField("left_format"),
    stringField("right_format"),
    boolField("compatible"),
    intField("adapter_cost"),
    stringField("notes"),
  )
}

/// Parse a schema compatibility comparison result from JSON.
let parseComparison = (json: string): result<schemaCompatibilityResult, string> =>
  Decoders.decode(comparisonDecoder, json)

/// Extract IR constraints from an analysis result for Panel-L import.
/// Generates constraint expressions based on schema structure properties.
let extractIrConstraints = (result: analysisResult): array<string> => {
  let constraints = []
  // Transport class constraint.
  let classLabel = transportClassLabel(result.transportClass)
  let constraints = Array.concat(
    constraints,
    [`transport_class(${result.filePath}) = ${classLabel}`],
  )
  // Overhead ratio constraint.
  let constraints = if result.overheadRatio > 1.5 {
    Array.concat(
      constraints,
      [
        `overhead_bound(${result.filePath}) <= 1.5 // current: ${Float.toString(
            result.overheadRatio,
          )}`,
      ],
    )
  } else {
    constraints
  }
  // Recursion constraint.
  let constraints = if result.hasRecursion {
    Array.concat(constraints, [`recursion_depth(${result.filePath}) is bounded`])
  } else {
    constraints
  }
  // Field count constraint.
  let constraints = if result.fieldCount > 50 {
    Array.concat(
      constraints,
      [`field_count(${result.filePath}) <= 50 // current: ${Int.toString(result.fieldCount)}`],
    )
  } else {
    constraints
  }
  constraints
}

/// Default initial state.
let defaultState: protocolSquisherState = {
  cliAvailable: false,
  loading: false,
  error: None,
  activeCategory: PsAnalyse,
  analyseInput: "",
  compareLeftInput: "",
  compareRightInput: "",
  lastAnalysis: None,
  lastComparison: None,
  analysisHistory: [],
  lastTypeCheck: None,
  irConstraints: [],
  transportDisplayActive: false,
}
