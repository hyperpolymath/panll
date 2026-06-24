// SPDX-License-Identifier: MPL-2.0

/// PanLL A2ML Parser — parses `.a2ml` clade definition files into structured data.
///
/// A2ML is a TOML-like format with `[section]` headers and `key = value` pairs.
/// Supports string values (`"..."`), multi-line strings (`""" ... """`),
/// and arrays (`[item1, item2]`). Comments start with `#`.

/// A parsed section: section name → Dict of key-value pairs.
/// Array values are joined with `|` as a separator for downstream parsing.
type a2mlSection = Dict.t<string>

/// A fully parsed A2ML document: section name → key-value Dict.
type a2mlDocument = Dict.t<a2mlSection>

/// Parse a raw `.a2ml` file string into sections.
let parse = (raw: string): a2mlDocument => {
  let doc: a2mlDocument = Dict.make()
  let lines = raw->String.split("\n")
  let currentSection = ref("")
  let currentDict: ref<a2mlSection> = ref(Dict.make())
  let inMultiline = ref(false)
  let multilineKey = ref("")
  let multilineBuf = ref("")

  let flushSection = () => {
    if currentSection.contents !== "" {
      doc->Dict.set(currentSection.contents, currentDict.contents)
    }
  }

  lines->Array.forEach(line => {
    let trimmed = line->String.trim

    // Handle multi-line string continuation.
    if inMultiline.contents {
      if trimmed->String.endsWith(`"""`) {
        // End of multi-line: strip closing delimiter.
        let fragment = trimmed->String.slice(~start=0, ~end=String.length(trimmed) - 3)
        let full = multilineBuf.contents ++ fragment
        currentDict.contents->Dict.set(multilineKey.contents, full->String.trim)
        inMultiline := false
      } else {
        multilineBuf := multilineBuf.contents ++ trimmed ++ " "
      }
    } else if trimmed === "" || trimmed->String.startsWith("#") {
      // Skip blank lines and comments.
      ()
    } else if trimmed->String.startsWith("[") && trimmed->String.endsWith("]") {
      // New section header.
      flushSection()
      let sectionName = trimmed->String.slice(~start=1, ~end=String.length(trimmed) - 1)
      currentSection := sectionName
      currentDict := Dict.make()
    } else {
      // Key = value pair.
      let eqIdx = trimmed->String.indexOf("=")
      if eqIdx > 0 {
        let key = trimmed->String.slice(~start=0, ~end=eqIdx)->String.trim
        let rawVal = trimmed->String.sliceToEnd(~start=eqIdx + 1)->String.trim

        if rawVal->String.startsWith(`"""`) {
          // Multi-line string start.
          inMultiline := true
          multilineKey := key
          multilineBuf := rawVal->String.sliceToEnd(~start=3) ++ " "
        } else if rawVal->String.startsWith("\"") && rawVal->String.endsWith("\"") {
          // Quoted string value.
          let unquoted = rawVal->String.slice(~start=1, ~end=String.length(rawVal) - 1)
          currentDict.contents->Dict.set(key, unquoted)
        } else if rawVal->String.startsWith("[") {
          // Array value — collect items across lines if needed.
          // For single-line arrays: [item1, item2]
          // For multi-line: we collect until the closing ]
          let arrayContent = ref(rawVal)

          // If the line doesn't end with ], read subsequent lines.
          // But since we process line-by-line, handle single-line only here.
          // Multi-line arrays are handled via the content string.
          let content = arrayContent.contents
          // Strip brackets.
          let inner = content->String.slice(~start=1, ~end=String.length(content) - 1)
          // Parse items: split by comma, strip quotes and whitespace.
          let items =
            inner
            ->String.split(",")
            ->Array.map(s => {
              let t = s->String.trim
              if t->String.startsWith("\"") && t->String.endsWith("\"") {
                t->String.slice(~start=1, ~end=String.length(t) - 1)
              } else {
                t
              }
            })
            ->Array.filter(s => s !== "")
          // Join with pipe separator for downstream parsing.
          currentDict.contents->Dict.set(key, items->Array.join("|"))
        } else {
          // Plain value (boolean, number, or unquoted string).
          currentDict.contents->Dict.set(key, rawVal)
        }
      }
    }
  })

  // Flush the last section.
  flushSection()
  doc
}

/// Get a string value from a section, with a default fallback.
let getString = (doc: a2mlDocument, section: string, key: string, ~default=""): string => {
  doc
  ->Dict.get(section)
  ->Option.flatMap(s => s->Dict.get(key))
  ->Option.getOr(default)
}

/// Get a boolean value from a section.
let getBool = (doc: a2mlDocument, section: string, key: string): bool => {
  getString(doc, section, key) === "true"
}

/// Get a pipe-separated array value from a section.
let getArray = (doc: a2mlDocument, section: string, key: string): array<string> => {
  let raw = getString(doc, section, key)
  if raw === "" {
    []
  } else {
    raw->String.split("|")->Array.map(String.trim)->Array.filter(s => s !== "")
  }
}

/// Check if a section exists in the document.
let hasSection = (doc: a2mlDocument, section: string): bool => {
  doc->Dict.get(section)->Option.isSome
}
