// SPDX-License-Identifier: PMPL-1.0-or-later

/// Help system messages -- search, navigation, onboarding, and context-sensitive help.

open Model

type helpMsg =
  /// Update the search query in the help search bar.
  | SetHelpSearch(string)
  /// Switch to a different help category tab.
  | SetHelpCategory(helpCategory)
  /// Select a specific help entry to display in full.
  | SelectEntry(string)
  /// Close the help panel.
  | CloseHelp
  /// Begin the onboarding walkthrough from the first step.
  | StartOnboarding
  /// Advance to the next onboarding step.
  | NextOnboardingStep
  /// Go back to the previous onboarding step.
  | PrevOnboardingStep
  /// Skip the rest of the onboarding walkthrough.
  | SkipOnboarding
  /// Mark the onboarding as completed.
  | CompleteOnboarding
  /// Open help pre-filtered to the specified panel's guide (F1 context-sensitive).
  | OpenContextHelp(option<panelId>)
  /// Search the glossary for a specific term.
  | SearchGlossary(string)
