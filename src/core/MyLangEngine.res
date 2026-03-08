// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL My-Lang Engine — pure computation for the AI-native language panel.
///
/// Provides labels, colours, parsing, and display helpers for the view layer.
/// No side effects — all Tauri/CLI interaction is in MyLangCmd.

open MyLangModel

/// Human-readable label for a dialect.
let dialectLabel = (d: myLangDialect): string =>
  switch d {
  | Solo => "Solo"
  | Duet => "Duet"
  | Ensemble => "Ensemble"
  | Me => "Me"
  }

/// Short description for a dialect.
let dialectDescription = (d: myLangDialect): string =>
  switch d {
  | Solo => "Dependable systems programming"
  | Duet => "AI-assisted with verification"
  | Ensemble => "AI as first-class component"
  | Me => "Personal AI agent"
  }

/// Tailwind colour class for a dialect badge.
let dialectColour = (d: myLangDialect): string =>
  switch d {
  | Solo => "text-slate-300 bg-slate-800/50"
  | Duet => "text-sky-400 bg-sky-900/30"
  | Ensemble => "text-violet-400 bg-violet-900/30"
  | Me => "text-amber-400 bg-amber-900/30"
  }

/// All dialects.
let allDialects: array<myLangDialect> = [Solo, Duet, Ensemble, Me]

/// Category tab label.
let categoryLabel = (cat: myLangCategory): string =>
  switch cat {
  | MlEditor => "Editor"
  | MlRepl => "REPL"
  | MlCompile => "Compile"
  | MlDialects => "Dialects"
  }

/// All category tabs.
let allCategories: array<myLangCategory> = [MlEditor, MlRepl, MlCompile, MlDialects]

/// Parse a dialect string.
let parseDialect = (s: string): myLangDialect =>
  switch String.toLowerCase(s) {
  | "solo" => Solo
  | "duet" => Duet
  | "ensemble" => Ensemble
  | "me" => Me
  | _ => Solo
  }

/// Parse a compilation result from JSON.
let parseCompilation = (json: string): result<compilationResult, string> => {
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
          success: getBool("success"),
          output: getString("output"),
          diagnostics: getString("diagnostics"),
          errorCount: getInt("error_count"),
          warningCount: getInt("warning_count"),
          compileTimeMs: getInt("compile_time_ms"),
        })
      }
    | _ => Error("Expected JSON object for compilation result")
    }
  } catch {
  | _ => Error("Failed to parse compilation JSON")
  }
}

/// File extension for a dialect's source files.
let dialectExtension = (d: myLangDialect): string =>
  switch d {
  | Solo => ".solo"
  | Duet => ".duet"
  | Ensemble => ".ens"
  | Me => ".me"
  }

/// Example starter code for each dialect.
let dialectExample = (d: myLangDialect): string =>
  switch d {
  | Solo => "// Solo — safe systems programming\nfn main() -> i32 {\n  let x: i32 = 42\n  x\n}\n"
  | Duet => "// Duet — AI-assisted with verification\n@verify\nfn sort(xs: List[i32]) -> List[i32] {\n  // AI suggests implementation\n  xs.sorted()\n}\n"
  | Ensemble => "// Ensemble — AI as first-class component\nagent greeter {\n  fn greet(name: String) -> String {\n    \"Hello, {name}!\"\n  }\n}\n"
  | Me => "// Me — personal AI agent\nme {\n  remember \"context\"\n  when asked(q) -> respond(q)\n}\n"
  }

/// Default initial state.
let defaultState: myLangState = {
  cliAvailable: false,
  loading: false,
  error: None,
  activeCategory: MlEditor,
  activeDialect: Solo,
  editorContent: "// Solo — safe systems programming\nfn main() -> i32 {\n  let x: i32 = 42\n  x\n}\n",
  replInput: "",
  replHistory: [],
  lastCompilation: None,
  lastTypeCheck: None,
  lspConnected: false,
  lspDiagnostics: [],
  replSessions: [],
}
