// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Palimpsest Plaza Component — view layer for the PMPL licensing panel.
///
/// The Plaza is designed to be the first thing a new FOSS developer encounters
/// when they open PanLL. It should feel welcoming, helpful, and demonstrate
/// that PMPL licensing isn't bureaucracy — it's protection.
///
/// Layout:
///   - Header with PMPL branding, adoption stats, and close button
///   - Category tabs (Dashboard | Compliance | Provenance | Compatibility | Ethical Use | Governance | Adopt)
///   - Content area varies by tab

open Model
open Msg
open Tea.Html

/// Render a single category tab.
let renderCategoryTab = (cat: plazaCategory, isActive: bool): Tea_Vdom.t<msg> => {
  let activeClass = isActive
    ? "border-indigo-500 text-indigo-300 bg-gray-800/50"
    : "border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-600"

  button(
    list{
      Attrs.class_(
        `px-3 py-2 text-sm font-medium border-b-2 cursor-pointer transition-colors ${activeClass}`,
      ),
      Attrs.role("tab"),
      Events.onClick(Plaza(SetPlazaCategory(cat))),
    },
    list{text(PlazaEngine.categoryLabel(cat))},
  )
}

/// Render the category tab bar.
let renderCategoryTabBar = (activeCategory: plazaCategory): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex border-b border-gray-800 overflow-x-auto"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Plaza categories"),
    },
    PlazaEngine.allCategories
    ->Array.map(cat => renderCategoryTab(cat, cat === activeCategory))
    ->List.fromArray,
  )
}

/// Render a stat card for the dashboard.
let renderStatCard = (label: string, value: string, colour: string, subtitle: string): Tea_Vdom.t<
  msg,
> => {
  div(
    list{Attrs.class_("bg-gray-800/50 border border-gray-700 rounded-lg p-4")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")},
        list{text(label)},
      ),
      div(list{Attrs.class_(`text-2xl font-bold ${colour}`)}, list{text(value)}),
      div(list{Attrs.class_("text-xs text-gray-600 mt-1")}, list{text(subtitle)}),
    },
  )
}

/// Render a progress bar with label.
let renderProgressBar = (label: string, count: int, total: int, colour: string): Tea_Vdom.t<
  msg,
> => {
  let pct = if total > 0 {
    Float.toFixed(Int.toFloat(count) /. Int.toFloat(total) *. 100.0, ~digits=0)
  } else {
    "0"
  }
  div(
    list{Attrs.class_("flex items-center gap-3 py-1")},
    list{
      div(list{Attrs.class_("w-32 text-sm text-gray-400")}, list{text(label)}),
      div(
        list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(`h-full ${colour} rounded-full transition-all`),
              Attrs.style("width", `${pct}%`),
            },
            list{},
          ),
        },
      ),
      div(
        list{Attrs.class_("w-20 text-xs text-gray-500 text-right")},
        list{text(`${Int.toString(count)} (${pct}%)`)},
      ),
    },
  )
}

/// Render the Dashboard tab — adoption statistics overview.
let renderDashboard = (plaza: plazaState): Tea_Vdom.t<msg> => {
  switch plaza.stats {
  | None =>
    div(
      list{Attrs.class_("flex-1 flex flex-col items-center justify-center gap-4")},
      list{
        div(
          list{Attrs.class_("text-gray-400 text-lg")},
          list{text("Palimpsest License Ecosystem")},
        ),
        div(
          list{Attrs.class_("text-gray-600 text-sm max-w-md text-center")},
          list{
            text(
              "Scan your ecosystem to see PMPL adoption, compliance, and provenance statistics across all repositories.",
            ),
          },
        ),
        button(
          list{
            Attrs.class_(
              "px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-500 transition-colors font-medium",
            ),
            Events.onClick(Plaza(LoadAdoptionStats)),
            KeyboardNav.onActivate(Plaza(LoadAdoptionStats)),
          },
          list{text("Scan Ecosystem")},
        ),
      },
    )
  | Some(stats) =>
    div(
      list{Attrs.class_("flex-1 overflow-y-auto p-6 space-y-6")},
      list{
        // Stat cards row
        div(
          list{Attrs.class_("grid grid-cols-5 gap-4")},
          list{
            renderStatCard(
              "Total Repos",
              Int.toString(stats.totalRepos),
              "text-gray-200",
              "in ecosystem",
            ),
            renderStatCard(
              "PMPL Licensed",
              Int.toString(stats.pmplRepos),
              "text-indigo-400",
              `${Float.toFixed(PlazaEngine.adoptionPercentage(stats), ~digits=1)}% adoption`,
            ),
            renderStatCard(
              "MPL-2.0 Fallback",
              Int.toString(stats.mplFallbackRepos),
              "text-amber-400",
              "platform requirement",
            ),
            renderStatCard(
              "Unlicensed",
              Int.toString(stats.unlicensedRepos),
              stats.unlicensedRepos > 0 ? "text-red-400" : "text-emerald-400",
              stats.unlicensedRepos > 0 ? "need attention" : "all licensed",
            ),
            renderStatCard(
              "Quantum-Signed",
              Int.toString(stats.quantumSignedRepos),
              "text-purple-400",
              "post-quantum provenance",
            ),
          },
        ),
        // License breakdown
        div(
          list{Attrs.class_("bg-gray-800/30 border border-gray-800 rounded-lg p-4")},
          list{
            div(
              list{Attrs.class_("text-sm font-medium text-gray-300 mb-3")},
              list{text("License Distribution")},
            ),
            div(
              list{Attrs.class_("space-y-1")},
              stats.byLicense
              ->Array.map(((license, count)) => {
                let colour = switch license {
                | "PMPL-1.0-or-later" => "bg-indigo-500"
                | "MPL-2.0" => "bg-amber-500"
                | "MIT" => "bg-emerald-500"
                | "Apache-2.0" => "bg-blue-500"
                | "unlicensed" => "bg-red-500"
                | _ => "bg-gray-500"
                }
                renderProgressBar(license, count, stats.totalRepos, colour)
              })
              ->List.fromArray,
            ),
          },
        ),
        // Quick actions
        div(
          list{Attrs.class_("flex gap-3")},
          list{
            button(
              list{
                Attrs.class_(
                  "px-4 py-2 bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors text-sm",
                ),
                Events.onClick(Plaza(LoadAdoptionStats)),
                KeyboardNav.onActivate(Plaza(LoadAdoptionStats)),
              },
              list{text("Refresh Stats")},
            ),
          },
        ),
      },
    )
  }
}

/// Render the Compatibility tab — license compatibility checker.
let renderCompatibility = (_plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-6")},
    list{
      div(
        list{Attrs.class_("max-w-2xl")},
        list{
          div(
            list{Attrs.class_("text-lg font-medium text-gray-300 mb-4")},
            list{text("PMPL Compatibility Matrix")},
          ),
          div(
            list{Attrs.class_("text-sm text-gray-500 mb-6")},
            list{
              text(
                "PMPL-1.0-or-later uses file-level copyleft (inherited from MPL-2.0), making it compatible with most permissive and weak-copyleft licenses. PMPL files and MIT files can coexist in the same project.",
              ),
            },
          ),
          // Static compatibility table
          div(
            list{Attrs.class_("space-y-2")},
            [
              ("MIT", true, "Fully compatible"),
              ("Apache-2.0", true, "Compatible with patent grant"),
              ("BSD-2/3-Clause", true, "Fully compatible"),
              ("MPL-2.0", true, "Base layer — fully compatible"),
              ("GPL-2.0+", true, "Compatible via MPL-2.0 Section 3.3"),
              ("GPL-3.0+", true, "Compatible via MPL-2.0 Section 3.3"),
              ("LGPL-2.1+", true, "Compatible for library use"),
              ("AGPL-3.0", false, "Network copyleft conflicts with file-level scope"),
              ("ISC", true, "Fully compatible"),
              ("CC0/Unlicense", true, "Public domain — compatible with anything"),
            ]
            ->Array.map(((license, compat, notes)) => {
              let statusClass = compat
                ? "text-emerald-400 bg-emerald-900/30 border-emerald-800"
                : "text-red-400 bg-red-900/30 border-red-800"
              let statusLabel = compat ? "Compatible" : "Incompatible"
              div(
                list{
                  Attrs.class_(
                    "flex items-center gap-3 p-3 rounded border border-gray-800 bg-gray-800/20",
                  ),
                },
                list{
                  div(
                    list{Attrs.class_("w-32 text-sm font-medium text-gray-300")},
                    list{text(license)},
                  ),
                  span(
                    list{Attrs.class_(`text-xs px-2 py-0.5 rounded border ${statusClass}`)},
                    list{text(statusLabel)},
                  ),
                  div(list{Attrs.class_("flex-1 text-xs text-gray-500")}, list{text(notes)}),
                },
              )
            })
            ->List.fromArray,
          ),
        },
      ),
    },
  )
}

/// Render the Adopt tab — quick-start guide for new projects.
let renderAdoptionWizard = (_plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-6")},
    list{
      div(
        list{Attrs.class_("max-w-2xl space-y-6")},
        list{
          div(
            list{Attrs.class_("text-lg font-medium text-gray-300 mb-2")},
            list{text("Adopt PMPL for Your Project")},
          ),
          div(
            list{Attrs.class_("text-sm text-gray-500 mb-6")},
            list{
              text(
                "Three steps to protect your work with the Palimpsest License. File-level copyleft means you can mix PMPL with MIT, Apache, BSD — no project-wide infection.",
              ),
            },
          ),
          // Step 1
          div(
            list{Attrs.class_("bg-gray-800/30 border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2 mb-2")},
                list{
                  span(list{Attrs.class_("text-indigo-400 font-bold")}, list{text("1")}),
                  span(
                    list{Attrs.class_("text-sm font-medium text-gray-300")},
                    list{text("Add LICENSE file")},
                  ),
                },
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 font-mono bg-gray-900 rounded p-2")},
                list{
                  text(
                    "Copy LICENSE.txt from palimpsest-license/v1.0/LICENSE.txt to your project root",
                  ),
                },
              ),
            },
          ),
          // Step 2
          div(
            list{Attrs.class_("bg-gray-800/30 border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2 mb-2")},
                list{
                  span(list{Attrs.class_("text-indigo-400 font-bold")}, list{text("2")}),
                  span(
                    list{Attrs.class_("text-sm font-medium text-gray-300")},
                    list{text("Add SPDX headers to source files")},
                  ),
                },
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 font-mono bg-gray-900 rounded p-2")},
                list{text("// SPDX-License-Identifier: PMPL-1.0-or-later")},
              ),
            },
          ),
          // Step 3
          div(
            list{Attrs.class_("bg-gray-800/30 border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2 mb-2")},
                list{
                  span(list{Attrs.class_("text-indigo-400 font-bold")}, list{text("3")}),
                  span(
                    list{Attrs.class_("text-sm font-medium text-gray-300")},
                    list{text("Optional: Add exhibits and provenance")},
                  ),
                },
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    "Exhibit A (Ethical Use) and Exhibit B (Quantum-Safe Provenance) are optional but recommended for projects with AI training or long-term archival needs.",
                  ),
                },
              ),
            },
          ),
          // Why PMPL
          div(
            list{Attrs.class_("border-t border-gray-800 pt-4 mt-4")},
            list{
              div(
                list{Attrs.class_("text-sm font-medium text-gray-400 mb-2")},
                list{text("Why PMPL over MPL-2.0?")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 space-y-1")},
                list{
                  div(
                    list{},
                    list{text("Ethical Use Guidelines — community norms for responsible use")},
                  ),
                  div(
                    list{},
                    list{
                      text(
                        "Quantum-Safe Provenance — attribution that survives decades, not just years",
                      ),
                    },
                  ),
                  div(
                    list{},
                    list{
                      text("Emotional Lineage — recognition that code carries cultural meaning"),
                    },
                  ),
                  div(
                    list{},
                    list{
                      text(
                        "Same file-level copyleft as MPL-2.0 — no GPL-style project infection",
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
}

/// Render a compliance level badge.
let renderComplianceBadge = (level: complianceLevel): Tea_Vdom.t<msg> => {
  let (label, colour) = switch level {
  | FullCompliance => ("Full", "bg-green-700")
  | PartialCompliance => ("Partial", "bg-yellow-700")
  | NonCompliant => ("Non-Compliant", "bg-red-700")
  | Unknown => ("Unknown", "bg-gray-700")
  }
  span(list{Attrs.class_(`px-2 py-0.5 rounded text-xs ${colour} text-white`)}, list{text(label)})
}

/// Render the Compliance Audit tab — SPDX headers, LICENSE files, exhibit completeness.
let renderCompliance = (plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("mb-4 flex items-center justify-between")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400")},
            list{text(`${Int.toString(Array.length(plaza.audits))} repos audited`)},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs bg-indigo-800 text-indigo-200 rounded hover:bg-indigo-700",
              ),
              Attrs.ariaLabel("Run compliance scan on all repos"),
              Events.onClick(Plaza(LoadAdoptionStats)),
              KeyboardNav.onActivate(Plaza(LoadAdoptionStats)),
            },
            list{text("Scan All")},
          ),
        },
      ),
      if Array.length(plaza.audits) == 0 {
        div(
          list{Attrs.class_("text-center py-12")},
          list{
            div(list{Attrs.class_("text-gray-500 mb-2")}, list{text("No audits yet")}),
            div(
              list{Attrs.class_("text-xs text-gray-600 max-w-md mx-auto")},
              list{
                text(
                  "Scan repos for SPDX headers, LICENSE files, and exhibit completeness. Connect to pmpl-audit for deep scanning.",
                ),
              },
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          plaza.audits
          ->Array.map(audit =>
            div(
              list{
                Attrs.class_(
                  "p-3 bg-gray-900/50 rounded border border-gray-800 flex items-center justify-between",
                ),
              },
              list{
                div(
                  list{Attrs.class_("flex-1")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-300 flex items-center gap-2")},
                      list{text(audit.repoName), renderComplianceBadge(audit.level)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-600 mt-1")},
                      list{
                        text(
                          `${Int.toString(audit.filesWithHeaders)}/${Int.toString(
                              audit.filesScanned,
                            )} files with SPDX headers`,
                        ),
                      },
                    ),
                  },
                ),
                div(list{Attrs.class_("text-xs text-gray-600")}, list{text(audit.lastAudit)}),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the Provenance Verification tab — quantum-safe signatures.
let renderProvenance = (plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("mb-4 flex items-center justify-between")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400")},
            list{text(`${Int.toString(Array.length(plaza.signatures))} signatures`)},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs bg-indigo-800 text-indigo-200 rounded hover:bg-indigo-700",
              ),
              Attrs.ariaLabel("Verify all provenance signatures"),
              Events.onClick(Plaza(LoadAdoptionStats)),
              KeyboardNav.onActivate(Plaza(LoadAdoptionStats)),
            },
            list{text("Verify All")},
          ),
        },
      ),
      if Array.length(plaza.signatures) == 0 {
        div(
          list{Attrs.class_("text-center py-12")},
          list{
            div(list{Attrs.class_("text-gray-500 mb-2")}, list{text("No signatures found")}),
            div(
              list{Attrs.class_("text-xs text-gray-600 max-w-md mx-auto")},
              list{
                text(
                  "Verify quantum-safe signatures (ML-DSA, SLH-DSA) on files and commits. Connect to pmpl-verify for signature chain validation.",
                ),
              },
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          plaza.signatures
          ->Array.map(sig => {
            let (statusText, statusColour) = switch sig.status {
            | SignatureValid => ("Valid", "text-green-400")
            | SignatureInvalid(reason) => (`Invalid: ${reason}`, "text-red-400")
            | NoSignature => ("Missing", "text-gray-500")
            | ClassicalOnly => ("Classical", "text-yellow-400")
            }
            div(
              list{Attrs.class_("p-3 bg-gray-900/50 rounded border border-gray-800")},
              list{
                div(
                  list{Attrs.class_("flex items-center justify-between")},
                  list{
                    div(list{Attrs.class_("text-sm text-gray-300")}, list{text(sig.target)}),
                    span(list{Attrs.class_(`text-xs ${statusColour}`)}, list{text(statusText)}),
                  },
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-600 mt-1 flex items-center gap-3")},
                  list{
                    text(`Algorithm: ${sig.algorithm}`),
                    text(`Signer: ${sig.signer}`),
                    text(sig.timestamp),
                  },
                ),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the Ethical Use Guide tab — AI training disclosure and responsible use.
let renderEthicalUse = (_plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("max-w-2xl mx-auto space-y-6")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-300 border-b border-gray-800 pb-2")},
            list{text("Ethical Use Guide (Exhibit A)")},
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800 space-y-3")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-400 font-medium")},
                list{text("AI Training Disclosure")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    "If you use PMPL-licensed code in AI training datasets, Exhibit A requires disclosure. Provide a clear statement in your model card or data sheet identifying the PMPL-licensed sources used.",
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800 space-y-3")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-400 font-medium")},
                list{text("Cultural Sensitivity")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    "Respect the cultural context of code contributions. Attribution should preserve original authorship information and acknowledge cultural origins where relevant.",
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800 space-y-3")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-400 font-medium")},
                list{text("Responsible Use")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    "PMPL code should not be used in systems designed to cause harm, violate human rights, or circumvent legal protections. The stewardship council reviews edge cases.",
                  ),
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render the Governance tab — stewardship decisions and amendments.
let renderGovernance = (_plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("max-w-2xl mx-auto space-y-6")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-300 border-b border-gray-800 pb-2")},
            list{text("Stewardship Council")},
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800 space-y-2")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-400 font-medium")},
                list{text("License Governance")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    "The Palimpsest License is governed by the Stewardship Council. Proposed amendments require council review and community feedback. Governance decisions are recorded in the transparency log.",
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800 space-y-2")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-400 font-medium")},
                list{text("Amendment Process")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    "1. Proposal submission with rationale. 2. Community comment period (30 days). 3. Council deliberation. 4. Decision recorded in transparency log. 5. Implementation in next license version.",
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800 space-y-2")},
            list{
              div(list{Attrs.class_("text-xs text-gray-400 font-medium")}, list{text("Contact")}),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text("Governance proposals and ethical use questions: j.d.a.jewell@open.ac.uk"),
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render content based on active category.
let renderContent = (plaza: plazaState): Tea_Vdom.t<msg> => {
  switch plaza.activeCategory {
  | Dashboard => renderDashboard(plaza)
  | Compatibility => renderCompatibility(plaza)
  | Adopt => renderAdoptionWizard(plaza)
  | Compliance => renderCompliance(plaza)
  | Provenance => renderProvenance(plaza)
  | EthicalUse => renderEthicalUse(plaza)
  | Governance => renderGovernance(plaza)
  }
}

/// Render the header bar.
let renderHeader = (plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-4")},
        list{
          div(
            list{Attrs.class_("text-lg font-medium text-gray-200")},
            list{text("Palimpsest Plaza")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text("PMPL-1.0-or-later adoption and governance hub")},
          ),
          switch plaza.stats {
          | Some(stats) =>
            div(
              list{Attrs.class_("flex items-center gap-2 text-xs")},
              list{
                span(
                  list{Attrs.class_("text-indigo-400")},
                  list{text(`${Int.toString(stats.pmplRepos)} PMPL`)},
                ),
                span(list{Attrs.class_("text-gray-700")}, list{text("/")}),
                span(
                  list{Attrs.class_("text-gray-500")},
                  list{text(`${Int.toString(stats.totalRepos)} repos`)},
                ),
              },
            )
          | None => noNode
          },
        },
      ),
      button(
        list{
          Attrs.class_(
            "px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors",
          ),
          Events.onClick(PanelSwitcher(ClosePanels)),
          KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
        },
        list{text("Close")},
      ),
    },
  )
}

/// Main Plaza panel view — full-screen overlay.
let view = (plaza: plazaState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.ariaLabel("Palimpsest Plaza panel"),
    },
    list{
      renderHeader(plaza),
      renderCategoryTabBar(plaza.activeCategory),
      if plaza.loading {
        div(
          list{Attrs.class_("flex-1 flex items-center justify-center")},
          list{
            div(
              list{Attrs.class_("text-gray-500 animate-pulse")},
              list{text("Scanning ecosystem...")},
            ),
          },
        )
      } else {
        switch plaza.error {
        | Some(e) =>
          div(
            list{Attrs.class_("flex-1 flex items-center justify-center")},
            list{
              div(
                list{Attrs.class_("text-center")},
                list{
                  div(list{Attrs.class_("text-red-400 mb-2")}, list{text("Error")}),
                  div(list{Attrs.class_("text-sm text-gray-500")}, list{text(e)}),
                },
              ),
            },
          )
        | None => renderContent(plaza)
        }
      },
    },
  )
}
