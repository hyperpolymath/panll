// SPDX-License-Identifier: MPL-2.0

/// HelpEngine — Pure functional engine for the PanLL help system.
///
/// Contains all logic for searching, filtering, and navigating help content.
/// Operates on data from HelpModel and HelpContent, keeping all state
/// transformations pure and side-effect free.
///
/// The help system supports:
/// - Full-text search across titles, bodies, and keywords
/// - Category-based filtering (GettingStarted, Glossary, PanelGuide, Shortcuts, Faq, Architecture)
/// - Panel-scoped contextual help
/// - A glossary of neurosymbolic terminology
/// - An 8-step onboarding walkthrough for new users
///
/// All functions are deterministic — given the same inputs, they always
/// produce the same outputs. No side effects, no mutation.

/// Returns the standard 8-step onboarding walkthrough for new PanLL users.
///
/// The walkthrough introduces users to the core concepts of the PanLL
/// interface in a logical progression: from the overall layout, through
/// the three-panel model, the Binary Star architecture, navigation,
/// keyboard shortcuts, the glossary, contextual help, and finally
/// encouragement to explore freely.
let defaultOnboardingSteps = (): array<HelpModel.onboardingStep> => {
  [
    {
      id: "welcome",
      title: "Welcome to PanLL",
      description: "PanLL (eNSAID) is your neurosymbolic mission control. This walkthrough will introduce the key concepts you need to get started.",
      targetSelector: None,
      completed: false,
    },
    {
      id: "three-panels",
      title: "The Three-Panel Layout",
      description: "PanLL uses three panels: Panel-L (left) for constraints and formal structure, Panel-N (centre) for agent reasoning, and Panel-W (right) for results and output. Together they form the neurosymbolic workspace.",
      targetSelector: Some(".panll-panels"),
      completed: false,
    },
    {
      id: "binary-star",
      title: "Binary Star Architecture",
      description: "Symbolic and neural subsystems orbit each other like a binary star system. The Drift Aura — a subtle background colour shift — shows you how stable that orbit is in real time.",
      targetSelector: Some(".drift-aura"),
      completed: false,
    },
    {
      id: "panel-switcher",
      title: "Panel Switcher",
      description: "Use the panel switcher on the right edge to navigate between different tools: ECHIDNA (theorem proving), TypeLL (type checking), VeriSimDB (simulation database), Hypatia (security scanning), and many more. Panels are grouped by category.",
      targetSelector: Some(".panel-switcher"),
      completed: false,
    },
    {
      id: "shortcuts",
      title: "Keyboard Shortcuts",
      description: "Press F1 or ? to open help at any time. Most panel switches have dedicated shortcuts for fast navigation. All shortcuts are customisable in the Workspace panel.",
      targetSelector: None,
      completed: false,
    },
    {
      id: "glossary",
      title: "The Glossary",
      description: "PanLL uses specialised terminology from neurosymbolic computing. Open the Glossary tab in this help panel to look up any unfamiliar term, from 'Task Barycentre' to 'Hostile UX'.",
      targetSelector: None,
      completed: false,
    },
    {
      id: "contextual-help",
      title: "Contextual Help",
      description: "When you open help from within a specific panel, the help system automatically filters to show content relevant to that panel. You can always clear the filter to see everything.",
      targetSelector: None,
      completed: false,
    },
    {
      id: "start-exploring",
      title: "Start Exploring",
      description: "You are ready to go. Switch between panels, run verifications, inspect provenance, and monitor orbital stability. If you get stuck, this help system is always one shortcut away.",
      targetSelector: None,
      completed: false,
    },
  ]
}

/// Returns the default initial state for the help system.
///
/// Starts with empty collections for entries and glossary terms,
/// which are populated from HelpContent when the help panel first opens.
/// The onboarding walkthrough is inactive by default and includes the
/// standard 8-step sequence.
let defaultState: HelpModel.helpState = {
  searchQuery: "",
  filteredEntries: [],
  activeCategory: GettingStarted,
  activeEntry: None,
  glossary: [],
  onboarding: {
    active: false,
    currentStep: 0,
    steps: defaultOnboardingSteps(),
    completedOnce: false,
  },
  contextPanelId: None,
}

/// Searches help entries by matching a query string against each entry's
/// title, body text, and keywords. Case-insensitive substring matching.
/// An empty query returns all entries unchanged.
let searchEntries = (query: string, entries: array<HelpModel.helpEntry>): array<
  HelpModel.helpEntry,
> => {
  let q = String.toLowerCase(query)
  if q === "" {
    entries
  } else {
    entries->Array.filter(entry => {
      let titleMatch = entry.title->String.toLowerCase->String.includes(q)
      let bodyMatch = entry.body->String.toLowerCase->String.includes(q)
      let keywordMatch =
        entry.keywords->Array.some(kw => kw->String.toLowerCase->String.includes(q))
      titleMatch || bodyMatch || keywordMatch
    })
  }
}

/// Filters help entries to only those belonging to the specified category.
let filterByCategory = (
  category: HelpModel.helpCategory,
  entries: array<HelpModel.helpEntry>,
): array<HelpModel.helpEntry> => {
  entries->Array.filter(entry => entry.category === category)
}

/// Filters help entries by their associated panel ID.
/// If panelId is None, all entries are returned unfiltered.
let filterByPanel = (
  panelId: option<PanelSwitcherModel.panelId>,
  entries: array<HelpModel.helpEntry>,
): array<HelpModel.helpEntry> => {
  switch panelId {
  | None => entries
  | Some(pid) =>
    entries->Array.filter(entry => {
      switch entry.panelId {
      | None => false
      | Some(entryPid) => entryPid === pid
      }
    })
  }
}

/// Finds a single help entry by its unique string identifier.
let findEntry = (id: string, entries: array<HelpModel.helpEntry>): option<HelpModel.helpEntry> => {
  entries->Array.find(entry => entry.id === id)
}

/// Finds a glossary term by exact case-insensitive match on the term name.
let findGlossaryTerm = (term: string, glossary: array<HelpModel.glossaryTerm>): option<
  HelpModel.glossaryTerm,
> => {
  let t = String.toLowerCase(term)
  glossary->Array.find(g => g.term->String.toLowerCase === t)
}

/// Searches the glossary by matching a query against both term names
/// and their definitions. Case-insensitive. Empty query returns all terms.
let searchGlossary = (query: string, glossary: array<HelpModel.glossaryTerm>): array<
  HelpModel.glossaryTerm,
> => {
  let q = String.toLowerCase(query)
  if q === "" {
    glossary
  } else {
    glossary->Array.filter(g => {
      let termMatch = g.term->String.toLowerCase->String.includes(q)
      let defMatch = g.definition->String.toLowerCase->String.includes(q)
      termMatch || defMatch
    })
  }
}

/// Converts a help category variant to a human-readable display label.
let categoryLabel = (cat: HelpModel.helpCategory): string => {
  switch cat {
  | GettingStarted => "Getting Started"
  | Glossary => "Glossary"
  | PanelGuide => "Panel Guides"
  | Shortcuts => "Shortcuts"
  | Faq => "FAQ"
  | Architecture => "Architecture"
  }
}

/// Advances the onboarding walkthrough to the next step.
/// If at the last step, marks onboarding as complete.
let nextOnboardingStep = (state: HelpModel.onboardingState): HelpModel.onboardingState => {
  let maxStep = Array.length(state.steps) - 1
  if state.currentStep >= maxStep {
    {...state, active: false, completedOnce: true}
  } else {
    {...state, currentStep: state.currentStep + 1}
  }
}

/// Moves the onboarding walkthrough back to the previous step.
/// If at the first step, returns state unchanged.
let prevOnboardingStep = (state: HelpModel.onboardingState): HelpModel.onboardingState => {
  if state.currentStep <= 0 {
    state
  } else {
    {...state, currentStep: state.currentStep - 1}
  }
}
