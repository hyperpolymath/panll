// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL A2ML Engine — pure functions for parsing, validating, and querying A2ML
/// manifest files (both S-expression style like 0-AI-MANIFEST.a2ml and sectioned
/// key-value style like clade .a2ml files and Trustfile.a2ml).
///
/// A2ML files come in two main flavours within PanLL:
///   1. S-expression manifests: `(manifest (identity ...) (canonical-locations ...) ...)`
///   2. Sectioned key-value: `[section-name]\nkey = value` (clade files, Trustfile)
///
/// This engine provides a unified representation via `a2mlSection` trees, with
/// parsing heuristics that detect the format and extract sections accordingly.
///
/// All functions are pure — no side effects, no Gossamer invocations, no I/O.

// ============================================================================
// Types
// ============================================================================

/// A single section or key-value node in an A2ML document.
/// Sections can nest: a `[clade-metadata]` section contains key-value children,
/// and an S-expression `(canonical-locations ...)` section contains location entries.
type rec a2mlSection = {
  key: string,
  value: string,
  children: array<a2mlSection>,
}

/// A parsed A2ML manifest with its file path, extracted sections, and parse status.
type a2mlManifest = {
  path: string,
  sections: array<a2mlSection>,
  isValid: bool,
  errors: array<string>,
}

/// Result of validating a manifest against the A2ML schema requirements.
type a2mlValidationResult = {
  valid: bool,
  errors: array<string>,
  warnings: array<string>,
  sectionCount: int,
}

// ============================================================================
// Internal Helpers
// ============================================================================

/// Trim whitespace from both ends of a string.
let trim = (s: string): string => {
  s->String.trim
}

/// Check if a line starts a new section in key-value format: `[section-name]`
let isSectionHeader = (line: string): bool => {
  let trimmed = trim(line)
  String.startsWith(trimmed, "[") &&
  String.endsWith(trimmed, "]") &&
  !String.startsWith(trimmed, "[[")
}

/// Extract the section name from a `[section-name]` header line.
let extractSectionName = (line: string): string => {
  let trimmed = trim(line)
  let withoutBrackets = String.sliceToEnd(trimmed, ~start=1)
  String.slice(withoutBrackets, ~start=0, ~end=String.length(withoutBrackets) - 1)
}

/// Check if a line is a `---` section divider (Trustfile-style).
let isSectionDivider = (line: string): bool => {
  trim(line) == "---"
}

/// Check if a line is a `### [SECTION]` header (Trustfile-style).
let isTrustfileSectionHeader = (line: string): bool => {
  let trimmed = trim(line)
  String.startsWith(trimmed, "### [") && String.endsWith(trimmed, "]")
}

/// Extract section name from `### [SECTION_NAME]` header.
let extractTrustfileSectionName = (line: string): string => {
  let trimmed = trim(line)
  let afterHash = String.sliceToEnd(trimmed, ~start=5)
  String.slice(afterHash, ~start=0, ~end=String.length(afterHash) - 1)
}

/// Check if a line is an S-expression opener like `(manifest`, `(identity`, etc.
let isSexprSection = (line: string): bool => {
  let trimmed = trim(line)
  String.startsWith(trimmed, "(") && !String.startsWith(trimmed, "(;")
}

/// Extract the S-expression section name from a line like `(manifest` or `  (identity`.
let extractSexprName = (line: string): string => {
  let trimmed = trim(line)
  let afterParen = String.sliceToEnd(trimmed, ~start=1)
  // Take up to the first space or closing paren
  let parts = String.split(afterParen, " ")
  let first = parts->Array.get(0)->Option.getOr("")

  // Remove trailing paren if present
  if String.endsWith(first, ")") {
    String.slice(first, ~start=0, ~end=String.length(first) - 1)
  } else {
    first
  }
}

/// Parse a `key = value` or `key = "value"` line into a section child.
let parseKeyValue = (line: string): option<a2mlSection> => {
  let trimmed = trim(line)

  // Skip comments and empty lines
  if trimmed == "" || String.startsWith(trimmed, "#") || String.startsWith(trimmed, ";") {
    None
  } else {
    let eqIdx = String.indexOf(trimmed, " = ")
    if eqIdx >= 0 {
      let key = String.slice(trimmed, ~start=0, ~end=eqIdx)->trim
      let rawValue = String.sliceToEnd(trimmed, ~start=eqIdx + 3)->trim
      // Strip surrounding quotes if present
      let value = if String.startsWith(rawValue, "\"") && String.endsWith(rawValue, "\"") {
        String.slice(rawValue, ~start=1, ~end=String.length(rawValue) - 1)
      } else {
        rawValue
      }
      Some({key, value, children: []})
    } else {
      // Try simple `key: value` YAML-style (used in Trustfile A2ML)
      let colonIdx = String.indexOf(trimmed, ": ")
      if colonIdx >= 0 {
        let key = String.slice(trimmed, ~start=0, ~end=colonIdx)->trim
        let rawValue = String.sliceToEnd(trimmed, ~start=colonIdx + 2)->trim
        let value = if String.startsWith(rawValue, "\"") && String.endsWith(rawValue, "\"") {
          String.slice(rawValue, ~start=1, ~end=String.length(rawValue) - 1)
        } else {
          rawValue
        }
        Some({key, value, children: []})
      } else {
        None
      }
    }
  }
}

/// Detect the A2ML format flavour from file content.
type a2mlFormat =
  | SExprFormat
  | SectionedKeyValueFormat
  | TrustfileFormat

let detectFormat = (content: string): a2mlFormat => {
  let trimmed = trim(content)
  if String.startsWith(trimmed, ";") || String.startsWith(trimmed, "(") {
    SExprFormat
  } else if String.includes(trimmed, "### [") && String.includes(trimmed, "---") {
    TrustfileFormat
  } else {
    SectionedKeyValueFormat
  }
}

// ============================================================================
// Parsers
// ============================================================================

/// Parse S-expression format A2ML (like 0-AI-MANIFEST.a2ml).
/// Extracts top-level sections and their string content as children.
let parseSexprContent = (content: string, path: string): a2mlManifest => {
  let lines = String.split(content, "\n")
  let sections: array<a2mlSection> = []
  let errors: array<string> = []
  let currentSection: ref<option<string>> = ref(None)
  let currentChildren: ref<array<a2mlSection>> = ref([])

  lines->Array.forEach(line => {
    let trimmed = trim(line)
    if trimmed == "" || String.startsWith(trimmed, ";") || String.startsWith(trimmed, ";;") {
      // Skip comments and blanks
      ()
    } else if isSexprSection(trimmed) {
      // Flush previous section
      switch currentSection.contents {
      | Some(name) =>
        let _ = sections->Array.push({
          key: name,
          value: "",
          children: currentChildren.contents,
        })
      | None => ()
      }
      currentSection := Some(extractSexprName(trimmed))
      currentChildren := []
    } else {
      // Try to extract key-value pairs from S-expression body
      // Lines like `(name "PanLL")` or `(state ".machine_readable/STATE.scm")`
      let cleaned =
        trimmed
        ->String.replaceAll("(", "")
        ->String.replaceAll(")", "")
        ->trim
      let parts = String.split(cleaned, " ")
      if Array.length(parts) >= 2 {
        let key = parts->Array.get(0)->Option.getOr("")
        let rawVal =
          parts
          ->Array.sliceToEnd(~start=1)
          ->Array.join(" ")
        let value = if String.startsWith(rawVal, "\"") && String.endsWith(rawVal, "\"") {
          String.slice(rawVal, ~start=1, ~end=String.length(rawVal) - 1)
        } else {
          rawVal
        }
        let _ = currentChildren.contents->Array.push({key, value, children: []})
      }
    }
  })

  // Flush final section
  switch currentSection.contents {
  | Some(name) =>
    let _ = sections->Array.push({
      key: name,
      value: "",
      children: currentChildren.contents,
    })
  | None => ()
  }

  {
    path,
    sections,
    isValid: Array.length(errors) == 0 && Array.length(sections) > 0,
    errors,
  }
}

/// Parse sectioned key-value format A2ML (like clade .a2ml files).
let parseSectionedContent = (content: string, path: string): a2mlManifest => {
  let lines = String.split(content, "\n")
  let sections: array<a2mlSection> = []
  let errors: array<string> = []
  let currentSection: ref<option<string>> = ref(None)
  let currentChildren: ref<array<a2mlSection>> = ref([])

  lines->Array.forEach(line => {
    let trimmed = trim(line)
    if trimmed == "" || String.startsWith(trimmed, "#") {
      // Skip comments and blanks
      ()
    } else if isSectionHeader(trimmed) {
      // Flush previous section
      switch currentSection.contents {
      | Some(name) =>
        let _ = sections->Array.push({
          key: name,
          value: "",
          children: currentChildren.contents,
        })
      | None => ()
      }
      currentSection := Some(extractSectionName(trimmed))
      currentChildren := []
    } else {
      switch parseKeyValue(trimmed) {
      | Some(kv) =>
        let _ = currentChildren.contents->Array.push(kv)
      | None => ()
      }
    }
  })

  // Flush final section
  switch currentSection.contents {
  | Some(name) =>
    let _ = sections->Array.push({
      key: name,
      value: "",
      children: currentChildren.contents,
    })
  | None => ()
  }

  {
    path,
    sections,
    isValid: Array.length(errors) == 0 && Array.length(sections) > 0,
    errors,
  }
}

/// Parse Trustfile-format A2ML (`---` dividers with `### [SECTION]` headers).
let parseTrustfileContent = (content: string, path: string): a2mlManifest => {
  let lines = String.split(content, "\n")
  let sections: array<a2mlSection> = []
  let errors: array<string> = []
  let currentSection: ref<option<string>> = ref(None)
  let currentChildren: ref<array<a2mlSection>> = ref([])

  lines->Array.forEach(line => {
    let trimmed = trim(line)
    if isSectionDivider(trimmed) {
      // Flush previous section on divider
      switch currentSection.contents {
      | Some(name) =>
        let _ = sections->Array.push({
          key: name,
          value: "",
          children: currentChildren.contents,
        })
        currentSection := None
        currentChildren := []
      | None => ()
      }
    } else if isTrustfileSectionHeader(trimmed) {
      currentSection := Some(extractTrustfileSectionName(trimmed))
      currentChildren := []
    } else if trimmed == "" || String.startsWith(trimmed, "#") {
      ()
    } else {
      switch parseKeyValue(trimmed) {
      | Some(kv) =>
        let _ = currentChildren.contents->Array.push(kv)
      | None => ()
      }
    }
  })

  // Flush final section
  switch currentSection.contents {
  | Some(name) =>
    let _ = sections->Array.push({
      key: name,
      value: "",
      children: currentChildren.contents,
    })
  | None => ()
  }

  {
    path,
    sections,
    isValid: Array.length(errors) == 0 && Array.length(sections) > 0,
    errors,
  }
}

// ============================================================================
// Public API
// ============================================================================

/// Parse A2ML content from any supported format. Auto-detects the flavour
/// (S-expression, sectioned key-value, or Trustfile) and delegates to the
/// appropriate parser.
let parseA2mlContent = (content: string, ~path: string=""): a2mlManifest => {
  if String.length(trim(content)) == 0 {
    {
      path,
      sections: [],
      isValid: false,
      errors: ["Empty content"],
    }
  } else {
    switch detectFormat(content) {
    | SExprFormat => parseSexprContent(content, path)
    | SectionedKeyValueFormat => parseSectionedContent(content, path)
    | TrustfileFormat => parseTrustfileContent(content, path)
    }
  }
}

/// Validate a parsed manifest against A2ML schema requirements.
///
/// For full manifests (0-AI-MANIFEST.a2ml), checks for required sections:
///   - identity or clade-metadata (identification)
///   - canonical-locations (file mapping)
///   - critical-invariants (rules)
///
/// For clade files, checks for:
///   - clade-metadata (identification)
///   - clade-traits (capability declaration)
///
/// For Trustfile A2ML, checks for:
///   - META section
///   - TRUSTFILE section
let validateManifest = (manifest: a2mlManifest): a2mlValidationResult => {
  let errors: array<string> = []
  let warnings: array<string> = []
  let sectionNames = manifest.sections->Array.map(s => s.key)

  // Check if this is a full manifest, clade file, or trustfile
  let hasIdentity = sectionNames->Array.some(n => n == "identity")
  let hasCladeMetadata = sectionNames->Array.some(n => n == "clade-metadata")
  let hasMeta = sectionNames->Array.some(n => n == "META")
  let hasTrustfile = sectionNames->Array.some(n => n == "TRUSTFILE")

  if hasIdentity {
    // Full manifest validation
    if !(sectionNames->Array.some(n => n == "canonical-locations")) {
      let _ = errors->Array.push("Missing required section: canonical-locations")
    }
    if !(sectionNames->Array.some(n => n == "critical-invariants")) {
      let _ = warnings->Array.push("Missing recommended section: critical-invariants")
    }
    if !(sectionNames->Array.some(n => n == "purpose")) {
      let _ = warnings->Array.push("Missing recommended section: purpose")
    }
    if !(sectionNames->Array.some(n => n == "lifecycle")) {
      let _ = warnings->Array.push("Missing recommended section: lifecycle")
    }
  } else if hasCladeMetadata {
    // Clade file validation
    if !(sectionNames->Array.some(n => n == "clade-traits")) {
      let _ = errors->Array.push("Clade file missing required section: clade-traits")
    }
    // Check clade-metadata has required keys
    let metaSection = manifest.sections->Array.find(s => s.key == "clade-metadata")
    switch metaSection {
    | Some(section) =>
      let childKeys = section.children->Array.map(c => c.key)
      if !(childKeys->Array.some(k => k == "id")) {
        let _ = errors->Array.push("clade-metadata missing required key: id")
      }
      if !(childKeys->Array.some(k => k == "name")) {
        let _ = errors->Array.push("clade-metadata missing required key: name")
      }
      if !(childKeys->Array.some(k => k == "kind")) {
        let _ = warnings->Array.push("clade-metadata missing recommended key: kind")
      }
    | None => ()
    }
  } else if hasMeta && hasTrustfile {
    // Trustfile validation
    if !(sectionNames->Array.some(n => n == "THREAT_MODEL")) {
      let _ = warnings->Array.push("Trustfile missing recommended section: THREAT_MODEL")
    }
    if !(sectionNames->Array.some(n => n == "FORMAL_VERIFICATION")) {
      let _ = warnings->Array.push("Trustfile missing recommended section: FORMAL_VERIFICATION")
    }
  } else if hasMeta {
    // Partial trustfile — META without TRUSTFILE
    let _ = warnings->Array.push("Has META section but no TRUSTFILE section — partial trustfile?")
  } else {
    // Unknown format — warn but don't error (might be a valid custom A2ML)
    let _ = warnings->Array.push("No recognised root section (identity, clade-metadata, or META)")
  }

  // Check for empty sections (applies to all formats)
  manifest.sections->Array.forEach(section => {
    if Array.length(section.children) == 0 && section.value == "" {
      let _ = warnings->Array.push(`Section "${section.key}" is empty`)
    }
  })

  // Check for empty values in children
  manifest.sections->Array.forEach(section => {
    section.children->Array.forEach(child => {
      if child.value == "" && Array.length(child.children) == 0 {
        let _ =
          warnings->Array.push(`Key "${child.key}" in section "${section.key}" has empty value`)
      }
    })
  })

  {
    valid: Array.length(errors) == 0,
    errors: Array.concat(manifest.errors, errors),
    warnings,
    sectionCount: Array.length(manifest.sections),
  }
}

/// Extract canonical file location mappings from a manifest.
/// Returns an array of (logical-name, file-path) tuples.
///
/// Works with both S-expression manifests (where canonical-locations has
/// children like `(state ".machine_readable/STATE.scm")`) and sectioned
/// key-value files (where `[canonical-locations]` has `key = "path"` entries).
let extractCanonicalLocations = (manifest: a2mlManifest): array<(string, string)> => {
  let locSection = manifest.sections->Array.find(s => s.key == "canonical-locations")
  switch locSection {
  | Some(section) => section.children->Array.map(child => (child.key, child.value))
  | None => []
  }
}

/// Extract lifecycle hooks (on-enter and on-exit steps) from a manifest.
/// Returns an array of step description strings.
let extractLifecycleHooks = (manifest: a2mlManifest): array<string> => {
  let lifecycleSection = manifest.sections->Array.find(s => s.key == "lifecycle")
  switch lifecycleSection {
  | Some(section) =>
    section.children->Array.map(child => {
      if child.value != "" {
        `${child.key}: ${child.value}`
      } else {
        child.key
      }
    })
  | None => []
  }
}

/// Find a section by key name in the manifest.
let findSection = (manifest: a2mlManifest, sectionKey: string): option<a2mlSection> => {
  manifest.sections->Array.find(s => s.key == sectionKey)
}

/// Get a value from a section by key name. Returns None if section or key not found.
let getValue = (manifest: a2mlManifest, sectionKey: string, key: string): option<string> => {
  switch findSection(manifest, sectionKey) {
  | Some(section) =>
    switch section.children->Array.find(c => c.key == key) {
    | Some(child) => Some(child.value)
    | None => None
    }
  | None => None
  }
}

/// Extract test coverage policy from A2ML clade traits.
/// Returns (required-coverage-percent, required-test-types, notes) or defaults
/// if the clade does not specify a test policy.
///
/// Looks for keys in `[clade-traits]` or `[clade-integrations]`:
///   - `test-coverage` or `coverage` → minimum coverage percentage
///   - `test-types` → pipe-separated list (e.g. "unit|integration|property")
///   - `test-notes` or `testing` → free-form test policy notes
let extractTestCoveragePolicy = (manifest: a2mlManifest): (int, array<string>, string) => {
  // Try clade-traits first, then clade-integrations
  let traitSection = switch findSection(manifest, "clade-traits") {
  | Some(s) => Some(s)
  | None => findSection(manifest, "clade-integrations")
  }
  switch traitSection {
  | Some(section) =>
    let coverageStr = switch section.children->Array.find(c =>
      c.key == "test-coverage" || c.key == "coverage"
    ) {
    | Some(child) => child.value
    | None => "0"
    }
    let coverage = Int.fromString(coverageStr)->Option.getOr(0)

    let testTypes = switch section.children->Array.find(c => c.key == "test-types") {
    | Some(child) =>
      child.value->String.split("|")->Array.map(s => String.trim(s))->Array.filter(s => s != "")
    | None => []
    }

    let notes = switch section.children->Array.find(c =>
      c.key == "test-notes" || c.key == "testing"
    ) {
    | Some(child) => child.value
    | None => ""
    }

    (coverage, testTypes, notes)
  | None => (0, [], "")
  }
}

/// Generate an A2ML test coverage section from a clade's test requirements.
/// This is used when creating new A2ML files for panels that inherit clade traits.
let generateTestCoverageSection = (
  coverage: int,
  testTypes: array<string>,
  notes: string,
): string => {
  let typesStr = testTypes->Array.join(" | ")
  let notesLine = if notes != "" {
    `test-notes = "${notes}"\n`
  } else {
    ""
  }
  `[test-policy]
test-coverage = ${Int.toString(coverage)}
test-types = "${typesStr}"
${notesLine}`
}

/// Generate a human-readable summary of a parsed manifest.
let summariseManifest = (manifest: a2mlManifest): string => {
  let sectionCount = Array.length(manifest.sections)
  let sectionNames = manifest.sections->Array.map(s => s.key)->Array.join(", ")
  let totalKeys = manifest.sections->Array.reduce(0, (acc, s) => acc + Array.length(s.children))

  let statusLine = if manifest.isValid {
    "Status: Valid"
  } else {
    let errorList = manifest.errors->Array.join("; ")
    `Status: Invalid (${errorList})`
  }

  let nameLine = switch getValue(manifest, "identity", "name") {
  | Some(name) => `Name: ${name}`
  | None =>
    switch getValue(manifest, "clade-metadata", "name") {
    | Some(name) => `Clade: ${name}`
    | None => "Name: (unknown)"
    }
  }

  let pathLine = if manifest.path != "" {
    `Path: ${manifest.path}`
  } else {
    "Path: (in-memory)"
  }

  `${nameLine}
${pathLine}
${statusLine}
Sections: ${Int.toString(sectionCount)} (${sectionNames})
Total keys: ${Int.toString(totalKeys)}`
}
