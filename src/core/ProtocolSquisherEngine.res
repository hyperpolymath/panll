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
  }

/// All supported formats.
let allFormats: array<schemaFormat> = [
  Protobuf, Avro, FlatBuffers, CapnProto, Thrift, MessagePack,
  Bebop, JsonSchema, GraphQL, Toml, RustFormat, ReScriptFormat, PythonFormat,
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

/// Parse an analysis result from JSON.
let parseAnalysis = (json: string): result<analysisResult, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getString = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getFloat = (key: string): float =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => n
            | _ => 0.0
            }
          | None => 0.0
          }
        let getInt = (key: string): int =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Float.toInt(n)
            | _ => 0
            }
          | None => 0
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }

        Ok({
          filePath: getString("file_path"),
          format: parseFormat(getString("format")),
          transportClass: parseTransportClass(getString("transport_class")),
          summary: getString("summary"),
          overheadRatio: getFloat("overhead_ratio"),
          fieldCount: getInt("field_count"),
          hasRecursion: getBool("has_recursion"),
        })
      }
    | _ => Error("Expected JSON object for analysis result")
    }
  } catch {
  | _ => Error("Failed to parse analysis JSON")
  }
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
}
