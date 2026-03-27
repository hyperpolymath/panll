// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — VoiceTag Engine (Layer 0)
///
/// Pure computation for tag management, voice command parsing, summary
/// generation, policy matching, and .mri.json serialisation. All functions
/// are pure — side effects (file I/O, voice API) happen in VoiceTagCmd.
///
/// The engine is designed so that the same logic could power a standalone CLI
/// tool, a VS Code extension, or PanLL's integrated experience. PanLL adds
/// voice input and agentic policy; the engine doesn't assume either.

open VoiceTagModel

// ===========================================================================
// Tag CRUD — the core operations that any Code MRI implementation needs
// ===========================================================================

/// Generate the next tag ID for a file (max existing + 1, or 1 if empty).
let nextId = (tags: array<mriTag>): int => {
  tags->Array.reduce(0, (max, tag) => tag.id > max ? tag.id : max) + 1
}

/// Create a new tag with human keyboard attribution (most common path).
let createTag = (
  tags: array<mriTag>,
  startLine: int,
  endLine: int,
  tagType: mriTagType,
  message: option<string>,
): mriTag => {
  {
    id: nextId(tags),
    startLine,
    endLine,
    tagType,
    message,
    attribution: {
      agent: "human",
      method: Keyboard,
      timestamp: Date.now(),
      sessionId: None,
    },
    codeAuthor: None,
    resolved: false,
    resolvedBy: None,
  }
}

/// Create a tag with explicit attribution (for voice, agent, or import sources).
let createTagWithAttribution = (
  tags: array<mriTag>,
  startLine: int,
  endLine: int,
  tagType: mriTagType,
  message: option<string>,
  agent: string,
  method: mriInputMethod,
): mriTag => {
  {
    id: nextId(tags),
    startLine,
    endLine,
    tagType,
    message,
    attribution: {
      agent,
      method,
      timestamp: Date.now(),
      sessionId: None,
    },
    codeAuthor: None,
    resolved: false,
    resolvedBy: None,
  }
}

/// Add a tag to the list (append, preserving order).
let addTag = (tags: array<mriTag>, tag: mriTag): array<mriTag> => {
  tags->Array.concat([tag])
}

/// Remove a tag by ID.
let removeTag = (tags: array<mriTag>, id: int): array<mriTag> => {
  tags->Array.filter(t => t.id !== id)
}

/// Resolve a tag (mark as done, record who resolved it).
let resolveTag = (tags: array<mriTag>, id: int, resolverAgent: string): array<mriTag> => {
  tags->Array.map(t =>
    if t.id === id {
      {
        ...t,
        resolved: true,
        resolvedBy: Some({
          agent: resolverAgent,
          method: Keyboard,
          timestamp: Date.now(),
          sessionId: None,
        }),
      }
    } else {
      t
    }
  )
}

/// Update a tag's message.
let updateTagMessage = (tags: array<mriTag>, id: int, message: string): array<mriTag> => {
  tags->Array.map(t =>
    if t.id === id {
      {...t, message: Some(message)}
    } else {
      t
    }
  )
}

/// Update a tag's type (e.g., escalate NOTE to FIXME).
let updateTagType = (tags: array<mriTag>, id: int, newType: mriTagType): array<mriTag> => {
  tags->Array.map(t =>
    if t.id === id {
      {...t, tagType: newType}
    } else {
      t
    }
  )
}

// ===========================================================================
// Filtering — used by the UI and by policy matching
// ===========================================================================

/// Filter tags by type.
let filterByType = (tags: array<mriTag>, tagType: mriTagType): array<mriTag> => {
  tags->Array.filter(t => t.tagType === tagType)
}

/// Filter to unresolved tags only.
let filterUnresolved = (tags: array<mriTag>): array<mriTag> => {
  tags->Array.filter(t => !t.resolved)
}

/// Filter by attribution agent (e.g., show only AI-created tags).
let filterByAgent = (tags: array<mriTag>, agent: string): array<mriTag> => {
  tags->Array.filter(t => t.attribution.agent === agent)
}

/// Get tags overlapping a specific line (for inline display).
let tagsAtLine = (tags: array<mriTag>, line: int): array<mriTag> => {
  tags->Array.filter(t => t.startLine <= line && t.endLine >= line)
}

/// Get tags within a line range (for region queries).
let tagsInRange = (tags: array<mriTag>, startLine: int, endLine: int): array<mriTag> => {
  tags->Array.filter(t => t.startLine <= endLine && t.endLine >= startLine)
}

// ===========================================================================
// Summary computation — feeds Provenance Map bar and Vexometer
// ===========================================================================

/// Compute summary statistics for a file's tags.
let computeSummary = (tags: array<mriTag>): mriFileSummary => {
  let unresolved = tags->Array.filter(t => !t.resolved)
  {
    totalTags: Array.length(tags),
    unresolvedTags: Array.length(unresolved),
    todoCount: Array.length(tags->Array.filter(t => t.tagType === Todo)),
    fixmeCount: Array.length(tags->Array.filter(t => t.tagType === Fixme)),
    careOnRegions: Array.length(tags->Array.filter(t => t.tagType === CareOn)),
    ecoModeRegions: Array.length(tags->Array.filter(t => t.tagType === EcoMode)),
    burdenRegions: Array.length(tags->Array.filter(t => t.tagType === Burden)),
    aiTagCount: Array.length(tags->Array.filter(t => t.attribution.agent !== "human")),
    humanTagCount: Array.length(tags->Array.filter(t => t.attribution.agent === "human")),
  }
}

// ===========================================================================
// Display helpers — labels, colours, icons for the UI layer
// ===========================================================================

/// Human-readable label for a tag type.
let tagTypeLabel = (tagType: mriTagType): string => {
  switch tagType {
  | Todo => "TODO"
  | Fixme => "FIXME"
  | Refactor => "REFACTOR"
  | Note => "NOTE"
  | Question => "QUESTION"
  | Warn => "WARN"
  | Review => "REVIEW"
  | CareOn => "CARE-ON"
  | EcoMode => "ECO-MODE"
  | Burden => "BURDEN"
  | Custom(name) => String.toUpperCase(name)
  }
}

/// Short label for compact display (tag chips, gutter markers).
let tagTypeShort = (tagType: mriTagType): string => {
  switch tagType {
  | Todo => "TD"
  | Fixme => "FX"
  | Refactor => "RF"
  | Note => "NT"
  | Question => "Q?"
  | Warn => "WN"
  | Review => "RV"
  | CareOn => "C!"
  | EcoMode => "EC"
  | Burden => "BU"
  | Custom(_) => "CU"
  }
}

/// Tailwind colour classes for tag type (bg, text, border).
let tagTypeColour = (tagType: mriTagType): (string, string, string) => {
  switch tagType {
  | Todo => ("bg-blue-900/50", "text-blue-400", "border-blue-700")
  | Fixme => ("bg-red-900/50", "text-red-400", "border-red-700")
  | Refactor => ("bg-amber-900/50", "text-amber-400", "border-amber-700")
  | Note => ("bg-gray-800", "text-gray-400", "border-gray-700")
  | Question => ("bg-purple-900/50", "text-purple-400", "border-purple-700")
  | Warn => ("bg-orange-900/50", "text-orange-400", "border-orange-700")
  | Review => ("bg-cyan-900/50", "text-cyan-400", "border-cyan-700")
  | CareOn => ("bg-pink-900/50", "text-pink-400", "border-pink-700")
  | EcoMode => ("bg-emerald-900/50", "text-emerald-400", "border-emerald-700")
  | Burden => ("bg-yellow-900/50", "text-yellow-400", "border-yellow-700")
  | Custom(_) => ("bg-indigo-900/50", "text-indigo-400", "border-indigo-700")
  }
}

/// Whether a tag type is modal (changes system behaviour, not just annotates).
let isModalTag = (tagType: mriTagType): bool => {
  switch tagType {
  | CareOn | EcoMode | Burden => true
  | _ => false
  }
}

/// Attribution method label.
let methodLabel = (method: mriInputMethod): string => {
  switch method {
  | Voice => "voice"
  | Keyboard => "keyboard"
  | Agent(name) => `agent:${name}`
  | Import(source) => `import:${source}`
  | Api => "api"
  }
}

/// ARIA label for a tag (screen reader accessibility).
let tagAriaLabel = (tag: mriTag): string => {
  let typeStr = tagTypeLabel(tag.tagType)
  let lineStr =
    tag.startLine === tag.endLine
      ? `line ${Int.toString(tag.startLine)}`
      : `lines ${Int.toString(tag.startLine)} to ${Int.toString(tag.endLine)}`
  let resolvedStr = tag.resolved ? ", resolved" : ""
  let msgStr = switch tag.message {
  | Some(m) => `: ${m}`
  | None => ""
  }
  `Tag ${Int.toString(tag.id)}, ${typeStr} at ${lineStr}${msgStr}${resolvedStr}`
}

// ===========================================================================
// Voice command parsing — simple grammar for voice input
// ===========================================================================

/// Parsed voice command — the result of interpreting a voice transcript.
type voiceCommand =
  | TagRange(int, int, mriTagType, option<string>)
  | TagSelection(mriTagType, option<string>)
  | EditTag(int)
  | DeleteTag(int)
  | ResolveTag(int)
  | ShowTag(int)
  | ShowAll(option<mriTagType>)
  | WhoWroteLine(int)
  | AttributeHuman
  | AttributeAi(string)
  | VoiceUnrecognised(string)

/// Parse a tag type from a spoken word.
let parseTagType = (word: string): option<mriTagType> => {
  switch String.toLowerCase(word) {
  | "todo" | "to-do" | "to do" => Some(Todo)
  | "fixme" | "fix me" | "fix" => Some(Fixme)
  | "refactor" => Some(Refactor)
  | "note" => Some(Note)
  | "question" => Some(Question)
  | "warn" | "warning" => Some(Warn)
  | "review" => Some(Review)
  | "care on" | "care-on" | "careful" => Some(CareOn)
  | "eco" | "eco mode" | "eco-mode" | "green" => Some(EcoMode)
  | "burden" | "burdened" => Some(Burden)
  | _ => None
  }
}

/// Parse a simple integer from a string, returning None on failure.
let parseInt = (s: string): option<int> => {
  let n = Int.fromString(s)
  n
}

/// Parse a voice transcript into a command.
///
/// Grammar (intentionally simple — no complex NLP, just keyword matching):
///   "line <N> to <M> tag <type> [message...]"
///   "tag <type> [message...]"           (uses current selection)
///   "edit tag <N>"
///   "delete tag <N>"
///   "resolve tag <N>"
///   "show tag <N>"
///   "show all [type]"
///   "who wrote line <N>"
///   "attribute human"
///   "attribute ai <model>"
let parseVoiceCommand = (transcript: string): voiceCommand => {
  let words =
    transcript
    ->String.toLowerCase
    ->String.trim
    ->String.split(" ")
    ->Array.filter(w => w !== "")

  let len = Array.length(words)

  // "line N to M tag TYPE [message]"
  if len >= 6 {
    let w0 = words->Array.getUnsafe(0)
    let w1 = words->Array.getUnsafe(1)
    let w2 = words->Array.getUnsafe(2)
    let w3 = words->Array.getUnsafe(3)
    let w4 = words->Array.getUnsafe(4)
    let w5 = words->Array.getUnsafe(5)
    if w0 === "line" && w2 === "to" && w4 === "tag" {
      switch (parseInt(w1), parseInt(w3), parseTagType(w5)) {
      | (Some(start), Some(end_), Some(tagType)) => {
          let msg = if len > 6 {
            Some(words->Array.sliceToEnd(~start=6)->Array.join(" "))
          } else {
            None
          }
          TagRange(start, end_, tagType, msg)
        }
      | _ => VoiceUnrecognised(transcript)
      }
    } else {
      // Fall through to shorter patterns
      VoiceUnrecognised(transcript)
    }
  } else if len >= 2 {
    let w0 = words->Array.getUnsafe(0)
    let w1 = words->Array.getUnsafe(1)

    // "tag TYPE [message]"
    if w0 === "tag" {
      switch parseTagType(w1) {
      | Some(tagType) => {
          let msg = if len > 2 {
            Some(words->Array.sliceToEnd(~start=2)->Array.join(" "))
          } else {
            None
          }
          TagSelection(tagType, msg)
        }
      | None => VoiceUnrecognised(transcript)
      }
    } // "edit tag N"
    else if w0 === "edit" && w1 === "tag" && len >= 3 {
      switch parseInt(words->Array.getUnsafe(2)) {
      | Some(n) => EditTag(n)
      | None => VoiceUnrecognised(transcript)
      }
    } // "delete tag N"
    else if w0 === "delete" && w1 === "tag" && len >= 3 {
      switch parseInt(words->Array.getUnsafe(2)) {
      | Some(n) => DeleteTag(n)
      | None => VoiceUnrecognised(transcript)
      }
    } // "resolve tag N"
    else if w0 === "resolve" && w1 === "tag" && len >= 3 {
      switch parseInt(words->Array.getUnsafe(2)) {
      | Some(n) => ResolveTag(n)
      | None => VoiceUnrecognised(transcript)
      }
    } // "show tag N"
    else if w0 === "show" && w1 === "tag" && len >= 3 {
      switch parseInt(words->Array.getUnsafe(2)) {
      | Some(n) => ShowTag(n)
      | None => VoiceUnrecognised(transcript)
      }
    } // "show all [type]"
    else if w0 === "show" && w1 === "all" {
      if len >= 3 {
        ShowAll(parseTagType(words->Array.getUnsafe(2)))
      } else {
        ShowAll(None)
      }
    } // "who wrote line N"
    else if w0 === "who" && w1 === "wrote" && len >= 4 {
      let w3 = words->Array.getUnsafe(3)
      switch parseInt(w3) {
      | Some(n) => WhoWroteLine(n)
      | None => VoiceUnrecognised(transcript)
      }
    } // "attribute human"
    else if w0 === "attribute" && w1 === "human" {
      AttributeHuman
    } // "attribute ai MODEL"
    else if w0 === "attribute" && w1 === "ai" && len >= 3 {
      AttributeAi(words->Array.getUnsafe(2))
    } else {
      VoiceUnrecognised(transcript)
    }
  } else {
    VoiceUnrecognised(transcript)
  }
}

// ===========================================================================
// .mri.json serialisation — portable format, no PanLL dependency
// ===========================================================================

/// Serialise a tag type to its JSON string representation.
let tagTypeToString = (tagType: mriTagType): string => {
  switch tagType {
  | Todo => "todo"
  | Fixme => "fixme"
  | Refactor => "refactor"
  | Note => "note"
  | Question => "question"
  | Warn => "warn"
  | Review => "review"
  | CareOn => "care-on"
  | EcoMode => "eco-mode"
  | Burden => "burden"
  | Custom(name) => `custom:${name}`
  }
}

/// Parse a tag type from its JSON string representation.
let tagTypeFromString = (s: string): mriTagType => {
  switch s {
  | "todo" => Todo
  | "fixme" => Fixme
  | "refactor" => Refactor
  | "note" => Note
  | "question" => Question
  | "warn" => Warn
  | "review" => Review
  | "care-on" => CareOn
  | "eco-mode" => EcoMode
  | "burden" => Burden
  | other =>
    if String.startsWith(other, "custom:") {
      Custom(String.sliceToEnd(other, ~start=7))
    } else {
      Custom(other)
    }
  }
}

/// Serialise input method to string.
let methodToString = (method: mriInputMethod): string => {
  switch method {
  | Voice => "voice"
  | Keyboard => "keyboard"
  | Agent(name) => `agent:${name}`
  | Import(source) => `import:${source}`
  | Api => "api"
  }
}

/// Parse input method from string.
let methodFromString = (s: string): mriInputMethod => {
  switch s {
  | "voice" => Voice
  | "keyboard" => Keyboard
  | "api" => Api
  | other =>
    if String.startsWith(other, "agent:") {
      Agent(String.sliceToEnd(other, ~start=6))
    } else if String.startsWith(other, "import:") {
      Import(String.sliceToEnd(other, ~start=7))
    } else {
      Keyboard
    }
  }
}

// ===========================================================================
// Default state
// ===========================================================================

/// Empty summary (no tags).
let emptySummary: mriFileSummary = {
  totalTags: 0,
  unresolvedTags: 0,
  todoCount: 0,
  fixmeCount: 0,
  careOnRegions: 0,
  ecoModeRegions: 0,
  burdenRegions: 0,
  aiTagCount: 0,
  humanTagCount: 0,
}

/// Default VoiceTag state — no file loaded, voice off, no tags.
let defaultState: voiceTagState = {
  currentFile: None,
  tags: [],
  voice: VoiceOff,
  selectedTagId: None,
  filterType: None,
  showResolved: false,
  summary: emptySummary,
  error: None,
}
