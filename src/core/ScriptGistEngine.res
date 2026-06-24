// SPDX-License-Identifier: MPL-2.0

/// PanLL ScriptGistEngine — Pure computation for the Script Gist system.
///
/// Handles gist creation, search, filtering, template expansion, token
/// estimation, MCP tool schema generation, and execution target resolution.
/// All functions are pure — side effects (save, load, execute) are in commands.

open ScriptGistModel

/// Category tab labels.
let categoryLabel = (cat: gistCategory): string =>
  switch cat {
  | GistAll => "All"
  | GistQueries => "Queries"
  | GistProofs => "Proofs"
  | GistAutomation => "Automation"
  | GistConfig => "Config"
  | GistTemplates => "Templates"
  }

/// All category tabs.
let allCategories: array<gistCategory> = [
  GistAll,
  GistQueries,
  GistProofs,
  GistAutomation,
  GistConfig,
  GistTemplates,
]

/// Language label for display.
let languageLabel = (lang: gistLanguage): string =>
  switch lang {
  | GistVcl => "VCL"
  | GistKql => "KQL"
  | GistGql => "GQL"
  | GistReScript => "ReScript"
  | GistGleam => "Gleam"
  | GistIdris2 => "Idris2"
  | GistNickel => "Nickel"
  | GistShell => "Shell"
  | GistOcl => "OCL"
  }

/// Language file extension.
let languageExt = (lang: gistLanguage): string =>
  switch lang {
  | GistVcl => ".vcl"
  | GistKql => ".kql"
  | GistGql => ".gql"
  | GistReScript => ".res"
  | GistGleam => ".gleam"
  | GistIdris2 => ".idr"
  | GistNickel => ".ncl"
  | GistShell => ".sh"
  | GistOcl => ".ocl"
  }

/// CSS colour class for language badge.
let languageColour = (lang: gistLanguage): string =>
  switch lang {
  | GistVcl | GistKql | GistGql => "text-cyan-400"
  | GistReScript => "text-red-400"
  | GistGleam => "text-pink-400"
  | GistIdris2 => "text-purple-400"
  | GistNickel => "text-amber-400"
  | GistShell => "text-green-400"
  | GistOcl => "text-blue-400"
  }

/// Resolve the default execution target for a language.
let defaultTarget = (lang: gistLanguage): gistTarget =>
  switch lang {
  | GistVcl | GistKql | GistGql => TargetNqc
  | GistIdris2 | GistOcl => TargetEchidna
  | GistShell => TargetShell
  | GistReScript | GistGleam | GistNickel => TargetDeno
  }

/// Resolve the category a gist belongs to based on its language.
let languageCategory = (lang: gistLanguage): gistCategory =>
  switch lang {
  | GistVcl | GistKql | GistGql => GistQueries
  | GistIdris2 | GistOcl => GistProofs
  | GistShell | GistReScript => GistAutomation
  | GistNickel | GistGleam => GistConfig
  }

/// Estimate token count for a string (rough: ~4 chars per token).
let estimateTokens = (text: string): int => {
  let len = String.length(text)
  if len === 0 {
    0
  } else {
    Int.fromFloat(Math.ceil(Int.toFloat(len) /. 4.0))
  }
}

/// Generate the MCP tool schema JSON for a gist (for tool discovery).
/// This is what gets advertised to LLMs so they can invoke the gist.
let generateMcpToolJson = (gist: scriptGist): string => {
  let inputProps =
    gist.schema.inputs
    ->Array.map(p => {
      "\"" ++
      p.name ++
      "\": {\"type\": \"" ++
      p.schemaType ++
      "\", \"description\": \"" ++
      p.description ++ "\"}"
    })
    ->Array.join(", ")
  let required =
    gist.schema.inputs
    ->Array.filter(p => p.required)
    ->Array.map(p => "\"" ++ p.name ++ "\"")
    ->Array.join(", ")
  "{" ++
  "\"name\": \"" ++
  gist.schema.toolName ++
  "\", " ++
  "\"description\": \"" ++
  gist.schema.summary ++
  "\", " ++
  "\"input_schema\": {" ++
  "\"type\": \"object\", " ++
  "\"properties\": {" ++
  inputProps ++
  "}, " ++
  "\"required\": [" ++
  required ++
  "]" ++
  "}" ++ "}"
}

/// Estimate the token cost of including a gist's schema in LLM context.
let schemaTokenCost = (schema: gistSchema): int => {
  let base = estimateTokens(schema.toolName) + estimateTokens(schema.summary)
  let paramCost =
    schema.inputs->Array.reduce(0, (acc, p) =>
      acc + estimateTokens(p.name) + estimateTokens(p.description) + 5
    )
  base + paramCost + 20 // overhead for JSON structure
}

/// Expand a template by replacing `{{placeholder}}` markers with values.
let expandTemplate = (template: gistTemplate, values: array<(string, string)>): string => {
  Array.reduce(values, template.templateCode, (code, (key, value)) => {
    let placeholder = "{{" ++ key ++ "}}"
    // Manual replace since String.replaceAll may not exist
    let parts = String.split(code, placeholder)
    Array.join(parts, value)
  })
}

/// Filter gists by category.
let filterByCategory = (gists: array<scriptGist>, cat: gistCategory): array<scriptGist> =>
  switch cat {
  | GistAll => gists
  | GistTemplates => [] // Templates are separate
  | cat => gists->Array.filter(g => languageCategory(g.language) === cat)
  }

/// Filter gists by search text (matches title, tags, tool name).
let filterBySearch = (gists: array<scriptGist>, query: string): array<scriptGist> => {
  if String.trim(query) === "" {
    gists
  } else {
    let q = String.toLowerCase(query)
    gists->Array.filter(g => {
      String.includes(String.toLowerCase(g.title), q) ||
      String.includes(String.toLowerCase(g.schema.toolName), q) ||
      g.tags->Array.some(t => String.includes(String.toLowerCase(t), q))
    })
  }
}

/// Sort gists.
let sortGists = (gists: array<scriptGist>, sortBy: gistSortBy): array<scriptGist> => {
  let sorted = Array.copy(gists)
  sorted->Array.sort((a, b) =>
    switch sortBy {
    | SortByName => String.compare(a.title, b.title)
    | SortByModified => Float.compare(b.modifiedAt, a.modifiedAt)
    | SortByLanguage => String.compare(languageLabel(a.language), languageLabel(b.language))
    | SortByRunCount => Int.compare(Array.length(b.history), Array.length(a.history))
    }
  )
  sorted
}

/// Find a gist by ID.
let findGist = (gists: array<scriptGist>, id: string): option<scriptGist> =>
  gists->Array.find(g => g.id === id)

/// Count gists by category.
let countByCategory = (gists: array<scriptGist>, cat: gistCategory): int =>
  filterByCategory(gists, cat)->Array.length

/// Visibility label.
let visibilityLabel = (vis: gistVisibility): string =>
  switch vis {
  | Private => "Private"
  | Local => "Local"
  | Repo => "Repo"
  | Published => "Published"
  }

/// Target label.
let targetLabel = (target: gistTarget): string =>
  switch target {
  | TargetDeno => "Deno Sandbox"
  | TargetNqc => "NQC Proxy"
  | TargetEchidna => "ECHIDNA"
  | TargetBoj(cart) => "BoJ: " ++ cart
  | TargetShell => "Shell"
  }

/// Create a new empty gist with sensible defaults.
let newGist = (id: string, title: string, language: gistLanguage): scriptGist => {
  {
    id,
    title,
    code: "",
    language,
    schema: {
      toolName: String.replaceAll(String.toLowerCase(title), " ", "-"),
      summary: title,
      inputs: [],
      outputDescription: "Execution result",
      estimatedTokens: 0,
    },
    target: defaultTarget(language),
    visibility: Private,
    version: 1,
    tags: [],
    createdAt: Date.now(),
    modifiedAt: Date.now(),
    history: [],
    pinned: false,
  }
}

/// Built-in templates for common operations.
let builtinTemplates: array<gistTemplate> = [
  {
    id: "tpl-vcl-query",
    name: "VCL Query",
    description: "VeriSimDB entity query with modality filter",
    templateCode: "SELECT * FROM entities\nWHERE modality = '{{modality}}'\nLIMIT {{limit}};",
    language: GistVcl,
    target: TargetNqc,
    placeholders: ["modality", "limit"],
  },
  {
    id: "tpl-ocl-invariant",
    name: "OCL Invariant",
    description: "OCL invariant constraint for enterprise model checking",
    templateCode: "context {{context}}\ninv {{name}}:\n  {{expression}}",
    language: GistOcl,
    target: TargetEchidna,
    placeholders: ["context", "name", "expression"],
  },
  {
    id: "tpl-proof-obligation",
    name: "Proof Obligation",
    description: "Idris2 proof obligation for ECHIDNA dispatch",
    templateCode: "module {{module}}\n\n{{name}} : {{type}}\n{{name}} = {{proof}}",
    language: GistIdris2,
    target: TargetEchidna,
    placeholders: ["module", "name", "type", "proof"],
  },
  {
    id: "tpl-automation-rule",
    name: "Automation Script",
    description: "ReScript automation script for panel orchestration",
    templateCode: "// Automation: {{description}}\nlet run = () => {\n  {{body}}\n}",
    language: GistReScript,
    target: TargetDeno,
    placeholders: ["description", "body"],
  },
  {
    id: "tpl-nickel-config",
    name: "Nickel Config",
    description: "Nickel configuration template with type contracts",
    templateCode: "let config : {{contract}} = {\n  {{fields}}\n}\nin config",
    language: GistNickel,
    target: TargetDeno,
    placeholders: ["contract", "fields"],
  },
  {
    id: "tpl-shell-health",
    name: "Health Check Script",
    description: "Shell script to check service health endpoints",
    templateCode: "#!/bin/sh\n# Health check: {{service}}\ncurl -sf {{url}}/health || exit 1\necho \"{{service}} OK\"",
    language: GistShell,
    target: TargetShell,
    placeholders: ["service", "url"],
  },
]

/// Create a diachronic checkpoint from the current gist set.
let snapshotDiachronic = (state: scriptGistState, label: string): diachronicCheckpoint => {
  let index = Array.length(state.diachronicHistory)
  {
    index,
    timestamp: Date.now(),
    label,
    snapshot: JSON.stringify(JSON.Encode.string("placeholder")), // serialised externally
  }
}

/// Create a new empty cardfile.
let newCardfile = (id: string, name: string): synchronicCardfile => {
  {
    id,
    name,
    description: "",
    gistIds: [],
    createdAt: Date.now(),
    modifiedAt: Date.now(),
    tags: [],
  }
}

/// Add a gist to a cardfile (idempotent — no duplicates).
let addGistToCardfile = (cardfile: synchronicCardfile, gistId: string): synchronicCardfile => {
  if cardfile.gistIds->Array.some(id => id === gistId) {
    cardfile
  } else {
    {
      ...cardfile,
      gistIds: Array.concat(cardfile.gistIds, [gistId]),
      modifiedAt: Date.now(),
    }
  }
}

/// Remove a gist from a cardfile.
let removeGistFromCardfile = (cardfile: synchronicCardfile, gistId: string): synchronicCardfile => {
  {
    ...cardfile,
    gistIds: cardfile.gistIds->Array.filter(id => id !== gistId),
    modifiedAt: Date.now(),
  }
}

/// Find a cardfile by ID.
let findCardfile = (cardfiles: array<synchronicCardfile>, id: string): option<synchronicCardfile> =>
  cardfiles->Array.find(cf => cf.id === id)

/// Resolve gists in a cardfile (ordered, skipping missing).
let resolveCardfileGists = (cardfile: synchronicCardfile, allGists: array<scriptGist>): array<
  scriptGist,
> => cardfile.gistIds->Array.filterMap(id => findGist(allGists, id))

/// Cardfile label for display.
let cardfileLabel = (cf: synchronicCardfile): string =>
  cf.name ++ " (" ++ Int.toString(Array.length(cf.gistIds)) ++ " cards)"

/// Default state.
let defaultState: scriptGistState = {
  gists: [],
  templates: builtinTemplates,
  selectedGistId: None,
  activeCategory: GistAll,
  filterText: "",
  sortBy: SortByModified,
  editorOpen: false,
  executing: false,
  lastResult: None,
  error: None,
  mcpToolsActive: false,
  diachronicHistory: [],
  cardfiles: [],
  selectedCardfileId: None,
}
