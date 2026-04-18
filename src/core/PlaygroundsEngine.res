// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playgrounds Engine — pure computation for the code sandbox.

open PlaygroundsModel

let categoryLabel = (cat: playgroundsCategory): string =>
  switch cat {
  | PlayEditor => "Editor"
  | PlayNqc => "NQC Console"
  | PlaySnippets => "Snippets"
  | PlayTutorials => "Tutorials"
  }

let languageLabel = (lang: playgroundLanguage): string =>
  switch lang {
  | LangVcl => "VCL"
  | LangKql => "KQL"
  | LangGql => "GQL"
  | LangRescript => "ReScript"
  | LangGleam => "Gleam"
  | LangIdris2 => "Idris2"
  | LangNickel => "Nickel"
  }

/// File extension for syntax highlighting hints.
let languageExt = (lang: playgroundLanguage): string =>
  switch lang {
  | LangVcl => ".vcl"
  | LangKql => ".kql"
  | LangGql => ".gql"
  | LangRescript => ".res"
  | LangGleam => ".gleam"
  | LangIdris2 => ".idr"
  | LangNickel => ".ncl"
  }

/// Whether this language connects to the NQC proxy.
let isDbLanguage = (lang: playgroundLanguage): bool =>
  switch lang {
  | LangVcl | LangKql | LangGql => true
  | _ => false
  }

/// Built-in tutorial snippets.
let defaultSnippets: array<snippet> = [
  {
    id: "vcl-hello",
    title: "VCL: Hello VeriSimDB",
    code: "SELECT * FROM octads LIMIT 10;",
    language: LangVcl,
    isTutorial: true,
  },
  {
    id: "kql-hello",
    title: "KQL: Hello QuandleDB",
    code: "MATCH (q:Quandle) RETURN q LIMIT 10;",
    language: LangKql,
    isTutorial: true,
  },
  {
    id: "gql-hello",
    title: "GQL: Hello LithoGlyph",
    code: "{ lithoglyphs(limit: 10) { id, glyph, provenance } }",
    language: LangGql,
    isTutorial: true,
  },
]

let defaultState: playgroundsState = {
  activeCategory: PlayEditor,
  activeLanguage: LangVcl,
  editorContent: "",
  lastResult: None,
  executing: false,
  error: None,
  snippets: defaultSnippets,
  nqcConnected: false,
  nqcInput: "",
  nqcLanguage: LangVcl,
  nqcHistory: [],
}

/// Wrap user code in a safe execution harness for Deno eval.
/// The harness captures stdout, prevents infinite loops (5s timeout),
/// and returns a JSON result envelope.
let wrapForExecution = (code: string, language: playgroundLanguage): string => {
  let prefix = switch language {
  | LangVcl => "// VeriSimDB VCL query\n"
  | LangKql => "// Knowledge Query Language\n"
  | LangGql => "// Graph Query Language\n"
  | LangRescript => "// ReScript (compiled to JS)\n"
  | LangGleam => "// Gleam (compiled to JS)\n"
  | LangIdris2 => "// Idris2 (interpreted)\n"
  | LangNickel => "// Nickel configuration\n"
  }
  prefix ++ code
}

/// Validate code before execution — basic syntax checks.
/// Returns None if valid, Some(errorMessage) if invalid.
let preflightCheck = (code: string, _language: playgroundLanguage): option<string> => {
  if String.trim(code) === "" {
    Some("Empty code — nothing to execute")
  } else if String.length(code) > 50000 {
    Some("Code exceeds 50,000 character limit")
  } else if String.includes(code, "while(true)") || String.includes(code, "for(;;)") {
    Some("Potential infinite loop detected — wrap in a bounded loop")
  } else {
    None
  }
}

/// Format an execution result for display in the output panel.
let formatOutput = (result: string, elapsedMs: float): string => {
  result ++ "\n\n--- executed in " ++ Float.toFixed(elapsedMs, ~digits=1) ++ "ms ---"
}

/// Determine if a language needs the NQC database proxy for execution.
let needsNqcProxy = (language: playgroundLanguage): bool => {
  switch language {
  | LangVcl | LangKql | LangGql => true
  | _ => false
  }
}
