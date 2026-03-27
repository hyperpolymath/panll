// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// Update handler for the in-application help system.
/// Manages search, category filtering, entry navigation, glossary lookup,
/// and the onboarding walkthrough.
let updateHelp = (model: model, msg: helpMsg): (model, Tea_Cmd.t<msg>) => {
  let h = model.help
  switch msg {
  | SetHelpSearch(query) =>
    let allEntries = HelpContent.allEntries()
    let filtered = if query === "" {
      HelpEngine.filterByCategory(h.activeCategory, allEntries)
    } else {
      HelpEngine.searchEntries(query, allEntries)
    }
    ({...model, help: {...h, searchQuery: query, filteredEntries: filtered}}, Tea_Cmd.none)
  | SetHelpCategory(cat) =>
    let allEntries = HelpContent.allEntries()
    let filtered = HelpEngine.filterByCategory(cat, allEntries)
    (
      {...model, help: {...h, activeCategory: cat, filteredEntries: filtered, activeEntry: None}},
      Tea_Cmd.none,
    )
  | SelectEntry(id) => ({...model, help: {...h, activeEntry: Some(id)}}, Tea_Cmd.none)
  | CloseHelp => (
      {...model, panelSwitcher: {...model.panelSwitcher, activePanel: None}},
      Tea_Cmd.none,
    )
  | StartOnboarding =>
    let onboarding = {...h.onboarding, active: true, currentStep: 0}
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | NextOnboardingStep =>
    let onboarding = HelpEngine.nextOnboardingStep(h.onboarding)
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | PrevOnboardingStep =>
    let onboarding = HelpEngine.prevOnboardingStep(h.onboarding)
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | SkipOnboarding =>
    let onboarding = {...h.onboarding, active: false, completedOnce: true}
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | CompleteOnboarding =>
    let onboarding = {...h.onboarding, active: false, completedOnce: true}
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | OpenContextHelp(panelId) =>
    let allEntries = HelpContent.allEntries()
    let filtered = HelpEngine.filterByPanel(panelId, allEntries)
    let newHelp = {
      ...h,
      contextPanelId: panelId,
      filteredEntries: filtered,
      activeCategory: PanelGuide,
      activeEntry: None,
    }
    (
      {
        ...model,
        help: newHelp,
        panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)},
      },
      Tea_Cmd.none,
    )
  | SearchGlossary(query) =>
    let glossary = HelpEngine.searchGlossary(query, HelpContent.allGlossaryTerms())
    ({...model, help: {...h, glossary, activeCategory: Glossary}}, Tea_Cmd.none)
  }
}
