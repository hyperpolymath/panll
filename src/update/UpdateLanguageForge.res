// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

// ===========================================================================
// Language Forge Sub-Updater
// ===========================================================================

/// Handle Language Forge messages — nextgen-languages portfolio monitoring.
let updateLanguageForge = (model: model, msg: languageForgeMsg): (model, Tea_Cmd.t<msg>) => {
  let forge = model.languageForge
  switch msg {
  | LoadLanguages => (
      {
        ...model,
        languageForge: {
          ...forge,
          loaded: true,
          loading: false,
          error: None,
          languages: LanguageForgeEngine.languageData(),
        },
      },
      Tea_Cmd.none,
    )
  | SetForgeCategory(cat) => (
      {...model, languageForge: {...forge, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetForgeFilter(text) => ({...model, languageForge: {...forge, filterText: text}}, Tea_Cmd.none)
  | SetForgeSort(sort) => ({...model, languageForge: {...forge, sortBy: sort}}, Tea_Cmd.none)
  | SelectLanguage(name) => (
      {...model, languageForge: {...forge, selectedLanguage: name}},
      Tea_Cmd.none,
    )
  | ToggleMoscow => (
      {...model, languageForge: {...forge, showMoscow: !forge.showMoscow}},
      Tea_Cmd.none,
    )
  }
}
