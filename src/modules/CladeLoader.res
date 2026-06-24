// SPDX-License-Identifier: MPL-2.0

/// PanLL Clade Loader — converts parsed A2ML clade files into `cladeEntry` records.
///
/// Handles both .a2ml formats:
///   - Newer format: `[clade-metadata]` section with id/name/kind/version/description
///   - Legacy format: `[clade]` section for id/name/kind/version, `[clade-description]`
///     for summary/long, `[clade-taxonomy]` for inheritance

open CladeBrowserModel

/// Parse a single `.a2ml` file's content into a `cladeEntry`.
/// The `dirId` is the directory name, used as fallback ID.
let fromA2ml = (dirId: string, content: string): option<cladeEntry> => {
  let doc = A2mlParser.parse(content)

  // Determine format: newer uses [clade-metadata], legacy uses [clade].
  let isNewFormat = A2mlParser.hasSection(doc, "clade-metadata")
  let metaSection = isNewFormat ? "clade-metadata" : "clade"

  // Core identity fields.
  let id = A2mlParser.getString(doc, metaSection, "id", ~default=dirId)
  let name = A2mlParser.getString(doc, metaSection, "name", ~default=id)
  let kind = A2mlParser.getString(doc, metaSection, "kind", ~default="meta")
  let version = A2mlParser.getString(doc, metaSection, "version", ~default="1.0.0")

  // Description: newer format has `description` in metadata,
  // legacy has `[clade-description]` with `summary` and `long`.
  let summary = if isNewFormat {
    A2mlParser.getString(doc, metaSection, "description")
  } else {
    A2mlParser.getString(doc, "clade-description", "summary")
  }
  let longDescription = if isNewFormat {
    A2mlParser.getString(doc, metaSection, "description")
  } else {
    A2mlParser.getString(doc, "clade-description", "long")
  }

  // Traits.
  let traits: cladeTraits = {
    hasPersistence: A2mlParser.getBool(doc, "clade-traits", "has-persistence"),
    hasBackend: A2mlParser.getBool(doc, "clade-traits", "has-backend"),
    hasWorkItems: A2mlParser.getBool(doc, "clade-traits", "has-work-items"),
    hasRealTime: A2mlParser.getBool(doc, "clade-traits", "has-real-time"),
    isAmbient: A2mlParser.getBool(doc, "clade-traits", "is-ambient"),
  }

  // Taxonomy (legacy format).
  let parentCladeId = {
    let raw = A2mlParser.getString(doc, "clade-taxonomy", "inherits-from")
    if raw === "" {
      None
    } else {
      Some(raw)
    }
  }
  let siblingClades = A2mlParser.getArray(doc, "clade-taxonomy", "sibling-clades")
  let supersedes = {
    let raw = A2mlParser.getString(doc, "clade-taxonomy", "supersedes")
    if raw === "" {
      []
    } else {
      [raw]
    }
  }

  // Panel integration.
  let panelId = A2mlParser.getString(doc, "clade-panel-integration", "panel-id")
  let panelIds = if panelId === "" {
    // Construct default panel ID from clade ID.
    let capitalised =
      id
      ->String.split("-")
      ->Array.map(part => {
        if String.length(part) > 0 {
          let first = part->String.slice(~start=0, ~end=1)->String.toUpperCase
          let rest = part->String.sliceToEnd(~start=1)
          first ++ rest
        } else {
          part
        }
      })
      ->Array.join("")
    ["Panel" ++ capitalised]
  } else {
    [panelId]
  }

  // Integrations.
  let consumedBy = A2mlParser.getArray(doc, "clade-integrations", "consumed-by")

  if id === "" {
    None
  } else {
    Some({
      id,
      name,
      kind,
      version,
      summary,
      longDescription,
      traits,
      panelIds,
      consumedBy,
      supersedes,
      parentCladeId,
      siblingClades,
      // Tier 1 fields — filled by CladeBrowserEngine.enrichClade.
      protocols: [],
      capabilities: [],
      requires: [],
      enhances: [],
      isolation: IsolationSoft,
      signing: SigningNone,
      sbom: None,
      sandbox: None,
    })
  }
}

/// Tea_Json decoder for a single scan result item.
/// Extracts "id" and "content" strings, then delegates to fromA2ml for parsing.
let scanItemDecoder: Tea_Json.decoder<cladeEntry> = json => {
  open Tea_Json
  let inner = map2(
    (dirId, content) => (dirId, content),
    field("id", string),
    field("content", string),
  )
  switch inner(json) {
  | Ok((dirId, content)) =>
    if dirId !== "" && content !== "" {
      switch fromA2ml(dirId, content) {
      | Some(entry) => Ok(entry)
      | None => Error(Failure("fromA2ml returned None", json))
      }
    } else {
      Error(Failure("Empty id or content", json))
    }
  | Error(e) => Error(e)
  }
}

/// Parse the JSON response from `scan_clade_files` into an array of clade entries.
/// Expected format: `[{"id": "...", "content": "..."}]`
let fromScanResult = (jsonStr: string): array<cladeEntry> =>
  Decoders.decodeWithDefault(Decoders.lenientArray(scanItemDecoder), [], jsonStr)

/// Merge file-loaded clades with built-in clades. File-loaded clades take
/// precedence over built-ins with the same ID. Built-ins without a matching
/// file are retained as fallbacks.
let mergeWithBuiltins = (loaded: array<cladeEntry>, builtins: array<cladeEntry>): array<
  cladeEntry,
> => {
  let loadedIds = loaded->Array.map(c => c.id)
  let uniqueBuiltins = builtins->Array.filter(b => !(loadedIds->Array.some(id => id === b.id)))
  Array.concat(loaded, uniqueBuiltins)
}
