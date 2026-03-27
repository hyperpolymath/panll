// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — VoiceTag Component (Layer 0)
///
/// View layer for the tag management panel. Renders:
///   - Tag list with type badges, line ranges, and attribution
///   - Voice input controls (start/stop listening, transcript display)
///   - Tag creation form (keyboard fallback for non-voice input)
///   - Filter controls (by type, resolved/unresolved)
///   - Summary bar (total tags, unresolved count, AI vs human ratio)
///
/// The component is designed as an ambient sidebar or panel overlay,
/// depending on how the user configures their layout. It always shows
/// the tags for the currently active file.
///
/// STANDALONE-FIRST: This UI is one consumer of the .mri.json format.
/// The same tags can be viewed/edited by CLI tools, VS Code extensions,
/// or any JSON-aware tool. PanLL adds voice input and agentic integration.

open Model
open Msg
open Tea.Html

// ===========================================================================
// Tag type badge — coloured pill showing tag category
// ===========================================================================

/// Render a tag type badge (coloured pill).
let renderTagBadge = (tagType: mriTagType): Tea_Vdom.t<msg> => {
  let (bg, text_, border) = VoiceTagEngine.tagTypeColour(tagType)
  let label = VoiceTagEngine.tagTypeShort(tagType)
  let isModal = VoiceTagEngine.isModalTag(tagType)
  span(
    list{
      Attrs.class_(
        `text-xs px-1.5 py-0.5 rounded border ${bg} ${text_} ${border} ${isModal
            ? "ring-1 ring-pink-500/30"
            : ""}`,
      ),
      Attrs.title(
        VoiceTagEngine.tagTypeLabel(tagType) ++ (
          isModal ? " (modal — affects system behaviour)" : ""
        ),
      ),
    },
    list{text(label)},
  )
}

// ===========================================================================
// Attribution display — who created the tag and how
// ===========================================================================

/// Render attribution info (agent + method).
let renderAttribution = (attr: mriAttribution): Tea_Vdom.t<msg> => {
  let methodStr = VoiceTagEngine.methodLabel(attr.method)
  let isAi = attr.agent !== "human"
  let agentColour = isAi ? "text-amber-400" : "text-emerald-400"
  span(
    list{Attrs.class_("text-xs text-gray-500 flex items-center gap-1")},
    list{
      span(list{Attrs.class_(agentColour)}, list{text(attr.agent)}),
      span(list{Attrs.class_("text-gray-700")}, list{text("·")}),
      span(list{}, list{text(methodStr)}),
    },
  )
}

// ===========================================================================
// Single tag row
// ===========================================================================

/// Render a single tag in the tag list.
let renderTag = (tag: mriTag, isSelected: bool): Tea_Vdom.t<msg> => {
  let selectedClass = isSelected
    ? "bg-gray-800/70 border-indigo-600"
    : "border-gray-800/50 hover:bg-gray-800/30"
  let resolvedClass = tag.resolved ? "opacity-60" : ""
  let lineStr =
    tag.startLine === tag.endLine
      ? `L${Int.toString(tag.startLine)}`
      : `L${Int.toString(tag.startLine)}-${Int.toString(tag.endLine)}`

  div(
    list{
      Attrs.class_(
        `flex items-center gap-2 px-3 py-2 border-b ${selectedClass} ${resolvedClass} transition-colors cursor-pointer`,
      ),
      Attrs.ariaLabel(VoiceTagEngine.tagAriaLabel(tag)),
      Events.onClick(VoiceTag(SelectTag(Some(tag.id)))),
    },
    list{
      // Tag number (for voice reference: "show tag 3")
      span(
        list{Attrs.class_("text-xs text-gray-600 w-6 text-right font-mono")},
        list{text(`#${Int.toString(tag.id)}`)},
      ),
      // Tag type badge
      renderTagBadge(tag.tagType),
      // Line range
      span(list{Attrs.class_("text-xs text-gray-500 font-mono w-16")}, list{text(lineStr)}),
      // Message (if any)
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          switch tag.message {
          | Some(m) =>
            span(list{Attrs.class_("text-sm text-gray-300 truncate block")}, list{text(m)})
          | None =>
            span(list{Attrs.class_("text-sm text-gray-600 italic")}, list{text("(no message)")})
          },
        },
      ),
      // Attribution
      renderAttribution(tag.attribution),
      // Resolved indicator
      if tag.resolved {
        span(
          list{Attrs.class_("text-xs text-emerald-600"), Attrs.title("Resolved")},
          list{text("R")},
        )
      } else {
        noNode
      },
      // Actions: resolve, delete
      div(
        list{Attrs.class_("flex items-center gap-1 ml-2")},
        list{
          if !tag.resolved {
            button(
              list{
                Attrs.class_(
                  "text-xs px-1.5 py-0.5 text-gray-500 hover:text-emerald-400 hover:bg-gray-800 rounded transition-colors",
                ),
                Attrs.title("Resolve tag"),
                Events.onClick(VoiceTag(ResolveTagById(tag.id))),
              },
              list{text("R")},
            )
          } else {
            noNode
          },
          button(
            list{
              Attrs.class_(
                "text-xs px-1.5 py-0.5 text-gray-500 hover:text-red-400 hover:bg-gray-800 rounded transition-colors",
              ),
              Attrs.title("Delete tag"),
              Events.onClick(VoiceTag(DeleteTagById(tag.id))),
            },
            list{text("X")},
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Voice controls — start/stop listening, status indicator
// ===========================================================================

/// Render voice input controls.
let renderVoiceControls = (voice: voiceState): Tea_Vdom.t<msg> => {
  let (statusText, statusClass, buttonLabel, buttonAction) = switch voice {
  | VoiceOff => ("Off", "text-gray-600", "Start Voice", VoiceTag(StartVoice))
  | VoiceListening => (
      "Listening...",
      "text-emerald-400 animate-pulse",
      "Stop",
      VoiceTag(StopVoice),
    )
  | VoiceProcessing(transcript) => (
      `Processing: "${transcript}"`,
      "text-amber-400",
      "Cancel",
      VoiceTag(StopVoice),
    )
  | VoiceError(err) => (`Error: ${err}`, "text-red-400", "Retry", VoiceTag(StartVoice))
  }

  div(
    list{Attrs.class_("flex items-center gap-3 px-4 py-2 border-b border-gray-800 bg-gray-900/50")},
    list{
      // Voice status indicator
      div(
        list{Attrs.class_("flex items-center gap-2 flex-1")},
        list{
          // Mic icon (simple text indicator)
          span(
            list{
              Attrs.class_(
                switch voice {
                | VoiceListening => "text-emerald-400 text-lg"
                | _ => "text-gray-600 text-lg"
                },
              ),
            },
            list{text("M")},
          ),
          span(list{Attrs.class_(`text-xs ${statusClass}`)}, list{text(statusText)}),
        },
      ),
      // Voice toggle button
      button(
        list{
          Attrs.class_(
            "px-3 py-1 text-xs rounded transition-colors " ++
            switch voice {
            | VoiceListening => "bg-red-900/50 text-red-300 hover:bg-red-800/50 border border-red-700"
            | _ => "bg-gray-800 text-gray-300 hover:bg-gray-700 border border-gray-700"
            },
          ),
          Events.onClick(buttonAction),
          Attrs.ariaLabel(buttonLabel),
        },
        list{text(buttonLabel)},
      ),
    },
  )
}

// ===========================================================================
// Summary bar — aggregate stats for the current file
// ===========================================================================

/// Render the summary statistics bar.
let renderSummary = (summary: mriFileSummary): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "flex items-center gap-4 px-4 py-2 border-b border-gray-800 text-xs text-gray-500",
      ),
    },
    list{
      span(list{}, list{text(`${Int.toString(summary.totalTags)} tags`)}),
      span(list{Attrs.class_("text-gray-700")}, list{text("|")}),
      span(
        list{Attrs.class_(summary.unresolvedTags > 0 ? "text-amber-400" : "")},
        list{text(`${Int.toString(summary.unresolvedTags)} open`)},
      ),
      span(list{Attrs.class_("text-gray-700")}, list{text("|")}),
      span(list{}, list{text(`${Int.toString(summary.humanTagCount)} human`)}),
      span(list{}, list{text(`${Int.toString(summary.aiTagCount)} AI`)}),
      if summary.careOnRegions > 0 {
        span(
          list{Attrs.class_("text-pink-400")},
          list{text(`${Int.toString(summary.careOnRegions)} care-on`)},
        )
      } else {
        noNode
      },
      if summary.ecoModeRegions > 0 {
        span(
          list{Attrs.class_("text-emerald-400")},
          list{text(`${Int.toString(summary.ecoModeRegions)} eco`)},
        )
      } else {
        noNode
      },
    },
  )
}

// ===========================================================================
// Filter controls — type filter, show resolved toggle
// ===========================================================================

/// Render the filter bar.
let renderFilters = (filterType: option<mriTagType>, showResolved: bool): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2 px-4 py-2 border-b border-gray-800")},
    list{
      // Type filter buttons
      button(
        list{
          Attrs.class_(
            `text-xs px-2 py-1 rounded transition-colors ${filterType === None
                ? "bg-indigo-900/50 text-indigo-300 border border-indigo-700"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Events.onClick(VoiceTag(SetFilterType(None))),
        },
        list{text("All")},
      ),
      button(
        list{
          Attrs.class_(
            `text-xs px-2 py-1 rounded transition-colors ${filterType === Some(Todo)
                ? "bg-blue-900/50 text-blue-300 border border-blue-700"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Events.onClick(VoiceTag(SetFilterType(Some(Todo)))),
        },
        list{text("TODO")},
      ),
      button(
        list{
          Attrs.class_(
            `text-xs px-2 py-1 rounded transition-colors ${filterType === Some(Fixme)
                ? "bg-red-900/50 text-red-300 border border-red-700"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Events.onClick(VoiceTag(SetFilterType(Some(Fixme)))),
        },
        list{text("FIXME")},
      ),
      button(
        list{
          Attrs.class_(
            `text-xs px-2 py-1 rounded transition-colors ${filterType === Some(Refactor)
                ? "bg-amber-900/50 text-amber-300 border border-amber-700"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Events.onClick(VoiceTag(SetFilterType(Some(Refactor)))),
        },
        list{text("REFACTOR")},
      ),
      button(
        list{
          Attrs.class_(
            `text-xs px-2 py-1 rounded transition-colors ${filterType === Some(Review)
                ? "bg-cyan-900/50 text-cyan-300 border border-cyan-700"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Events.onClick(VoiceTag(SetFilterType(Some(Review)))),
        },
        list{text("REVIEW")},
      ),
      // Spacer
      div(list{Attrs.class_("flex-1")}, list{}),
      // Show resolved toggle
      button(
        list{
          Attrs.class_(
            `text-xs px-2 py-1 rounded transition-colors ${showResolved
                ? "bg-gray-700 text-gray-300"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Events.onClick(VoiceTag(ToggleShowResolved)),
        },
        list{text(showResolved ? "Hide Resolved" : "Show Resolved")},
      ),
    },
  )
}

// ===========================================================================
// Header — file name, controls, close button
// ===========================================================================

/// Render the panel header.
let renderHeader = (currentFile: option<string>): Tea_Vdom.t<msg> => {
  let fileName = switch currentFile {
  | Some(f) => f
  | None => "(no file)"
  }
  div(
    list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
    list{
      // Title
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          div(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Code MRI")}),
          span(list{Attrs.class_("text-xs text-gray-500")}, list{text("VoiceTag")}),
          span(
            list{Attrs.class_("text-xs text-gray-600 font-mono truncate max-w-xs")},
            list{text(fileName)},
          ),
        },
      ),
      // Controls
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          // Load tags for current file
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-gray-800 text-gray-300 rounded hover:bg-gray-700 border border-gray-700 transition-colors",
              ),
              Events.onClick(VoiceTag(LoadFileTags)),
              Attrs.title("Reload tags from .mri.json"),
            },
            list{text("Reload")},
          ),
          // Close button
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Empty state — no tags yet
// ===========================================================================

/// Render the empty state when no tags exist.
let renderEmpty = (): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 flex items-center justify-center")},
    list{
      div(
        list{Attrs.class_("text-center max-w-sm")},
        list{
          div(list{Attrs.class_("text-gray-500 text-lg mb-2")}, list{text("No tags yet")}),
          div(
            list{Attrs.class_("text-gray-600 text-sm mb-4")},
            list{
              text(
                "Use voice commands or the keyboard to annotate code regions. Tags are saved as .mri.json sidecars — portable, no PanLL required.",
              ),
            },
          ),
          div(
            list{Attrs.class_("text-xs text-gray-700 space-y-1")},
            list{
              div(list{}, list{text("Voice: \"line 24 to 34 tag todo fix this later\"")}),
              div(list{}, list{text("Voice: \"tag fixme needs error handling\"")}),
              div(list{}, list{text("Voice: \"resolve tag 3\"")}),
            },
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Main view — full-screen panel overlay
// ===========================================================================

/// Main VoiceTag panel view — renders as a full-screen overlay.
///
/// Layout:
///   Header (title, file name, reload, close)
///   Voice controls (mic toggle, status, transcript)
///   Summary bar (tag counts, human/AI ratio)
///   Filter bar (type filter, resolved toggle)
///   Tag list (scrollable)
let view = (vt: voiceTagState): Tea_Vdom.t<msg> => {
  // Apply filters to the tag list.
  let filteredTags = {
    let byType = switch vt.filterType {
    | Some(t) => VoiceTagEngine.filterByType(vt.tags, t)
    | None => vt.tags
    }
    if vt.showResolved {
      byType
    } else {
      VoiceTagEngine.filterUnresolved(byType)
    }
  }

  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.ariaLabel("Code MRI VoiceTag panel"),
    },
    list{
      // Header
      renderHeader(vt.currentFile),
      // Voice controls
      renderVoiceControls(vt.voice),
      // Summary bar
      renderSummary(vt.summary),
      // Filter bar
      renderFilters(vt.filterType, vt.showResolved),
      // Error display
      switch vt.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 border-b border-red-800 text-xs text-red-400"),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Tag list (scrollable)
      if Array.length(filteredTags) === 0 {
        renderEmpty()
      } else {
        div(
          list{Attrs.class_("flex-1 overflow-y-auto")},
          filteredTags
          ->Array.map(tag => renderTag(tag, vt.selectedTagId === Some(tag.id)))
          ->List.fromArray,
        )
      },
    },
  )
}
