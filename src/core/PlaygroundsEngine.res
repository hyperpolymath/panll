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
  | LangVql => "VQL"
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
  | LangVql => ".vql"
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
  | LangVql | LangKql | LangGql => true
  | _ => false
  }

/// Built-in tutorial snippets.
let defaultSnippets: array<snippet> = [
  {
    id: "vql-hello",
    title: "VQL: Hello VeriSimDB",
    code: "SELECT * FROM hexads LIMIT 10;",
    language: LangVql,
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
  activeLanguage: LangVql,
  editorContent: "",
  lastResult: None,
  executing: false,
  error: None,
  snippets: defaultSnippets,
  nqcConnected: false,
}
