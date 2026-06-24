// SPDX-License-Identifier: MPL-2.0

/// PanLL DLC Workshop Component — view for creating, testing, and
/// packaging IDApTIK DLC puzzle packs. Puzzle browser, VM instruction
/// composer, solution test runner, asset browser, and packaging.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (label: string, cat: dlcWorkshopCategory, active: dlcWorkshopCategory): Tea_Vdom.t<
  msg,
> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(DlcWorkshop(SetWorkshopCategory(cat)))},
    list{text(label)},
  )
}

/// Render a puzzle card.
let renderPuzzleCard = (puzzle: dlcPuzzle, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderCls = if isSelected {
    "border-cyan-400"
  } else {
    "border-gray-700"
  }
  let diffCls = DlcWorkshopEngine.difficultyColour(puzzle.difficulty)
  let testCls = DlcWorkshopEngine.testStatusColour(puzzle.testStatus)
  div(
    list{
      Attrs.class_(
        `p-3 bg-gray-800 rounded border ${borderCls} cursor-pointer hover:border-gray-500`,
      ),
      Events.onClick(DlcWorkshop(SelectPuzzle(puzzle.id))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-100")}, list{text(puzzle.name)}),
          span(
            list{Attrs.class_(`text-xs ${diffCls}`)},
            list{text(DlcWorkshopEngine.difficultyLabel(puzzle.difficulty))},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-400 mb-2 line-clamp-2")},
        list{text(puzzle.description)},
      ),
      div(
        list{Attrs.class_("flex items-center gap-3 text-xs")},
        list{
          span(
            list{Attrs.class_("text-gray-500")},
            list{text(`${Int.toString(Array.length(puzzle.instructions))} instrs`)},
          ),
          span(
            list{Attrs.class_("text-gray-500")},
            list{text(`${Int.toString(puzzle.optimalSteps)} optimal`)},
          ),
          span(
            list{Attrs.class_(testCls)},
            list{text(DlcWorkshopEngine.testStatusLabel(puzzle.testStatus))},
          ),
        },
      ),
    },
  )
}

/// Render puzzles list view.
let renderPuzzles = (state: dlcWorkshopState): Tea_Vdom.t<msg> => {
  let filtered = DlcWorkshopEngine.filterPuzzles(
    state.puzzles,
    state.filterText,
    state.filterDifficulty,
  )
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Filter bar
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 bg-gray-800 border border-gray-700 rounded text-sm text-gray-200 placeholder-gray-500",
              ),
              Attrs.placeholder("Filter puzzles..."),
              Attrs.value(state.filterText),
              Events.onInput(text => DlcWorkshop(SetDlcFilter(text))),
            },
            list{},
          ),
          // Difficulty filter chips
          button(
            list{
              Attrs.class_(
                if state.filterDifficulty === None {
                  "px-2 py-1 text-xs bg-gray-600 text-white rounded"
                } else {
                  "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(DlcWorkshop(SetDifficultyFilter(None))),
            },
            list{text("All")},
          ),
          ...DlcWorkshopEngine.allDifficulties
          ->Array.map(diff => {
            let isActive = state.filterDifficulty === Some(diff)
            let cls = if isActive {
              `px-2 py-1 text-xs bg-gray-600 ${DlcWorkshopEngine.difficultyColour(diff)} rounded`
            } else {
              "px-2 py-1 text-xs bg-gray-800 text-gray-500 rounded cursor-pointer hover:text-gray-300"
            }
            button(
              list{Attrs.class_(cls), Events.onClick(DlcWorkshop(SetDifficultyFilter(Some(diff))))},
              list{text(DlcWorkshopEngine.difficultyLabel(diff))},
            )
          })
          ->List.fromArray,
        },
      ),
      // Stats
      div(
        list{Attrs.class_("flex items-center gap-4 text-xs text-gray-400")},
        list{
          span(list{}, list{text(`${Int.toString(Array.length(filtered))} puzzles`)}),
          span(
            list{},
            list{
              text(`${Int.toString(DlcWorkshopEngine.passedTests(state.puzzles))} tests passed`),
            },
          ),
        },
      ),
      // Puzzle cards
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{
            text("No puzzles found. "),
            button(
              list{
                Attrs.class_("text-cyan-400 hover:text-cyan-300 underline cursor-pointer"),
                Events.onClick(DlcWorkshop(LoadPuzzles)),
                KeyboardNav.onActivate(DlcWorkshop(LoadPuzzles)),
              },
              list{text("Load puzzles")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-3")},
          filtered
          ->Array.map(p => renderPuzzleCard(p, state.selectedPuzzleId === Some(p.id)))
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the VM instruction composer.
let renderComposer = (state: dlcWorkshopState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200")}, list{text("VM Instruction Composer")}),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
                  ),
                  Events.onClick(DlcWorkshop(AddInstruction)),
                  KeyboardNav.onActivate(DlcWorkshop(AddInstruction)),
                },
                list{text("Add Instruction")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(DlcWorkshop(ClearComposer)),
                  KeyboardNav.onActivate(DlcWorkshop(ClearComposer)),
                },
                list{text("Clear")},
              ),
            },
          ),
        },
      ),
      // Instructions list
      if Array.length(state.composerInstructions) === 0 {
        div(
          list{
            Attrs.class_(
              "text-center text-gray-500 text-sm py-8 border border-dashed border-gray-700 rounded",
            ),
          },
          list{text("No instructions — click 'Add Instruction' to start composing a puzzle")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1 font-mono text-xs")},
          state.composerInstructions
          ->Array.map(instr =>
            div(
              list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded")},
              list{
                span(
                  list{Attrs.class_("text-gray-500 w-6")},
                  list{text(Int.toString(instr.index))},
                ),
                span(list{Attrs.class_("text-cyan-400 w-16")}, list{text(instr.opcode)}),
                switch instr.operand {
                | Some(op) =>
                  span(list{Attrs.class_("text-amber-400 w-8")}, list{text(Int.toString(op))})
                | None => span(list{Attrs.class_("text-gray-600 w-8")}, list{text("-")})
                },
                if instr.comment !== "" {
                  span(list{Attrs.class_("text-gray-500 italic")}, list{text(`; ${instr.comment}`)})
                } else {
                  noNode
                },
                button(
                  list{
                    Attrs.class_("ml-auto text-red-400 hover:text-red-300 cursor-pointer"),
                    Events.onClick(DlcWorkshop(RemoveInstruction(instr.index))),
                  },
                  list{text("x")},
                ),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render testing view.
let renderTesting = (state: dlcWorkshopState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
              ),
              Events.onClick(DlcWorkshop(RunAllTests)),
              KeyboardNav.onActivate(DlcWorkshop(RunAllTests)),
            },
            list{text("Run All Tests")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{
              text(
                `${Int.toString(DlcWorkshopEngine.passedTests(state.puzzles))}/${Int.toString(
                    Array.length(state.puzzles),
                  )} passed`,
              ),
            },
          ),
        },
      ),
      // Test results per puzzle
      div(
        list{Attrs.class_("space-y-1")},
        state.puzzles
        ->Array.map(puzzle => {
          let testCls = DlcWorkshopEngine.testStatusColour(puzzle.testStatus)
          div(
            list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded text-xs")},
            list{
              span(list{Attrs.class_("text-gray-200 w-40 truncate")}, list{text(puzzle.name)}),
              span(
                list{Attrs.class_(testCls)},
                list{text(DlcWorkshopEngine.testStatusLabel(puzzle.testStatus))},
              ),
              button(
                list{
                  Attrs.class_(
                    "ml-auto px-2 py-0.5 bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(DlcWorkshop(RunPuzzleTest(puzzle.id))),
                },
                list{text("Run")},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Render assets view.
let renderAssets = (state: dlcWorkshopState): Tea_Vdom.t<msg> => {
  if Array.length(state.assets) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{
        text("No assets loaded. "),
        button(
          list{
            Attrs.class_("text-cyan-400 hover:text-cyan-300 underline cursor-pointer"),
            Events.onClick(DlcWorkshop(BrowseDlcAssets)),
            KeyboardNav.onActivate(DlcWorkshop(BrowseDlcAssets)),
          },
          list{text("Browse assets")},
        ),
      },
    )
  } else {
    div(
      list{Attrs.class_("grid grid-cols-3 lg:grid-cols-4 gap-2")},
      state.assets
      ->Array.map(asset =>
        div(
          list{Attrs.class_("p-2 bg-gray-800 rounded border border-gray-700")},
          list{
            div(
              list{Attrs.class_("text-xs text-gray-100 font-medium truncate")},
              list{text(asset.name)},
            ),
            div(list{Attrs.class_("text-xs text-gray-500")}, list{text(asset.assetType)}),
            div(
              list{Attrs.class_("text-xs text-gray-600")},
              list{text(`${Int.toString(asset.sizeBytes / 1024)}KB`)},
            ),
          },
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render packaging view.
let renderPackaging = (state: dlcWorkshopState): Tea_Vdom.t<msg> => {
  let meta = state.packMeta
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Pack metadata
      div(
        list{Attrs.class_("p-4 bg-gray-800 rounded border border-gray-700")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-200 mb-3")},
            list{text("Pack Metadata")},
          ),
          div(
            list{Attrs.class_("grid grid-cols-2 gap-3 text-xs")},
            list{
              div(
                list{},
                list{
                  div(list{Attrs.class_("text-gray-500")}, list{text("Name")}),
                  div(list{Attrs.class_("text-gray-200")}, list{text(meta.name)}),
                },
              ),
              div(
                list{},
                list{
                  div(list{Attrs.class_("text-gray-500")}, list{text("Version")}),
                  div(list{Attrs.class_("text-gray-200")}, list{text(meta.version)}),
                },
              ),
              div(
                list{},
                list{
                  div(list{Attrs.class_("text-gray-500")}, list{text("Author")}),
                  div(list{Attrs.class_("text-gray-200")}, list{text(meta.author)}),
                },
              ),
              div(
                list{},
                list{
                  div(list{Attrs.class_("text-gray-500")}, list{text("Puzzles")}),
                  div(
                    list{Attrs.class_("text-gray-200")},
                    list{text(Int.toString(Array.length(state.puzzles)))},
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Package button
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                "px-4 py-2 text-sm bg-purple-700 text-white rounded hover:bg-purple-600 cursor-pointer",
              ),
              Events.onClick(DlcWorkshop(PackageDlc)),
              KeyboardNav.onActivate(DlcWorkshop(PackageDlc)),
            },
            list{text("Package DLC")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{
              text(
                `${Int.toString(Array.length(state.puzzles))} puzzles, ${Int.toString(
                    Array.length(state.assets),
                  )} assets`,
              ),
            },
          ),
        },
      ),
      // Chains
      if Array.length(state.chains) > 0 {
        div(
          list{Attrs.class_("space-y-2")},
          list{
            div(list{Attrs.class_("text-sm text-gray-300")}, list{text("Puzzle Chains")}),
            ...state.chains
            ->Array.map(chain =>
              div(
                list{Attrs.class_("p-2 bg-gray-800 rounded text-xs")},
                list{
                  div(
                    list{Attrs.class_("flex items-center justify-between")},
                    list{
                      span(list{Attrs.class_("text-gray-200")}, list{text(chain.name)}),
                      span(
                        list{Attrs.class_("text-gray-500")},
                        list{text(`${Int.toString(Array.length(chain.puzzleIds))} puzzles`)},
                      ),
                    },
                  ),
                },
              )
            )
            ->List.fromArray,
          },
        )
      } else {
        noNode
      },
    },
  )
}

/// Main view function.
let view = (state: dlcWorkshopState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("DLC Workshop panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-lg font-semibold text-gray-100")},
                list{text("DLC Workshop")},
              ),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text(state.packMeta.name)}),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(DlcWorkshop(ImportPuzzle)),
                  KeyboardNav.onActivate(DlcWorkshop(ImportPuzzle)),
                },
                list{text("Import")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(DlcWorkshop(ExportPuzzle)),
                  KeyboardNav.onActivate(DlcWorkshop(ExportPuzzle)),
                },
                list{text("Export")},
              ),
            },
          ),
        },
      ),
      // Category tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Puzzles", WorkshopPuzzles, state.activeCategory),
          renderTab("Composer", WorkshopComposer, state.activeCategory),
          renderTab("Testing", WorkshopTesting, state.activeCategory),
          renderTab("Assets", WorkshopAssets, state.activeCategory),
          renderTab("Packaging", WorkshopPackaging, state.activeCategory),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300",
            ),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                text(err),
                button(
                  list{
                    Attrs.class_("text-red-400 hover:text-red-200 cursor-pointer"),
                    Events.onClick(DlcWorkshop(DismissWorkshopError)),
                    KeyboardNav.onActivate(DlcWorkshop(DismissWorkshopError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Loading
      if state.loading {
        div(
          list{Attrs.class_("px-4 py-2 text-xs text-cyan-400 animate-pulse")},
          list{text("Loading DLC data...")},
        )
      } else {
        noNode
      },
      // Main content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | WorkshopPuzzles => renderPuzzles(state)
          | WorkshopComposer => renderComposer(state)
          | WorkshopTesting => renderTesting(state)
          | WorkshopAssets => renderAssets(state)
          | WorkshopPackaging => renderPackaging(state)
          },
        },
      ),
    },
  )
}
