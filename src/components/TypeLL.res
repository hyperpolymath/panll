// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TypeLL Component — the verification kernel panel.
///
/// Four tabs: Checker, Explorer, Refinement, Guide.
/// View layer selector (RAW/FOLDED/GLYPHED/WYSIWYG) controls how type
/// information is presented — progressive disclosure from expert to learner.
///
/// The evangeliser philosophy ("Celebrate good, minimize bad, show better")
/// drives the narrative feedback on every type check result.

open Model
open Msg
open Tea.Html

// ============================================================================
// Shared sub-views
// ============================================================================

/// Render the view layer selector (RAW → WYSIWYG).
let renderViewLayerSelector = (active: viewLayer): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-1 bg-gray-900 rounded-lg p-1")},
    TypeLLEngine.allViewLayers
    ->Array.map(vl => {
      let isActive = vl === active
      let colour = TypeLLEngine.viewLayerColour(vl)
      button(
        list{
          Attrs.class_(
            `px-2 py-1 text-xs rounded transition-colors ${isActive
                ? colour ++ " ring-1 ring-gray-600"
                : "text-gray-600 hover:text-gray-400"}`,
          ),
          Attrs.ariaLabel(TypeLLEngine.viewLayerDescription(vl)),
          Events.onClick(TypeLL(SetViewLayer(vl))),
        },
        list{text(TypeLLEngine.viewLayerLabel(vl))},
      )
    })
    ->List.fromArray,
  )
}

/// Render a type feature badge with glyph.
let renderFeatureBadge = (f: typeFeature, viewLayer: viewLayer): Tea_Vdom.t<msg> => {
  let glyph = TypeLLEngine.featureGlyph(f)
  let tierColour = TypeLLEngine.tierColour(TypeLLEngine.featureTier(f))
  switch viewLayer {
  | Raw =>
    span(
      list{Attrs.class_(`px-1.5 py-0.5 text-xs rounded ${tierColour}`)},
      list{text(TypeLLEngine.featureCode(f))},
    )
  | Folded =>
    span(
      list{Attrs.class_(`px-2 py-0.5 text-xs rounded ${tierColour}`)},
      list{text(TypeLLEngine.featureLabel(f))},
    )
  | Glyphed =>
    span(
      list{
        Attrs.class_(`px-2 py-0.5 text-xs rounded ${tierColour}`),
        Attrs.ariaLabel(glyph.meaning),
      },
      list{text(`${glyph.symbol} ${glyph.label}`)},
    )
  | Wysiwyg =>
    div(
      list{Attrs.class_(`px-3 py-1.5 text-xs rounded-lg ${tierColour} border border-gray-700`)},
      list{
        div(
          list{Attrs.class_("font-medium")},
          list{text(`${glyph.symbol} ${TypeLLEngine.featureLabel(f)}`)},
        ),
        div(list{Attrs.class_("text-gray-500 mt-0.5")}, list{text(glyph.meaning)}),
      },
    )
  }
}

/// Render an evangeliser narrative block.
let renderNarrative = (narrative: typeNarrative): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 space-y-3")},
    list{
      if narrative.celebrate !== "" {
        div(
          list{Attrs.class_("flex items-start gap-2")},
          list{
            span(
              list{Attrs.class_("text-emerald-400 text-sm font-medium shrink-0")},
              list{text("Celebrate")},
            ),
            span(list{Attrs.class_("text-sm text-gray-300")}, list{text(narrative.celebrate)}),
          },
        )
      } else {
        noNode
      },
      if narrative.minimize !== "" {
        div(
          list{Attrs.class_("flex items-start gap-2")},
          list{
            span(
              list{Attrs.class_("text-amber-400 text-sm font-medium shrink-0")},
              list{text("Note")},
            ),
            span(list{Attrs.class_("text-sm text-gray-400")}, list{text(narrative.minimize)}),
          },
        )
      } else {
        noNode
      },
      if narrative.showBetter !== "" {
        div(
          list{Attrs.class_("flex items-start gap-2")},
          list{
            span(
              list{Attrs.class_("text-cyan-400 text-sm font-medium shrink-0")},
              list{text("Better")},
            ),
            span(list{Attrs.class_("text-sm text-gray-300")}, list{text(narrative.showBetter)}),
          },
        )
      } else {
        noNode
      },
      if narrative.safety !== "" {
        div(
          list{Attrs.class_("flex items-start gap-2")},
          list{
            span(
              list{Attrs.class_("text-violet-400 text-sm font-medium shrink-0")},
              list{text("Safety")},
            ),
            span(list{Attrs.class_("text-sm text-gray-300")}, list{text(narrative.safety)}),
          },
        )
      } else {
        noNode
      },
    },
  )
}

/// Render a type check result.
let renderCheckResult = (
  result: typeCheckResult,
  viewLayer: viewLayer,
  narrative: option<typeNarrative>,
): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Status + type signature
      div(
        list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3 mb-3")},
            list{
              span(
                list{
                  Attrs.class_(
                    if result.valid {
                      "text-emerald-400 text-sm font-medium"
                    } else {
                      "text-red-400 text-sm font-medium"
                    },
                  ),
                },
                list{
                  text(
                    if result.valid {
                      "Well-typed"
                    } else {
                      "Type error"
                    },
                  ),
                },
              ),
              span(
                list{
                  Attrs.class_(
                    `px-2 py-0.5 text-xs rounded ${TypeLLEngine.tierColour(result.maxTier)}`,
                  ),
                },
                list{text(TypeLLEngine.tierLabel(result.maxTier))},
              ),
            },
          ),
          // Type signature with view layer formatting
          pre(
            list{
              Attrs.class_(
                "font-mono text-sm text-gray-200 bg-gray-950 rounded p-3 whitespace-pre-wrap",
              ),
            },
            list{
              text(
                TypeLLEngine.formatSignature(
                  result.typeSignature,
                  viewLayer,
                  result.activeFeatures,
                ),
              ),
            },
          ),
          if result.explanation !== "" {
            div(list{Attrs.class_("mt-2 text-sm text-gray-400")}, list{text(result.explanation)})
          } else {
            noNode
          },
        },
      ),
      // Active features
      if result.activeFeatures->Array.length > 0 {
        div(
          list{Attrs.class_("flex flex-wrap gap-2")},
          result.activeFeatures->Array.map(f => renderFeatureBadge(f, viewLayer))->List.fromArray,
        )
      } else {
        noNode
      },
      // Proof obligations
      if result.proofObligations->Array.length > 0 {
        div(
          list{Attrs.class_("bg-gray-900 border border-violet-700/50 rounded-lg p-4")},
          list{
            div(
              list{Attrs.class_("text-xs text-violet-400 mb-2 font-medium")},
              list{text("Proof Obligations")},
            ),
            div(
              list{Attrs.class_("space-y-1")},
              result.proofObligations
              ->Array.map(po =>
                div(list{Attrs.class_("text-sm text-gray-300 font-mono")}, list{text(po)})
              )
              ->List.fromArray,
            ),
          },
        )
      } else {
        noNode
      },
      // Effects
      if result.effects->Array.length > 0 {
        div(
          list{Attrs.class_("bg-gray-900 border border-amber-700/50 rounded-lg p-4")},
          list{
            div(
              list{Attrs.class_("text-xs text-amber-400 mb-2 font-medium")},
              list{text("Effects")},
            ),
            div(
              list{Attrs.class_("flex flex-wrap gap-2")},
              result.effects
              ->Array.map(e =>
                span(
                  list{Attrs.class_("px-2 py-0.5 text-xs rounded bg-amber-900/30 text-amber-300")},
                  list{text(e)},
                )
              )
              ->List.fromArray,
            ),
          },
        )
      } else {
        noNode
      },
      // Linearity issues
      if result.linearityIssues->Array.length > 0 {
        div(
          list{Attrs.class_("bg-gray-900 border border-red-700/50 rounded-lg p-4")},
          list{
            div(
              list{Attrs.class_("text-xs text-red-400 mb-2 font-medium")},
              list{text("Linearity Issues")},
            ),
            div(
              list{Attrs.class_("space-y-1")},
              result.linearityIssues
              ->Array.map(li => div(list{Attrs.class_("text-sm text-red-300")}, list{text(li)}))
              ->List.fromArray,
            ),
          },
        )
      } else {
        noNode
      },
      // Evangeliser narrative
      switch narrative {
      | Some(n) => renderNarrative(n)
      | None => noNode
      },
    },
  )
}

/// Render category tabs.
let renderTabs = (active: typellCategory): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    TypeLLEngine.allCategories
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-cyan-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(TypeLL(SetTlCategory(tab))),
        },
        list{text(TypeLLEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Main view for the TypeLL panel.
let view = (tl: typellState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("TypeLL verification kernel panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("TypeLL")}),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Verification Kernel")}),
              if tl.serverConnected {
                span(list{Attrs.class_("text-xs text-emerald-500")}, list{text("connected")})
              } else {
                span(list{Attrs.class_("text-xs text-amber-500")}, list{text("offline")})
              },
              if tl.serviceActive {
                span(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{text(`${Int.toString(tl.queriesServed)} queries served`)},
                )
              } else {
                noNode
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              renderViewLayerSelector(tl.activeViewLayer),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700",
                  ),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                  KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          renderTabs(tl.activeCategory),
          switch tl.activeCategory {
          // ── Checker Tab ──
          | TlChecker =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-400 mb-2")},
                  list{
                    text(
                      "Enter an expression to type-check. TypeLL detects dependent, linear, affine, session, and refinement types automatically.",
                    ),
                  },
                ),
                textarea(
                  list{
                    Attrs.class_(
                      "w-full h-40 bg-gray-900 border border-gray-700 rounded-lg p-4 font-mono text-sm text-gray-200 resize-none focus:border-cyan-500 focus:outline-none",
                    ),
                    Attrs.value(tl.checkerInput),
                    Attrs.placeholder("e.g., fun (n : Nat) => Vec n Int"),
                    Events.onInput(v => TypeLL(UpdateCheckerInput(v))),
                  },
                  list{},
                ),
                div(
                  list{Attrs.class_("flex gap-2")},
                  list{
                    button(
                      list{
                        Attrs.class_(
                          "px-4 py-2 text-sm bg-cyan-600 text-white rounded hover:bg-cyan-500",
                        ),
                        Events.onClick(TypeLL(RunCheck)),
                        KeyboardNav.onActivate(TypeLL(RunCheck)),
                      },
                      list{text("Check Types")},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          "px-4 py-2 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700",
                        ),
                        Events.onClick(TypeLL(RunInfer)),
                        KeyboardNav.onActivate(TypeLL(RunInfer)),
                      },
                      list{text("Infer Type")},
                    ),
                  },
                ),
                switch tl.lastCheckResult {
                | Some(result) => renderCheckResult(result, tl.activeViewLayer, tl.lastNarrative)
                | None => noNode
                },
              },
            )
          // ── Explorer Tab ──
          | TlExplorer =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("flex gap-3 items-center")},
                  list{
                    input(
                      list{
                        Attrs.class_(
                          "flex-1 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600 font-mono",
                        ),
                        Attrs.placeholder("Search signatures..."),
                        Attrs.value(tl.signatureFilter),
                        Events.onInput(v => TypeLL(SetSignatureFilter(v))),
                      },
                      list{},
                    ),
                    // Tier filter buttons
                    button(
                      list{
                        Attrs.class_(
                          `px-3 py-1.5 text-xs rounded ${tl.tierFilter === None
                              ? "bg-gray-700 text-gray-200"
                              : "text-gray-500 hover:text-gray-300"}`,
                        ),
                        Events.onClick(TypeLL(SetTierFilter(None))),
                      },
                      list{text("All")},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          `px-3 py-1.5 text-xs rounded ${tl.tierFilter === Some(TierCore)
                              ? TypeLLEngine.tierColour(TierCore)
                              : "text-gray-500 hover:text-gray-300"}`,
                        ),
                        Events.onClick(TypeLL(SetTierFilter(Some(TierCore)))),
                      },
                      list{text("Core")},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          `px-3 py-1.5 text-xs rounded ${tl.tierFilter === Some(TierAdvanced)
                              ? TypeLLEngine.tierColour(TierAdvanced)
                              : "text-gray-500 hover:text-gray-300"}`,
                        ),
                        Events.onClick(TypeLL(SetTierFilter(Some(TierAdvanced)))),
                      },
                      list{text("Advanced")},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          `px-3 py-1.5 text-xs rounded ${tl.tierFilter === Some(TierResearch)
                              ? TypeLLEngine.tierColour(TierResearch)
                              : "text-gray-500 hover:text-gray-300"}`,
                        ),
                        Events.onClick(TypeLL(SetTierFilter(Some(TierResearch)))),
                      },
                      list{text("Research")},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          "px-3 py-1.5 text-xs bg-cyan-600 text-white rounded hover:bg-cyan-500",
                        ),
                        Events.onClick(TypeLL(LoadSignatures)),
                        KeyboardNav.onActivate(TypeLL(LoadSignatures)),
                      },
                      list{text("Load")},
                    ),
                  },
                ),
                // Signature list
                if tl.signatures->Array.length === 0 {
                  div(
                    list{Attrs.class_("text-center text-gray-500 mt-8")},
                    list{text("No signatures loaded. Connect to TypeLL server and click Load.")},
                  )
                } else {
                  let filtered =
                    tl.signatures
                    ->TypeLLEngine.filterByTier(tl.tierFilter)
                    ->TypeLLEngine.filterBySearch(tl.signatureFilter)
                  div(
                    list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                    list{
                      div(
                        list{Attrs.class_("max-h-96 overflow-y-auto")},
                        filtered
                        ->Array.map(sig =>
                          div(
                            list{
                              Attrs.class_(
                                "flex items-center gap-3 p-3 border-b border-gray-800 hover:bg-gray-900/50",
                              ),
                            },
                            list{
                              span(
                                list{
                                  Attrs.class_(
                                    `px-1.5 py-0.5 text-xs rounded ${TypeLLEngine.tierColour(
                                        sig.tier,
                                      )}`,
                                  ),
                                },
                                list{text(TypeLLEngine.tierLabel(sig.tier))},
                              ),
                              span(
                                list{Attrs.class_("text-sm font-mono text-cyan-400")},
                                list{text(sig.name)},
                              ),
                              span(
                                list{
                                  Attrs.class_("text-sm font-mono text-gray-400 flex-1 truncate"),
                                },
                                list{text(sig.signature)},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-600")},
                                list{text(sig.module_)},
                              ),
                            },
                          )
                        )
                        ->List.fromArray,
                      ),
                    },
                  )
                },
                // Universes
                if tl.universes->Array.length > 0 {
                  div(
                    list{Attrs.class_("mt-6")},
                    list{
                      h3(
                        list{Attrs.class_("text-sm font-medium text-gray-300 mb-3")},
                        list{text("Type Universes")},
                      ),
                      div(
                        list{Attrs.class_("space-y-2")},
                        tl.universes
                        ->Array.map(u =>
                          div(
                            list{Attrs.class_("flex items-center gap-3 text-sm")},
                            list{
                              span(
                                list{Attrs.class_("font-mono text-violet-400 w-8 text-right")},
                                list{text(Int.toString(u.level))},
                              ),
                              span(
                                list{Attrs.class_("font-mono text-gray-200")},
                                list{text(u.name)},
                              ),
                              span(list{Attrs.class_("text-gray-500")}, list{text(u.description)}),
                            },
                          )
                        )
                        ->List.fromArray,
                      ),
                    },
                  )
                } else {
                  noNode
                },
              },
            )
          // ── Refinement Tab ──
          | TlRefinement =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-400 mb-2")},
                  list{
                    text(
                      "Narrow a type with refinement constraints. TypeLL checks satisfiability and consistency.",
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("grid grid-cols-2 gap-4")},
                  list{
                    div(
                      list{Attrs.class_("space-y-2")},
                      list{
                        label(list{Attrs.class_("text-xs text-gray-500")}, list{text("Base Type")}),
                        input(
                          list{
                            Attrs.class_(
                              "w-full bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 font-mono placeholder-gray-600",
                            ),
                            Attrs.placeholder("e.g., Int"),
                            Attrs.value(tl.refinementSpec),
                            Events.onInput(v => TypeLL(UpdateRefinementSpec(v))),
                          },
                          list{},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("space-y-2")},
                      list{
                        label(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text("Constraints (one per line)")},
                        ),
                        textarea(
                          list{
                            Attrs.class_(
                              "w-full h-20 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 font-mono resize-none placeholder-gray-600",
                            ),
                            Attrs.placeholder("x > 0\nx < 256"),
                            Attrs.value(tl.refinementConstraints),
                            Events.onInput(v => TypeLL(UpdateRefinementConstraints(v))),
                          },
                          list{},
                        ),
                      },
                    ),
                  },
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-sm bg-violet-600 text-white rounded hover:bg-violet-500",
                    ),
                    Events.onClick(TypeLL(RunRefine)),
                    KeyboardNav.onActivate(TypeLL(RunRefine)),
                  },
                  list{text("Apply Refinement")},
                ),
                switch tl.lastRefinement {
                | Some(ref) =>
                  div(
                    list{
                      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 space-y-3"),
                    },
                    list{
                      div(
                        list{Attrs.class_("flex items-center gap-3")},
                        list{
                          span(
                            list{
                              Attrs.class_(
                                if ref.consistent {
                                  "text-emerald-400 text-sm"
                                } else {
                                  "text-red-400 text-sm"
                                },
                              ),
                            },
                            list{
                              text(
                                if ref.consistent {
                                  "Consistent"
                                } else {
                                  "Inconsistent"
                                },
                              ),
                            },
                          ),
                        },
                      ),
                      div(
                        list{Attrs.class_("grid grid-cols-2 gap-4")},
                        list{
                          div(
                            list{},
                            list{
                              div(
                                list{Attrs.class_("text-xs text-gray-500 mb-1")},
                                list{text("Base Type")},
                              ),
                              pre(
                                list{
                                  Attrs.class_(
                                    "font-mono text-sm text-gray-300 bg-gray-950 rounded p-2",
                                  ),
                                },
                                list{text(ref.baseType)},
                              ),
                            },
                          ),
                          div(
                            list{},
                            list{
                              div(
                                list{Attrs.class_("text-xs text-gray-500 mb-1")},
                                list{text("Refined Type")},
                              ),
                              pre(
                                list{
                                  Attrs.class_(
                                    "font-mono text-sm text-cyan-300 bg-gray-950 rounded p-2",
                                  ),
                                },
                                list{text(ref.refinedType)},
                              ),
                            },
                          ),
                        },
                      ),
                    },
                  )
                | None => noNode
                },
              },
            )
          // ── Discipline Tab ──
          | TlDiscipline =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-400 mb-2")},
                  list{
                    text(
                      "Type discipline modes control the default type system behaviour per module. Affine by default (like Rust), with opt-in linear, dependent, refined, or unrestricted modes.",
                    ),
                  },
                ),
                // Default discipline selector
                div(
                  list{Attrs.class_("p-3 bg-gray-900 border border-gray-700 rounded-lg")},
                  list{
                    div(
                      list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wide mb-2")},
                      list{text("Default Discipline")},
                    ),
                    div(
                      list{Attrs.class_("flex flex-wrap gap-2")},
                      TypeLLEngine.allDisciplines
                      ->Array.map(d => {
                        let isActive = d === tl.defaultDiscipline
                        button(
                          list{
                            Attrs.class_(
                              `px-3 py-1.5 text-xs rounded transition-colors ${isActive
                                  ? TypeLLEngine.disciplineColour(d) ++ " font-medium"
                                  : "text-gray-500 hover:text-gray-300 bg-gray-800"}`,
                            ),
                            Events.onClick(TypeLL(SetDefaultDiscipline(d))),
                          },
                          list{text(TypeLLEngine.disciplineDirective(d))},
                        )
                      })
                      ->List.fromArray,
                    ),
                  },
                ),
                // Active declarations
                div(
                  list{Attrs.class_("p-3 bg-gray-900 border border-gray-700 rounded-lg")},
                  list{
                    div(
                      list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wide mb-2")},
                      list{
                        text(
                          "Module Declarations (" ++
                          Int.toString(Array.length(tl.disciplineDeclarations)) ++ ")",
                        ),
                      },
                    ),
                    if Array.length(tl.disciplineDeclarations) === 0 {
                      div(
                        list{Attrs.class_("text-xs text-gray-600")},
                        list{
                          text(
                            "No module-level discipline declarations yet. Modules inherit the default.",
                          ),
                        },
                      )
                    } else {
                      div(
                        list{Attrs.class_("space-y-1")},
                        tl.disciplineDeclarations
                        ->Array.map(decl =>
                          div(
                            list{
                              Attrs.class_(
                                "flex items-center justify-between px-2 py-1 bg-gray-800/40 rounded text-xs",
                              ),
                            },
                            list{
                              span(
                                list{Attrs.class_("text-gray-300 font-mono")},
                                list{text(decl.scope)},
                              ),
                              span(
                                list{
                                  Attrs.class_(
                                    TypeLLEngine.disciplineColour(
                                      decl.discipline,
                                    ) ++ " px-2 py-0.5 rounded",
                                  ),
                                },
                                list{text(TypeLLEngine.disciplineDirective(decl.discipline))},
                              ),
                            },
                          )
                        )
                        ->List.fromArray,
                      )
                    },
                  },
                ),
                // QTT quantifier reference
                div(
                  list{Attrs.class_("p-3 bg-gray-900 border border-gray-700 rounded-lg")},
                  list{
                    div(
                      list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wide mb-2")},
                      list{text("QTT Usage Quantifiers")},
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-3 gap-3")},
                      list{
                        div(
                          list{Attrs.class_("text-center p-2 bg-gray-800/40 rounded")},
                          list{
                            div(
                              list{Attrs.class_("text-lg font-mono text-purple-400")},
                              list{text("0")},
                            ),
                            div(
                              list{Attrs.class_("text-[10px] text-gray-500")},
                              list{text("Erased at runtime")},
                            ),
                            div(
                              list{Attrs.class_("text-[10px] text-gray-600")},
                              list{text("Proof-only witness")},
                            ),
                          },
                        ),
                        div(
                          list{Attrs.class_("text-center p-2 bg-gray-800/40 rounded")},
                          list{
                            div(
                              list{Attrs.class_("text-lg font-mono text-red-400")},
                              list{text("1")},
                            ),
                            div(
                              list{Attrs.class_("text-[10px] text-gray-500")},
                              list{text("Exactly once")},
                            ),
                            div(
                              list{Attrs.class_("text-[10px] text-gray-600")},
                              list{text("Linear consumption")},
                            ),
                          },
                        ),
                        div(
                          list{Attrs.class_("text-center p-2 bg-gray-800/40 rounded")},
                          list{
                            div(
                              list{Attrs.class_("text-lg font-mono text-green-400")},
                              list{text("w")},
                            ),
                            div(
                              list{Attrs.class_("text-[10px] text-gray-500")},
                              list{text("Unrestricted")},
                            ),
                            div(
                              list{Attrs.class_("text-[10px] text-gray-600")},
                              list{text("Standard FP")},
                            ),
                          },
                        ),
                      },
                    ),
                  },
                ),
                // Unified analysis result (if available)
                switch tl.lastUnifiedAnalysis {
                | Some(analysis) =>
                  div(
                    list{Attrs.class_("p-3 bg-gray-900 border border-gray-700 rounded-lg")},
                    list{
                      div(
                        list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wide mb-2")},
                        list{text("Last Unified Analysis")},
                      ),
                      div(
                        list{Attrs.class_("text-xs text-gray-300 font-mono")},
                        list{text(TypeLLEngine.unifiedAnalysisSummary(analysis))},
                      ),
                    },
                  )
                | None => noNode
                },
              },
            )
          // ── Guide Tab ──
          | TlGuide =>
            div(
              list{Attrs.class_("space-y-8 max-w-3xl")},
              list{
                // Tier 1: Core
                div(
                  list{Attrs.class_("space-y-3")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-2")},
                      list{
                        span(
                          list{
                            Attrs.class_(
                              `px-2 py-0.5 text-xs font-medium rounded ${TypeLLEngine.tierColour(
                                  TierCore,
                                )}`,
                            ),
                          },
                          list{text("Tier 1: Core")},
                        ),
                        span(
                          list{Attrs.class_("text-sm text-gray-400")},
                          list{text("Essential type safety")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-2 gap-3")},
                      TypeLLEngine.coreFeatures
                      ->Array.map(f => {
                        let glyph = TypeLLEngine.featureGlyph(f)
                        div(
                          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3")},
                          list{
                            div(
                              list{Attrs.class_("flex items-center gap-2 mb-1")},
                              list{
                                span(
                                  list{Attrs.class_("font-mono text-emerald-400")},
                                  list{text(glyph.symbol)},
                                ),
                                span(
                                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                                  list{text(TypeLLEngine.featureLabel(f))},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("text-xs text-gray-500")},
                              list{text(glyph.meaning)},
                            ),
                          },
                        )
                      })
                      ->List.fromArray,
                    ),
                  },
                ),
                // Tier 2: Advanced
                div(
                  list{Attrs.class_("space-y-3")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-2")},
                      list{
                        span(
                          list{
                            Attrs.class_(
                              `px-2 py-0.5 text-xs font-medium rounded ${TypeLLEngine.tierColour(
                                  TierAdvanced,
                                )}`,
                            ),
                          },
                          list{text("Tier 2: Advanced")},
                        ),
                        span(
                          list{Attrs.class_("text-sm text-gray-400")},
                          list{text("Precision resource management")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-2 gap-3")},
                      TypeLLEngine.advancedFeatures
                      ->Array.map(f => {
                        let glyph = TypeLLEngine.featureGlyph(f)
                        div(
                          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3")},
                          list{
                            div(
                              list{Attrs.class_("flex items-center gap-2 mb-1")},
                              list{
                                span(
                                  list{Attrs.class_("font-mono text-blue-400")},
                                  list{text(glyph.symbol)},
                                ),
                                span(
                                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                                  list{text(TypeLLEngine.featureLabel(f))},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("text-xs text-gray-500")},
                              list{text(glyph.meaning)},
                            ),
                          },
                        )
                      })
                      ->List.fromArray,
                    ),
                  },
                ),
                // Tier 3: Research
                div(
                  list{Attrs.class_("space-y-3")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-2")},
                      list{
                        span(
                          list{
                            Attrs.class_(
                              `px-2 py-0.5 text-xs font-medium rounded ${TypeLLEngine.tierColour(
                                  TierResearch,
                                )}`,
                            ),
                          },
                          list{text("Tier 3: Research")},
                        ),
                        span(
                          list{Attrs.class_("text-sm text-gray-400")},
                          list{text("Frontier type theory")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-2 gap-3")},
                      TypeLLEngine.researchFeatures
                      ->Array.map(f => {
                        let glyph = TypeLLEngine.featureGlyph(f)
                        div(
                          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3")},
                          list{
                            div(
                              list{Attrs.class_("flex items-center gap-2 mb-1")},
                              list{
                                span(
                                  list{Attrs.class_("font-mono text-purple-400")},
                                  list{text(glyph.symbol)},
                                ),
                                span(
                                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                                  list{text(TypeLLEngine.featureLabel(f))},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("text-xs text-gray-500")},
                              list{text(glyph.meaning)},
                            ),
                          },
                        )
                      })
                      ->List.fromArray,
                    ),
                  },
                ),
                // Cross-panel integration table
                div(
                  list{Attrs.class_("space-y-3")},
                  list{
                    h3(
                      list{Attrs.class_("text-sm font-medium text-gray-200")},
                      list{text("Cross-Panel Integration")},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mb-2")},
                      list{
                        text(
                          "TypeLL provides type intelligence to every panel, not just this one.",
                        ),
                      },
                    ),
                    div(
                      list{
                        Attrs.class_(
                          "bg-gray-900 border border-gray-700 rounded-lg overflow-hidden",
                        ),
                      },
                      list{
                        div(
                          list{Attrs.class_("divide-y divide-gray-800")},
                          list{
                            div(
                              list{Attrs.class_("flex p-2 text-xs")},
                              list{
                                span(
                                  list{Attrs.class_("w-40 text-cyan-400")},
                                  list{text("VeriSimDB")},
                                ),
                                span(
                                  list{Attrs.class_("text-gray-400")},
                                  list{text("VQL-UT 10-level type safety (supersedes VQL-DT)")},
                                ),
                              },
                            ),
                            div(
                              list{
                                Attrs.class_("p-2 text-xs bg-gray-950 border-l-2 border-cyan-700"),
                              },
                              list{
                                div(
                                  list{Attrs.class_("text-cyan-500 font-bold mb-1")},
                                  list{text("VQL-UT Safety Levels")},
                                ),
                                div(
                                  list{Attrs.class_("grid grid-cols-2 gap-1 text-gray-500")},
                                  list{
                                    span(list{}, list{text("L1 Parse-time")}),
                                    span(list{}, list{text("L2 Schema-binding")}),
                                    span(list{}, list{text("L3 Type-compatible")}),
                                    span(list{}, list{text("L4 Null-safety")}),
                                    span(list{}, list{text("L5 Injection-proof")}),
                                    span(list{}, list{text("L6 Result-type")}),
                                    span(
                                      list{Attrs.class_("text-amber-500")},
                                      list{text("L7 Cardinality")},
                                    ),
                                    span(
                                      list{Attrs.class_("text-amber-500")},
                                      list{text("L8 Effect-tracking")},
                                    ),
                                    span(
                                      list{Attrs.class_("text-amber-500")},
                                      list{text("L9 Temporal")},
                                    ),
                                    span(
                                      list{Attrs.class_("text-amber-500")},
                                      list{text("L10 Linearity")},
                                    ),
                                  },
                                ),
                                div(
                                  list{Attrs.class_("mt-1 text-gray-600 italic")},
                                  list{text("Amber = research-identified (Idris2 verified)")},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("flex p-2 text-xs")},
                              list{
                                span(
                                  list{Attrs.class_("w-40 text-cyan-400")},
                                  list{text("Protocol-Squisher")},
                                ),
                                span(
                                  list{Attrs.class_("text-gray-400")},
                                  list{text("Schema type compatibility, adapter type safety")},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("flex p-2 text-xs")},
                              list{
                                span(
                                  list{Attrs.class_("w-40 text-cyan-400")},
                                  list{text("My-Lang")},
                                ),
                                span(
                                  list{Attrs.class_("text-gray-400")},
                                  list{text("Full type checking across Solo/Duet/Ensemble/Me")},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("flex p-2 text-xs")},
                              list{
                                span(
                                  list{Attrs.class_("w-40 text-cyan-400")},
                                  list{text("Anti-Crash")},
                                ),
                                span(
                                  list{Attrs.class_("text-gray-400")},
                                  list{text("Type-level validation before token acceptance")},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("flex p-2 text-xs")},
                              list{
                                span(
                                  list{Attrs.class_("w-40 text-cyan-400")},
                                  list{text("Pane-L")},
                                ),
                                span(
                                  list{Attrs.class_("text-gray-400")},
                                  list{
                                    text("Type constraints as first-class symbolic constraints"),
                                  },
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("flex p-2 text-xs")},
                              list{
                                span(list{Attrs.class_("w-40 text-cyan-400")}, list{text("BoJ")}),
                                span(
                                  list{Attrs.class_("text-gray-400")},
                                  list{text("Cartridge ABI type checking (Idris2 formal specs)")},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("flex p-2 text-xs")},
                              list{
                                span(
                                  list{Attrs.class_("w-40 text-cyan-400")},
                                  list{text("ECHIDNA")},
                                ),
                                span(
                                  list{Attrs.class_("text-gray-400")},
                                  list{
                                    text(
                                      "Proof obligation dispatch — TypeLL generates, ECHIDNA proves",
                                    ),
                                  },
                                ),
                              },
                            ),
                          },
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          },
          // Loading/error
          if tl.loading {
            div(
              list{Attrs.class_("mt-4 text-gray-400 text-sm"), Attrs.role("status")},
              list{text("Processing...")},
            )
          } else {
            noNode
          },
          switch tl.error {
          | Some(e) =>
            div(
              list{
                Attrs.class_(
                  "mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300",
                ),
                Attrs.role("alert"),
              },
              list{text(e)},
            )
          | None => noNode
          },
        },
      ),
    },
  )
}
