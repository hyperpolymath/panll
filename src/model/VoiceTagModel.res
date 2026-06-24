// SPDX-License-Identifier: MPL-2.0

/// Code MRI — VoiceTag Model (Layer 0)
///
/// Types for the annotation/tagging system that forms the foundation of Code MRI
/// (Mutual Recognition & Integrity). Tags are stored as `.mri.json` sidecar files
/// alongside source files — a portable, editor-agnostic format that any tool can
/// read and write. PanLL adds voice input, agentic policy, provenance integration,
/// and the full Code MRI timeline on top.
///
/// STANDALONE-FIRST: The `.mri.json` format is designed so that someone who never
/// installs PanLL can still use Code MRI tags with a CLI tool, VS Code extension,
/// Vim plugin, or anything that reads JSON. PanLL is one consumer of this format,
/// not the gatekeeper. If someone builds a better Code MRI viewer, the data is
/// theirs — no lock-in.
///
/// Tag types fall into three categories:
///   Standard  — TODO, FIXME, REFACTOR, NOTE, QUESTION, WARN, REVIEW
///   Modal     — CARE_ON, ECO_MODE, BURDEN (change system behaviour, not just annotate)
///   Custom    — user-defined tag types for project-specific concerns

/// Standard annotation tag types plus modal tags that affect system behaviour.
/// Modal tags (CareOn, EcoMode, Burden) are part of DD-017 — they adjust
/// panic-attack sensitivity, triaxial priority scoring, and constraint tuning.
type mriTagType =
  | Todo
  | Fixme
  | Refactor
  | Note
  | Question
  | Warn
  | Review
  | CareOn
  | EcoMode
  | Burden
  | Custom(string)

/// How the tag was created — voice, keyboard, agent, or imported from another tool.
/// This attribution is on the TAG ITSELF, not the code it annotates. "Who said this
/// region needs attention?" is different from "Who wrote this code?" — both matter.
type mriInputMethod =
  | Voice
  | Keyboard
  | Agent(string)
  | Import(string)
  | Api

/// Who created this tag and how.
type mriAttribution = {
  agent: string,
  method: mriInputMethod,
  timestamp: float,
  sessionId: option<string>,
}

/// Who wrote the code that a tag annotates (not the tag itself).
/// This feeds the Provenance Map and the "Turnitin-but-honest" authorship tracking.
type mriCodeAuthor = {
  author: string,
  email: string,
  isAi: bool,
  aiModel: option<string>,
  coAuthored: bool,
  coAuthor: option<string>,
}

/// A single Code MRI tag — the atomic unit of annotation.
///
/// Tags are numbered per file for easy voice reference ("delete tag 3", "show tag 7").
/// The number is stable within a session but may be reassigned if tags are deleted
/// and the file is compacted. For persistent cross-session references, use the
/// combination of (file, startLine, endLine, tagType).
type mriTag = {
  id: int,
  startLine: int,
  endLine: int,
  tagType: mriTagType,
  message: option<string>,
  attribution: mriAttribution,
  codeAuthor: option<mriCodeAuthor>,
  resolved: bool,
  resolvedBy: option<mriAttribution>,
}

/// Summary statistics for a file's tags — displayed in the Provenance Map bar
/// and used by the Vexometer to calculate annotation-based friction.
type mriFileSummary = {
  totalTags: int,
  unresolvedTags: int,
  todoCount: int,
  fixmeCount: int,
  careOnRegions: int,
  ecoModeRegions: int,
  burdenRegions: int,
  aiTagCount: int,
  humanTagCount: int,
}

/// The `.mri.json` sidecar file format — portable, editor-agnostic, no PanLL
/// dependency. Version field ensures forward compatibility.
///
/// File naming convention: `<source-file>.mri.json`
/// Example: `Model.res` → `Model.res.mri.json`
///
/// The format is intentionally simple so that a 20-line Python script or a
/// jq command can create and query tags. PanLL's voice/agent/provenance layers
/// are value-add, not requirements.
type mriFile = {
  version: string,
  sourceFile: string,
  tags: array<mriTag>,
  lastModified: float,
  totalLines: option<int>,
}

/// Voice recognition state — uses browser-native Web Speech API.
/// No external service, no API key, no network dependency.
type voiceState =
  | VoiceOff
  | VoiceListening
  | VoiceProcessing(string)
  | VoiceError(string)

/// The complete VoiceTag panel state within PanLL.
type voiceTagState = {
  /// Tags for the currently viewed file (loaded from .mri.json sidecar)
  currentFile: option<string>,
  tags: array<mriTag>,
  /// Voice input state
  voice: voiceState,
  /// UI state
  selectedTagId: option<int>,
  filterType: option<mriTagType>,
  showResolved: bool,
  /// Summary for the provenance bar
  summary: mriFileSummary,
  /// Error display
  error: option<string>,
}
