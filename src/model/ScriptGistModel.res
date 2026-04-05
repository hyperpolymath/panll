// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ScriptGistModel — Portable script gist types.
///
/// A Script Gist is a self-contained, addressable computation unit that can be:
///   1. Written and saved by users (like GitHub Gists)
///   2. Invoked by LLMs/SLMs as MCP tools (token-minimised schema)
///   3. Fired by Automation Router rules (trigger → gist execution)
///   4. Run standalone via `deno run` or BoJ cartridge dispatch
///   5. Shared via URL, file export, or ENSAID config embedding
///
/// Design: Each gist carries its own schema (inputs/outputs) so that tool
/// discovery protocols (MCP, OpenAI function calling, etc.) can advertise
/// it without parsing the code. The schema is the "contract"; the code is
/// the "implementation".

/// The language a gist is written in.
type gistLanguage =
  /// VeriSimDB query language — routed to NQC proxy.
  | GistVql
  /// QuandleDB knowledge queries — routed to NQC proxy.
  | GistKql
  /// LithoGlyph graph queries — routed to NQC proxy.
  | GistGql
  /// ReScript — compiled to JS, executed in Deno sandbox.
  | GistReScript
  /// Gleam — compiled to JS, executed in Deno sandbox.
  | GistGleam
  /// Idris2 — interpreted or compiled, executed via ECHIDNA dispatch.
  | GistIdris2
  /// Nickel — configuration language, evaluated to JSON.
  | GistNickel
  /// Shell — POSIX sh, executed in sandboxed subprocess.
  | GistShell
  /// OCL — Object Constraint Language, dispatched to ECHIDNA for model checking.
  | GistOcl

/// Schema parameter for tool discovery (MCP / function calling).
type gistParam = {
  /// Parameter name (must be a valid identifier).
  name: string,
  /// Human-readable description for LLM context.
  description: string,
  /// JSON Schema type string ("string", "number", "boolean", "object", "array").
  schemaType: string,
  /// Whether this parameter is required.
  required: bool,
  /// Default value as JSON string, if any.
  defaultValue: option<string>,
}

/// The tool schema that makes a gist discoverable by LLMs.
type gistSchema = {
  /// Tool name (kebab-case, globally unique within a workspace).
  toolName: string,
  /// One-line description (shown in tool listings, kept short for token budget).
  summary: string,
  /// Input parameters.
  inputs: array<gistParam>,
  /// Output description (what the gist returns).
  outputDescription: string,
  /// Estimated token cost of including this schema in an LLM context window.
  estimatedTokens: int,
}

/// Execution target — where the gist runs.
type gistTarget =
  /// Local Deno sandbox (default for most languages).
  | TargetDeno
  /// NQC database proxy (for VCL/KQL/GQL).
  | TargetNqc
  /// ECHIDNA prover backend (for Idris2/OCL).
  | TargetEchidna
  /// BoJ cartridge dispatch (for remote/federated execution).
  | TargetBoj(string) // cartridge name
  /// Shell subprocess (sandboxed).
  | TargetShell

/// Visibility level for sharing.
type gistVisibility =
  /// Only visible in this workspace.
  | Private
  /// Visible to all workspaces on this machine.
  | Local
  /// Exported to `.panll/gists/` for version control.
  | Repo
  /// Published with a shareable URL.
  | Published

/// A single execution result.
type gistResult = {
  /// Whether execution succeeded.
  success: bool,
  /// The output (stdout, query result, proof result, etc.).
  output: string,
  /// Error message, if any.
  error: option<string>,
  /// Execution duration in milliseconds.
  durationMs: float,
  /// Timestamp of execution (Unix ms).
  executedAt: float,
  /// Who invoked it: "user", "automation:rule-id", "llm:claude", etc.
  invoker: string,
}

/// A Script Gist — the core entity.
type scriptGist = {
  /// Unique identifier (UUID or content-addressable hash).
  id: string,
  /// Human-readable title.
  title: string,
  /// The gist source code.
  code: string,
  /// Language the gist is written in.
  language: gistLanguage,
  /// Tool schema for LLM/MCP discovery.
  schema: gistSchema,
  /// Execution target.
  target: gistTarget,
  /// Visibility/sharing level.
  visibility: gistVisibility,
  /// Version counter (incremented on save).
  version: int,
  /// Tags for categorisation and search.
  tags: array<string>,
  /// When the gist was created (Unix ms).
  createdAt: float,
  /// When the gist was last modified (Unix ms).
  modifiedAt: float,
  /// Last N execution results (ring buffer).
  history: array<gistResult>,
  /// Whether this gist is pinned to the quick-access bar.
  pinned: bool,
}

/// Template for formulaic gist creation (token-minimised patterns).
type gistTemplate = {
  /// Template identifier.
  id: string,
  /// Template name.
  name: string,
  /// Description of what this template produces.
  description: string,
  /// The template code with `{{placeholder}}` markers.
  templateCode: string,
  /// Language for generated gists.
  language: gistLanguage,
  /// Default target for generated gists.
  target: gistTarget,
  /// Placeholder names that must be filled.
  placeholders: array<string>,
}

/// Category tabs for the gist browser.
type gistCategory =
  /// All gists in a flat list.
  | GistAll
  /// Database queries (VCL/KQL/GQL).
  | GistQueries
  /// Proof scripts (Idris2/OCL).
  | GistProofs
  /// Automation scripts (ReScript/Shell).
  | GistAutomation
  /// Configuration templates (Nickel/Gleam).
  | GistConfig
  /// Templates for formulaic creation.
  | GistTemplates

/// Sort order for the gist list.
type gistSortBy =
  | SortByName
  | SortByModified
  | SortByLanguage
  | SortByRunCount

/// Minskian diachronic checkpoint — time-based state snapshot for rollback.
/// Named after Minsky's Society of Mind: scripts capture temporal sequences.
type diachronicCheckpoint = {
  /// Checkpoint index (sequential).
  index: int,
  /// Timestamp of snapshot (Unix ms).
  timestamp: float,
  /// Label for this checkpoint (auto-generated or user-provided).
  label: string,
  /// Serialised gist state at this point in time.
  snapshot: string,
}

/// Minskian synchronic cardfile — space-based composition of gists.
/// Named after Minsky's K-lines: schemata capture structural arrangements.
/// A cardfile is an ordered collection of gist references that together form
/// a composable workspace — like index cards pinned to a board.
type synchronicCardfile = {
  /// Unique cardfile identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Description of what this cardfile represents.
  description: string,
  /// Ordered list of gist IDs in this cardfile.
  gistIds: array<string>,
  /// When the cardfile was created (Unix ms).
  createdAt: float,
  /// When the cardfile was last modified (Unix ms).
  modifiedAt: float,
  /// Tags for categorisation.
  tags: array<string>,
}

/// State of the Script Gist subsystem.
type scriptGistState = {
  /// All gists in the workspace.
  gists: array<scriptGist>,
  /// Available templates for quick creation.
  templates: array<gistTemplate>,
  /// Currently selected gist (for editing/viewing).
  selectedGistId: option<string>,
  /// Active category tab.
  activeCategory: gistCategory,
  /// Search/filter text.
  filterText: string,
  /// Sort order.
  sortBy: gistSortBy,
  /// Whether the gist editor is open.
  editorOpen: bool,
  /// Whether a gist is currently executing.
  executing: bool,
  /// Last execution result (for the status bar).
  lastResult: option<gistResult>,
  /// Error from save/load operations.
  error: option<string>,
  /// Whether the MCP tool registry is active (advertising gists as tools).
  mcpToolsActive: bool,
  /// Diachronic checkpoints — time-based rollback stack (Minskian scripts).
  diachronicHistory: array<diachronicCheckpoint>,
  /// Synchronic cardfiles — space-based gist compositions (Minskian schemata).
  cardfiles: array<synchronicCardfile>,
  /// Currently selected cardfile for editing.
  selectedCardfileId: option<string>,
}
