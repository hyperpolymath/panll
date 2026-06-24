// SPDX-License-Identifier: MPL-2.0

/// PanLL Help Model — types for the in-application help and guidance system.
///
/// Provides context-sensitive help, a searchable glossary of neurosymbolic
/// terminology, per-panel guides, keyboard shortcut reference, and an
/// onboarding walkthrough for new users.
///
/// The help system is a first-class panel (PanelHelp) but also supports
/// context-sensitive invocation: pressing F1 or ? opens help pre-filtered
/// to the currently active panel's topic.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Help content categories for filtering and navigation.
/// Each category maps to a tab in the Help panel.
type helpCategory =
  /// Getting started guide — first-time user walkthrough and orientation.
  | GettingStarted
  /// Glossary of neurosymbolic terminology (task barycentre, symbolic mass,
  /// neural stream, OODA loop, contractiles, vexation index, etc.).
  | Glossary
  /// Per-panel guide — each panel has a dedicated help page describing
  /// its purpose, controls, backend requirements, and workflow.
  | PanelGuide
  /// Keyboard shortcuts reference — lists all keybindings with descriptions.
  | Shortcuts
  /// Frequently asked questions — common issues and their resolutions.
  | Faq
  /// Architecture overview — Binary Star model, three-panel layout,
  /// TEA update loop, and neurosymbolic integration points.
  | Architecture

/// A single help entry — an article/page in the help system.
/// Entries are searchable by title, body text, and keywords.
type helpEntry = {
  /// Unique identifier for this help entry (e.g. "panel-echidna", "glossary-barycentre").
  id: string,
  /// Human-readable title displayed in search results and as the page heading.
  title: string,
  /// Full help text body. Supports a subset of Markdown-like formatting
  /// (paragraphs separated by blank lines, **bold**, `code`).
  body: string,
  /// Category this entry belongs to — determines which tab it appears under.
  category: helpCategory,
  /// If this entry is panel-specific help, which panel it documents.
  /// None for general entries (glossary terms, shortcuts, architecture).
  panelId: option<PanelSwitcherModel.panelId>,
  /// Search keywords that match this entry beyond title/body text.
  /// Includes synonyms, abbreviations, and related concepts.
  keywords: array<string>,
}

/// A glossary term with cross-references to related terms.
/// Glossary terms are a specialised subset of help entries with
/// richer linking for exploratory learning.
type glossaryTerm = {
  /// The term being defined (e.g. "Task Barycentre", "Symbolic Mass").
  term: string,
  /// Plain-language definition accessible to users unfamiliar with
  /// neurosymbolic AI concepts. Avoids jargon where possible.
  definition: string,
  /// Related terms the user might want to explore next.
  /// Creates a knowledge graph of neurosymbolic concepts.
  relatedTerms: array<string>,
  /// Optional longer explanation with examples and analogies.
  extendedDescription: option<string>,
}

/// A single step in the onboarding walkthrough.
/// Steps are presented sequentially with optional highlighting
/// of UI elements to guide the user's attention.
type onboardingStep = {
  /// Unique step identifier (e.g. "welcome", "panel-switcher", "dark-start").
  id: string,
  /// Step title displayed as the heading of the onboarding card.
  title: string,
  /// Detailed description explaining what this UI element does
  /// and how to interact with it.
  description: string,
  /// CSS selector for the target element to highlight during this step.
  /// None for general information steps that don't target a specific element.
  targetSelector: option<string>,
  /// Whether the user has completed/acknowledged this step.
  completed: bool,
}

/// State for the onboarding walkthrough sub-system.
type onboardingState = {
  /// Whether the onboarding walkthrough is currently active/visible.
  active: bool,
  /// Zero-based index of the current step being displayed.
  currentStep: int,
  /// Ordered sequence of onboarding steps to present.
  steps: array<onboardingStep>,
  /// Whether the user has completed onboarding at least once.
  /// Persisted to localStorage to avoid re-showing on return visits.
  completedOnce: bool,
}

/// Root state for the help system.
type helpState = {
  /// Current search query text in the help search bar.
  searchQuery: string,
  /// Help entries matching the current search query and category filter.
  /// Recomputed by HelpEngine on every search/category change.
  filteredEntries: array<helpEntry>,
  /// Currently selected category tab for filtering help entries.
  activeCategory: helpCategory,
  /// ID of the currently displayed help entry (None = show entry list).
  activeEntry: option<string>,
  /// Full glossary of neurosymbolic terms for the Glossary tab.
  glossary: array<glossaryTerm>,
  /// Onboarding walkthrough state.
  onboarding: onboardingState,
  /// When help is opened context-sensitively (F1), this records which
  /// panel was active so help can pre-filter to that panel's guide.
  contextPanelId: option<PanelSwitcherModel.panelId>,
}
