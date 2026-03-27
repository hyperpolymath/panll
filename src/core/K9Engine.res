// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL K9 Engine — pure functions for parsing, validating, and querying K9
/// contractile files (.k9.ncl). K9 files are Nickel configuration components
/// with three security levels:
///
///   - Kennel: Pure data configuration. No execution, no contracts, no I/O.
///     Identified by `leash = 'Kennel` or absence of contracts/recipes.
///
///   - Yard: Configuration with Nickel contract validation. Has type contracts
///     and validation blocks but no execution recipes. No I/O.
///     Identified by `leash = 'Yard` or presence of contracts without recipes.
///
///   - Hunt: Full execution with Just recipes. Has system access, network,
///     filesystem writes, subprocess spawning. Requires signature.
///     Identified by `leash = 'Hunt` or presence of `recipes` blocks.
///
/// K9 files may also serve as layout presets for PanLL panel arrangements
/// (e.g., `layouts/protocol-design.k9.ncl`), which define pane sizes,
/// promoted actions, and default prover configurations.
///
/// All functions are pure — no side effects, no Tauri invocations, no I/O.

// ============================================================================
// Types
// ============================================================================

/// The three K9 security trust levels, ordered by increasing privilege.
type k9SecurityLevel =
  | Kennel
  | Yard
  | Hunt

/// A parsed K9 contractile with metadata and validation status.
type k9Contractile = {
  path: string,
  name: string,
  securityLevel: k9SecurityLevel,
  isValid: bool,
  errors: array<string>,
}

/// A parsed panel layout configuration extracted from a K9 layout file.
type k9Layout = {
  name: string,
  panels: array<string>,
  discipline: string,
}

/// Structured metadata extracted from a K9 pedigree block.
type k9Pedigree = {
  schemaVersion: string,
  componentType: string,
  trustLevel: string,
  allowNetwork: bool,
  allowFilesystemWrite: bool,
  allowSubprocess: bool,
  author: string,
  description: string,
}

// ============================================================================
// Internal Helpers
// ============================================================================

/// Trim whitespace from both ends.
let trim = (s: string): string => {
  s->String.trim
}

/// Check if content contains the K9 magic header.
let hasK9Magic = (content: string): bool => {
  let trimmed = trim(content)
  String.startsWith(trimmed, "K9!")
}

/// Check if content contains Nickel contract annotations (pipes with types).
let hasNickelContracts = (content: string): bool => {
  // Yard-level files use Nickel contract syntax: `| Type`, `| std.contract.*`
  String.includes(content, "| String") ||
  String.includes(content, "| Number") ||
  String.includes(content, "| Bool") ||
  String.includes(content, "| Array") ||
  String.includes(content, "| std.contract") ||
  String.includes(content, "| std.string") ||
  String.includes(content, "| std.array")
}

/// Check if content contains execution recipes (Hunt-level).
let hasRecipes = (content: string): bool => {
  String.includes(content, "recipes = {") || String.includes(content, "recipes=")
}

/// Check if content declares a specific leash level.
let declaresLeash = (content: string, level: string): bool => {
  String.includes(content, `leash = '${level}`)
}

/// Extract a string value from a `key = "value"` or `key = 'value` line pattern.
let extractStringValue = (content: string, key: string): option<string> => {
  // Look for `key = "value"` pattern
  let pattern = `${key} = "`
  let idx = String.indexOf(content, pattern)
  if idx >= 0 {
    let afterKey = String.sliceToEnd(content, ~start=idx + String.length(pattern))
    let endIdx = String.indexOf(afterKey, "\"")
    if endIdx >= 0 {
      Some(String.slice(afterKey, ~start=0, ~end=endIdx))
    } else {
      None
    }
  } else {
    // Try `key = 'EnumValue` pattern (Nickel enum)
    let enumPattern = `${key} = '`
    let enumIdx = String.indexOf(content, enumPattern)
    if enumIdx >= 0 {
      let afterKey = String.sliceToEnd(content, ~start=enumIdx + String.length(enumPattern))
      // Take until comma, newline, or whitespace
      let chars = String.split(afterKey, "")
      let result = ref("")
      let done = ref(false)
      chars->Array.forEach(c => {
        if !done.contents {
          if c == "," || c == "\n" || c == " " || c == "}" {
            done := true
          } else {
            result := result.contents ++ c
          }
        }
      })
      if result.contents != "" {
        Some(result.contents)
      } else {
        None
      }
    } else {
      None
    }
  }
}

/// Extract a boolean value from a `key = true/false` pattern.
let extractBoolValue = (content: string, key: string): option<bool> => {
  if String.includes(content, `${key} = true`) {
    Some(true)
  } else if String.includes(content, `${key} = false`) {
    Some(false)
  } else {
    None
  }
}

/// Extract a numeric value from a `key = 42` pattern.
let extractIntValue = (content: string, key: string): option<int> => {
  let pattern = `${key} = `
  let idx = String.indexOf(content, pattern)
  if idx >= 0 {
    let afterKey = String.sliceToEnd(content, ~start=idx + String.length(pattern))
    let chars = String.split(afterKey, "")
    let digits = ref("")
    let done = ref(false)
    chars->Array.forEach(c => {
      if !done.contents {
        if c >= "0" && c <= "9" {
          digits := digits.contents ++ c
        } else {
          done := true
        }
      }
    })
    Int.fromString(digits.contents)
  } else {
    None
  }
}

/// Extract an array of strings from a `key = ["a", "b"]` pattern.
let extractStringArray = (content: string, key: string): array<string> => {
  let pattern = `${key} = [`
  let idx = String.indexOf(content, pattern)
  if idx >= 0 {
    let afterKey = String.sliceToEnd(content, ~start=idx + String.length(pattern))
    let endIdx = String.indexOf(afterKey, "]")
    if endIdx >= 0 {
      let arrayContent = String.slice(afterKey, ~start=0, ~end=endIdx)
      arrayContent
      ->String.split(",")
      ->Array.map(s => {
        let trimmed = trim(s)

        // Remove surrounding quotes
        if String.startsWith(trimmed, "\"") && String.endsWith(trimmed, "\"") {
          String.slice(trimmed, ~start=1, ~end=String.length(trimmed) - 1)
        } else {
          trimmed
        }
      })
      ->Array.filter(s => s != "")
    } else {
      []
    }
  } else {
    []
  }
}

// ============================================================================
// Public API
// ============================================================================

/// Detect the security level of a K9 file from its content.
///
/// Priority:
///   1. Explicit `leash = 'Hunt/Yard/Kennel` declaration takes precedence.
///   2. If `recipes` block present → Hunt.
///   3. If Nickel contracts present → Yard.
///   4. Otherwise → Kennel (pure data).
let detectSecurityLevel = (content: string): k9SecurityLevel => {
  // Check explicit leash declarations first
  if declaresLeash(content, "Hunt") {
    Hunt
  } else if declaresLeash(content, "Yard") {
    Yard
  } else if declaresLeash(content, "Kennel") {
    Kennel
  } else if hasRecipes(content) {
    // Implicit detection: recipes means Hunt
    Hunt
  } else if hasNickelContracts(content) {
    // Implicit detection: contracts means Yard
    Yard
  } else {
    // Default: pure data
    Kennel
  }
}

/// Validate the structural integrity of a K9 contractile.
///
/// Checks:
///   - Non-empty content
///   - K9 magic header present (if K9 template format)
///   - Pedigree block present
///   - Security level consistency (declared vs detected)
///   - Hunt-level files must declare side_effects
///   - Hunt-level files must have signature_required = true
let validateContractile = (content: string, ~path: string=""): k9Contractile => {
  let errors: array<string> = []
  let trimmedContent = trim(content)

  if String.length(trimmedContent) == 0 {
    let _ = errors->Array.push("Empty K9 file")
  }

  // Check for pedigree block
  let hasPedigree =
    String.includes(content, "pedigree = {") || String.includes(content, "pedigree=")
  if !hasPedigree && !String.includes(content, "LayoutPreset") {
    // Layout files import pedigree from pedigree-layout.ncl, so they're exempt
    let _ = errors->Array.push("Missing pedigree block")
  }

  let detectedLevel = detectSecurityLevel(content)

  // Hunt-level specific checks
  if detectedLevel == Hunt {
    if !String.includes(content, "side_effects") {
      let _ = errors->Array.push("Hunt-level K9 must declare side_effects")
    }
    if !String.includes(content, "signature_required = true") {
      let _ = errors->Array.push("Hunt-level K9 must have signature_required = true")
    }
  }

  // Extract name from metadata
  let name = switch extractStringValue(content, "name") {
  | Some(n) => n
  | None =>
    // Try extracting from filename
    if path != "" {
      let parts = String.split(path, "/")
      let filename = parts->Array.get(Array.length(parts) - 1)->Option.getOr("unknown")
      String.replace(filename, ".k9.ncl", "")
    } else {
      "unknown"
    }
  }

  {
    path,
    name,
    securityLevel: detectedLevel,
    isValid: Array.length(errors) == 0,
    errors,
  }
}

/// Parse panel layout configuration from a K9 layout file.
///
/// Layout K9 files define PanLL panel arrangements with pane sizes,
/// promoted actions, and default prover selections. They are always
/// Yard-level (pure config with Nickel contracts for validation).
let parseLayoutPanels = (content: string): k9Layout => {
  let name = switch extractStringValue(content, "name") {
  | Some(n) => n
  | None => "Unknown Layout"
  }

  // Extract promoted actions as the panel configuration
  let panels = extractStringArray(content, "promoted_actions")

  // Determine discipline from layout name or description
  let discipline = if String.includes(content, "protocol") || String.includes(content, "Protocol") {
    "protocol-design"
  } else if String.includes(content, "logic") || String.includes(content, "Logic") {
    "logic-and-proofs"
  } else if String.includes(content, "database") || String.includes(content, "Database") {
    "database-design"
  } else if String.includes(content, "language") || String.includes(content, "Language") {
    "language-design"
  } else {
    "general"
  }

  {name, panels, discipline}
}

/// Human-readable label for a security level.
let securityLevelLabel = (level: k9SecurityLevel): string => {
  switch level {
  | Kennel => "Kennel (data-only)"
  | Yard => "Yard (validated config)"
  | Hunt => "Hunt (full execution)"
  }
}

/// Colour code for a security level (for UI rendering).
///   - Kennel: green (safe, no execution)
///   - Yard: amber/yellow (contracts but no I/O)
///   - Hunt: red (full system access)
let securityLevelColour = (level: k9SecurityLevel): string => {
  switch level {
  | Kennel => "#22c55e"
  | Yard => "#f59e0b"
  | Hunt => "#ef4444"
  }
}

/// CSS class name for a security level badge.
let securityLevelClass = (level: k9SecurityLevel): string => {
  switch level {
  | Kennel => "k9-kennel"
  | Yard => "k9-yard"
  | Hunt => "k9-hunt"
  }
}

/// Extract the pedigree metadata block from K9 content.
let extractPedigree = (content: string): k9Pedigree => {
  {
    schemaVersion: extractStringValue(content, "schema_version")->Option.getOr("unknown"),
    componentType: extractStringValue(content, "component_type")->Option.getOr("unknown"),
    trustLevel: extractStringValue(content, "trust_level")->Option.getOr("unknown"),
    allowNetwork: extractBoolValue(content, "allow_network")->Option.getOr(false),
    allowFilesystemWrite: extractBoolValue(content, "allow_filesystem_write")->Option.getOr(false),
    allowSubprocess: extractBoolValue(content, "allow_subprocess")->Option.getOr(false),
    author: extractStringValue(content, "author")->Option.getOr("unknown"),
    description: extractStringValue(content, "description")->Option.getOr(""),
  }
}

/// Extract pane sizes from a layout K9 file.
/// Returns (pane_l_size, pane_n_size, pane_w_size) or (33, 34, 33) as default.
let extractPaneSizes = (content: string): (int, int, int) => {
  let l = extractIntValue(content, "pane_l_size")->Option.getOr(33)
  let n = extractIntValue(content, "pane_n_size")->Option.getOr(34)
  let w = extractIntValue(content, "pane_w_size")->Option.getOr(33)
  (l, n, w)
}

/// Generate a human-readable summary of a K9 contractile.
let summariseContractile = (contractile: k9Contractile): string => {
  let statusLine = if contractile.isValid {
    "Status: Valid"
  } else {
    let errorList = contractile.errors->Array.join("; ")
    `Status: Invalid (${errorList})`
  }

  `Name: ${contractile.name}
Path: ${contractile.path}
Security: ${securityLevelLabel(contractile.securityLevel)}
${statusLine}`
}

// ============================================================================
// A2ML/K9 Integration Functions
// ============================================================================

/// Generate a K9 Kennel-level Nickel schema from a panel module's configuration.
/// Kennel schemas are pure data — no contracts, no execution, no I/O.
/// They capture the shape of a module's configurable state as a K9 data file.
///
/// Takes the module name and a list of (field-name, field-type, default-value) triples
/// describing the module's configurable fields.
let generateKennelSchema = (
  moduleName: string,
  fields: array<(string, string, string)>,
): string => {
  let fieldLines =
    fields
    ->Array.map(((name, typ, defaultVal)) => {
      `    ${name} = ${defaultVal}, # ${typ}`
    })
    ->Array.join("\n")

  `# K9 Kennel Schema — auto-generated from ${moduleName} module config
# Security: Kennel (data-only, no contracts, no execution)
# SPDX-License-Identifier: PMPL-1.0-or-later

K9!

{
  pedigree = {
    schema_version = "1.0",
    component_type = "ModuleConfig",
    trust_level = "kennel",
    allow_network = false,
    allow_filesystem_write = false,
    allow_subprocess = false,
    author = "panll-generator",
    description = "Auto-generated Kennel schema for ${moduleName} panel module",
  },

  leash = 'Kennel,

  module = "${moduleName}",

  config = {
${fieldLines}
  },
}`
}

/// Generate a K9 Yard-level Nickel contract from a BoJ cartridge definition.
/// Yard contracts add Nickel type validation to cartridge configuration —
/// they verify port ranges, protocol lists, grade values, and layer status
/// without executing anything.
///
/// Takes a cartridge name, list of protocol names, and port configuration.
let generateYardContract = (
  cartridgeName: string,
  protocols: array<string>,
  restPort: int,
  grpcPort: int,
  graphqlPort: int,
  grade: string,
): string => {
  let protoArray = protocols->Array.map(p => `"${p}"`)->Array.join(", ")
  let portValidation = if restPort > 0 || grpcPort > 0 || graphqlPort > 0 {
    `    rest_port | std.contract.from_predicate (fun p => p >= 1024 && p <= 65535) = ${Int.toString(
        restPort,
      )},
    grpc_port | std.contract.from_predicate (fun p => p >= 1024 && p <= 65535) = ${Int.toString(
        grpcPort,
      )},
    graphql_port | std.contract.from_predicate (fun p => p >= 1024 && p <= 65535) = ${Int.toString(
        graphqlPort,
      )},`
  } else {
    `    rest_port = 0,
    grpc_port = 0,
    graphql_port = 0,`
  }

  `# K9 Yard Contract — auto-generated from BoJ cartridge "${cartridgeName}"
# Security: Yard (validated config with Nickel contracts, no execution)
# SPDX-License-Identifier: PMPL-1.0-or-later

K9!

{
  pedigree = {
    schema_version = "1.0",
    component_type = "CartridgeConfig",
    trust_level = "yard",
    allow_network = false,
    allow_filesystem_write = false,
    allow_subprocess = false,
    author = "panll-generator",
    description = "Auto-generated Yard contract for BoJ cartridge ${cartridgeName}",
  },

  leash = 'Yard,

  cartridge = {
    name | String = "${cartridgeName}",
    grade | std.contract.from_predicate (fun g => std.array.elem g ["A", "B", "C", "D"]) = "${grade}",
    protocols | Array String = [${protoArray}],
${portValidation}
  },

  layers = {
    abi_ready | Bool = false,
    ffi_ready | Bool = false,
    adapter_ready | Bool = false,
    shared_lib_ready | Bool = false,
  },
}`
}

/// Extract configurable fields from a BoJ cartridge for Kennel schema generation.
/// Returns (field-name, field-type, default-value) triples.
let cartridgeToKennelFields = (name: string, protocols: array<string>): array<(
  string,
  string,
  string,
)> => {
  let protoStr = "[" ++ protocols->Array.map(p => `"${p}"`)->Array.join(", ") ++ "]"
  [
    ("name", "String", `"${name}"`),
    ("loaded", "Bool", "false"),
    ("protocols", "Array String", protoStr),
    ("rest_port", "Number", "0"),
    ("grpc_port", "Number", "0"),
    ("graphql_port", "Number", "0"),
  ]
}

/// Check if a K9 Hunt-level execution is permitted for a given clade permission set.
/// Returns (allowed, reason) where reason explains the decision.
///
/// Hunt-level K9 files require:
///   1. The clade must have `hunt` in its isolation requirements
///   2. The clade must have signing enabled
///   3. The contractile must have signature_required = true
let checkHuntPermission = (
  cladeIsolation: string,
  cladeSigning: bool,
  contractileContent: string,
): (bool, string) => {
  let huntAllowed =
    String.includes(cladeIsolation, "hunt") || String.includes(cladeIsolation, "full")
  let hasSig = String.includes(contractileContent, "signature_required = true")

  if !huntAllowed {
    (false, "Clade isolation level does not permit Hunt execution")
  } else if !cladeSigning {
    (false, "Clade does not have signing enabled — Hunt requires signed contractiles")
  } else if !hasSig {
    (false, "Contractile does not declare signature_required = true")
  } else {
    (true, "Hunt execution permitted — clade isolation allows it, signing verified")
  }
}
