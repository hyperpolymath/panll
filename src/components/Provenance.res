// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Provenance Component — Code trust surface visualization.
///
/// Renders the Qubes-style ambient provenance overlay that shows who wrote
/// each piece of code and how trustworthy it is. This is CORE infrastructure,
/// always visible, not a panel overlay.
///
/// Visual design:
///   - Trust summary bar (compact, always visible in header area)
///   - Per-region colour coding with shape indicators
///   - Hostile UX: pulsing red borders on unreviewed AI regions
///   - Accessibility: palettes swap hues, shapes + labels provide redundancy
///   - Screen reader: ARIA labels announce trust level, not colour

open Model
open Msg
open Tea.Html

/// Render a single trust level indicator with its count and percentage.
/// Uses shape + colour + label for triple redundancy (accessibility).
let renderTrustIndicator = (
  level: trustLevel,
  lineCount: int,
  totalLines: int,
  palette: accessibilityPalette,
): Tea_Vdom.t<msg> => {
  let (_bgClass, textClass, borderClass) = ProvenanceEngine.trustColours(level, palette)
  let label = ProvenanceEngine.trustShortLabel(level)
  let ariaLabel = ProvenanceEngine.trustAriaLabel(level)
  let shape = ProvenanceEngine.trustShape(level)
  let pct = if totalLines > 0 {
    Float.toFixed(Float.fromInt(lineCount) /. Float.fromInt(totalLines) *. 100.0, ~digits=0)
  } else {
    "0"
  }

  div(
    list{
      Attrs.class_(`flex items-center gap-1 px-2 py-1 border rounded text-xs ${textClass} ${borderClass}`),
      Attrs.ariaLabel(ariaLabel),
      Attrs.role("status"),
    },
    list{
      // Shape indicator (redundant channel beyond colour)
      // Using text labels instead of emoji for ReScript compatibility.
      span(list{Attrs.class_("text-xs font-mono"), Attrs.ariaHidden(true)}, list{
        text(switch shape {
        | "shield-check" => "[V]"
        | "user-check" => "[H]"
        | "cpu" => "[A]"
        | "alert-triangle" => "[!]"
        | _ => "[?]"
        }),
      }),
      span(list{}, list{text(`${label}: ${pct}%`)}),
      span(list{Attrs.class_("text-gray-600")}, list{text(`(${Int.toString(lineCount)})`)}),
    },
  )
}

/// Render the compact trust summary bar.
/// Shows the trust distribution as a horizontal bar with colour segments
/// and individual indicators for each trust level.
let renderSummaryBar = (
  summary: provenanceSummary,
  palette: accessibilityPalette,
): Tea_Vdom.t<msg> => {
  let total = summary.totalLines
  let trustPct = ProvenanceEngine.trustPercentage(summary)

  div(
    list{
      Attrs.class_("flex items-center gap-3 px-3 py-1.5 bg-gray-900/80 border-b border-gray-800"),
      Attrs.role("region"),
      Attrs.ariaLabel(`Code provenance: ${Float.toFixed(trustPct, ~digits=0)}% trusted`),
    },
    list{
      // Title
      span(list{Attrs.class_("text-xs text-gray-500 font-medium mr-2")}, list{text("Provenance")}),

      // Segmented progress bar showing trust distribution
      div(list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded-full overflow-hidden flex")}, list{
        if total > 0 {
          let segment = (lines, colour) => {
            let width = Float.toFixed(Float.fromInt(lines) /. Float.fromInt(total) *. 100.0, ~digits=1)
            div(list{Attrs.class_(`h-full ${colour}`), Attrs.style("width", `${width}%`)}, list{})
          }
          let (vBg, _, _) = ProvenanceEngine.trustColours(Verified, palette)
          let (hBg, _, _) = ProvenanceEngine.trustColours(HumanReviewed, palette)
          let (aBg, _, _) = ProvenanceEngine.trustColours(AiAssisted, palette)
          let (rBg, _, _) = ProvenanceEngine.trustColours(UnreviewedAi, palette)
          let (gBg, _, _) = ProvenanceEngine.trustColours(Unknown, palette)
          div(list{Attrs.class_("flex w-full h-full")}, list{
            segment(summary.verifiedLines, vBg),
            segment(summary.humanReviewedLines, hBg),
            segment(summary.aiAssistedLines, aBg),
            segment(summary.unreviewedAiLines, rBg),
            segment(summary.unknownLines, gBg),
          })
        } else {
          div(list{Attrs.class_("h-full w-full bg-gray-700")}, list{})
        },
      }),

      // Trust score
      span(
        list{
          Attrs.class_(
            `text-xs font-mono ml-2 ${trustPct > 80.0
              ? "text-green-400"
              : trustPct > 50.0
                ? "text-amber-400"
                : "text-red-400"}`,
          ),
        },
        list{text(`${Float.toFixed(trustPct, ~digits=0)}%`)},
      ),

      // Violation warning
      if summary.hasViolations {
        span(
          list{
            Attrs.class_("text-xs text-red-400 animate-pulse ml-2"),
            Attrs.role("alert"),
            Attrs.ariaLabel("Unreviewed AI code detected"),
          },
          list{text("[!] UNREVIEWED AI")},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the detailed trust breakdown (expanded view).
/// Shows per-level indicators with line counts and percentages.
let renderDetailedBreakdown = (
  summary: provenanceSummary,
  palette: accessibilityPalette,
): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-wrap gap-2 px-3 py-2 bg-gray-900/60 border-b border-gray-800")},
    list{
      renderTrustIndicator(Verified, summary.verifiedLines, summary.totalLines, palette),
      renderTrustIndicator(HumanReviewed, summary.humanReviewedLines, summary.totalLines, palette),
      renderTrustIndicator(AiAssisted, summary.aiAssistedLines, summary.totalLines, palette),
      renderTrustIndicator(UnreviewedAi, summary.unreviewedAiLines, summary.totalLines, palette),
      renderTrustIndicator(Unknown, summary.unknownLines, summary.totalLines, palette),
      // Author and co-author counts
      span(list{Attrs.class_("text-xs text-gray-500 ml-auto")}, list{
        text(`${Int.toString(summary.authorCount)} authors, ${Int.toString(summary.coAuthorCount)} AI co-authors`),
      }),
    },
  )
}

/// Render the palette selector for accessibility options.
let renderPaletteSelector = (active: accessibilityPalette): Tea_Vdom.t<msg> => {
  let palettes: array<(accessibilityPalette, string)> = [
    (StandardPalette, "Standard"),
    (DeuteranopiaPalette, "Deuteranopia"),
    (ProtanopiaPalette, "Protanopia"),
    (HighContrastPalette, "High Contrast"),
  ]
  div(
    list{
      Attrs.class_("flex gap-1 px-3 py-1"),
      Attrs.role("radiogroup"),
      Attrs.ariaLabel("Select accessibility palette"),
    },
    palettes
    ->Array.map(((palette, label)) => {
      let isActive = palette === active
      button(
        list{
          Attrs.class_(
            `px-2 py-0.5 text-xs rounded ${isActive
              ? "bg-gray-700 text-gray-200"
              : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("radio"),
          Attrs.ariaSelected(isActive),
          Attrs.title(`Switch to ${label} colour palette`),
          Events.onClick(Provenance(SetPalette(palette))),
        },
        list{text(label)},
      )
    })
    ->List.fromArray,
  )
}

/// Render the hostile UX suppression toggle.
/// This is the "pull the smoke alarm battery" button — visible, deliberate,
/// and everyone knows you did it.
let renderHostileUxToggle = (suppressed: bool): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        `px-2 py-1 text-xs rounded ${suppressed
          ? "bg-red-900/50 text-red-300 border border-red-700"
          : "bg-gray-800 text-gray-400 hover:bg-gray-700"}`,
      ),
      Events.onClick(Provenance(ToggleHostileUx)),
      Attrs.ariaLabel(
        suppressed
          ? "Hostile UX suppressed — click to re-enable violation warnings"
          : "Click to suppress hostile UX warnings",
      ),
    },
    list{
      text(
        suppressed
          ? "[!] Warnings Suppressed"
          : "Suppress Warnings",
      ),
    },
  )
}

/// The main provenance view — renders as an ambient bar, not a panel overlay.
/// This is called from View.res and sits above the three-panel layout.
let view = (prov: provenanceState): Tea_Vdom.t<msg> => {
  if !prov.enabled {
    noNode
  } else {
    div(
      list{
        Attrs.class_("relative z-20"),
        Attrs.role("complementary"),
        Attrs.ariaLabel("Code provenance trust surface"),
      },
      list{
        switch prov.activeFile {
        | Some(file) =>
          div(list{}, list{
            renderSummaryBar(file.summary, prov.palette),
            renderDetailedBreakdown(file.summary, prov.palette),
          })
        | None =>
          // No file active — show minimal indicator
          div(
            list{Attrs.class_("px-3 py-1 bg-gray-900/60 border-b border-gray-800 flex items-center gap-2")},
            list{
              span(list{Attrs.class_("text-xs text-gray-600")}, list{text("Provenance: no file selected")}),
              renderHostileUxToggle(prov.hostileUxSuppressed),
            },
          )
        },
      },
    )
  }
}
