// SPDX-License-Identifier: MPL-2.0

/// PanLL Stapeln Assembly Pipeline — container stack assembly view.
///
/// Renders within PanLL's three-panel framework to provide an overview
/// of container assembly constraints, reasoning, and generated artifacts.
/// The detailed node editor lives in stapeln's own frontend; this panel
/// shows the mission-control view: constraints, validation, and outputs.
///
/// Three-panel layout:
///   Panel-L (Constraints & Discovery)  — security, resource, network policy
///   Panel-N (Assembly Reasoning)       — pipeline state, optimisation, posture
///   Panel-W (Results & Artifacts)      — Containerfile, compose, scan results

open Model
open Msg
open Tea.Html

// ============================================================================
// Panel-L: Constraints & Discovery
// ============================================================================

/// Render a single constraint row with label and value.
let constraintRow = (label: string, value: string, ~highlight: bool=false): Tea_Vdom.t<msg> => {
  let valueCls = highlight ? "text-sm font-medium text-emerald-400" : "text-sm text-gray-300"
  div(
    list{Attrs.class_("flex items-center justify-between py-1.5 border-b border-gray-800")},
    list{
      span(list{Attrs.class_("text-xs text-gray-500")}, list{text(label)}),
      span(list{Attrs.class_(valueCls)}, list{text(value)}),
    },
  )
}

/// Render a boolean constraint as a coloured badge.
let boolBadge = (label: string, enabled: bool): Tea_Vdom.t<msg> => {
  let (badgeCls, badgeText) = enabled
    ? ("px-2 py-0.5 text-xs bg-emerald-900 text-emerald-300 rounded", "Required")
    : ("px-2 py-0.5 text-xs bg-gray-800 text-gray-500 rounded", "Off")
  div(
    list{Attrs.class_("flex items-center justify-between py-1.5 border-b border-gray-800")},
    list{
      span(list{Attrs.class_("text-xs text-gray-500")}, list{text(label)}),
      span(list{Attrs.class_(badgeCls)}, list{text(badgeText)}),
    },
  )
}

/// Render a registry constraint row.
let registryRow = (rc: registryConstraint): Tea_Vdom.t<msg> => {
  let (cls, icon) = rc.allowed ? ("text-emerald-400", "ALLOW") : ("text-red-400", "DENY")
  div(
    list{Attrs.class_("flex items-center justify-between py-1 px-2 bg-gray-900 rounded mb-1")},
    list{
      span(list{Attrs.class_("text-xs text-gray-400 font-mono")}, list{text(rc.registry)}),
      span(list{Attrs.class_(`text-xs font-medium ${cls}`)}, list{text(icon)}),
    },
  )
}

/// Panel-L: Security and resource constraints editor.
let viewConstraints = (model: model): Tea_Vdom.t<msg> => {
  let st = model.stapeln
  let c = st.constraints
  div(
    list{Attrs.class_("p-4 space-y-4")},
    list{
      // Header
      h3(
        list{Attrs.class_("text-lg font-semibold text-white mb-2")},
        list{text("Assembly Constraints")},
      ),
      // Security constraints section
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(
            list{Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider mb-2")},
            list{text("Supply Chain Security")},
          ),
          constraintRow("SLSA Level", StapelnEngine.slsaLabel(c.minSlsaLevel), ~highlight=true),
          constraintRow("Signature Policy", StapelnEngine.signaturePolicyLabel(c.signaturePolicy)),
          constraintRow("SBOM Format", StapelnEngine.sbomFormatLabel(c.sbomFormat)),
          boolBadge("Healthcheck", c.requireHealthcheck),
          boolBadge("Non-Root", c.requireNonRoot),
        },
      ),
      // Resource constraints section
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(
            list{
              Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider mb-2 mt-3"),
            },
            list{text("Resource Limits")},
          ),
          constraintRow("Max Image Size", Int.toString(c.maxImageSizeMb) ++ " MB"),
          constraintRow("Memory Limit", Int.toString(c.memoryLimitMb) ++ " MB"),
          constraintRow("CPU Limit", Float.toString(c.cpuLimit) ++ " cores"),
        },
      ),
      // Registry constraints
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(
            list{
              Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider mb-2 mt-3"),
            },
            list{text("Registry Policy")},
          ),
          div(
            list{Attrs.class_("space-y-1")},
            c.registryConstraints->Array.map(registryRow)->List.fromArray,
          ),
        },
      ),
      // Denied images
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(
            list{
              Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider mb-2 mt-3"),
            },
            list{text("Denied Images")},
          ),
          div(
            list{Attrs.class_("space-y-1")},
            c.deniedImages
            ->Array.map(img =>
              div(
                list{Attrs.class_("px-2 py-1 bg-red-950 text-red-400 text-xs font-mono rounded")},
                list{text(img)},
              )
            )
            ->List.fromArray,
          ),
        },
      ),
      // Network policy
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(
            list{
              Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider mb-2 mt-3"),
            },
            list{text("Network Policy")},
          ),
          div(
            list{Attrs.class_("space-y-1")},
            c.networkRules
            ->Array.map(rule => {
              let protocolStr = switch rule.protocol {
              | Tcp => "TCP"
              | Udp => "UDP"
              | Sctp => "SCTP"
              }
              let dirCls = rule.direction === "ingress" ? "text-cyan-400" : "text-amber-400"
              div(
                list{Attrs.class_("flex items-center gap-2 px-2 py-1 bg-gray-900 rounded")},
                list{
                  span(
                    list{Attrs.class_(`text-xs font-medium ${dirCls}`)},
                    list{text(rule.direction)},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-300 font-mono")},
                    list{text(protocolStr ++ ":" ++ Int.toString(rule.port))},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-500 ml-auto")},
                    list{text(rule.description)},
                  ),
                },
              )
            })
            ->List.fromArray,
          ),
        },
      ),
      // Connect / Disconnect button
      div(
        list{Attrs.class_("pt-3")},
        list{
          button(
            list{
              Attrs.class_(
                if st.connected {
                  "w-full px-3 py-2 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer"
                } else {
                  "w-full px-3 py-2 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
                },
              ),
              Events.onClick(Stapeln(Connect)),
              KeyboardNav.onActivate(Stapeln(Connect)),
            },
            list{
              text(
                if st.connected {
                  "Connected"
                } else {
                  "Connect to Pipeline"
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Panel-N: Assembly Reasoning
// ============================================================================

/// Render a stat card for the pipeline overview.
let statCard = (label: string, value: string, colour: string): Tea_Vdom.t<msg> =>
  div(
    list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
    list{
      div(list{Attrs.class_(`text-2xl font-light ${colour}`)}, list{text(value)}),
      div(list{Attrs.class_("text-xs text-gray-500")}, list{text(label)}),
    },
  )

/// Render a single optimisation suggestion row.
let suggestionRow = (s: optimisationSuggestion): Tea_Vdom.t<msg> => {
  let severityCls = switch s.severity {
  | "critical" => "text-red-400"
  | "warning" => "text-amber-400"
  | _ => "text-blue-400"
  }
  let categoryCls = switch s.category {
  | "security" => "bg-red-900 text-red-300"
  | "size" => "bg-cyan-900 text-cyan-300"
  | "performance" => "bg-purple-900 text-purple-300"
  | _ => "bg-gray-700 text-gray-300"
  }
  div(
    list{Attrs.class_("p-2 bg-gray-900 rounded border border-gray-800 space-y-1")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          span(list{Attrs.class_(`text-xs font-medium ${severityCls}`)}, list{text(s.severity)}),
          span(
            list{Attrs.class_(`px-1.5 py-0.5 text-xs rounded ${categoryCls}`)},
            list{text(s.category)},
          ),
          if s.autoFixAvailable {
            span(list{Attrs.class_("text-xs text-emerald-500 ml-auto")}, list{text("auto-fix")})
          } else {
            text("")
          },
        },
      ),
      div(list{Attrs.class_("text-xs text-gray-300")}, list{text(s.message)}),
    },
  )
}

/// Panel-N: Pipeline state overview and reasoning engine output.
let viewReasoning = (model: model): Tea_Vdom.t<msg> => {
  let st = model.stapeln
  div(
    list{Attrs.class_("p-4 space-y-4")},
    list{
      // Header
      h3(
        list{Attrs.class_("text-lg font-semibold text-white mb-2")},
        list{text("Assembly Reasoning")},
      ),
      // Connection status
      div(
        list{Attrs.class_("flex items-center gap-2 mb-3")},
        list{
          div(
            list{
              Attrs.class_(
                if st.connected {
                  "w-2 h-2 rounded-full bg-emerald-400"
                } else {
                  "w-2 h-2 rounded-full bg-gray-600"
                },
              ),
            },
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{
              text(
                if st.connected {
                  "Pipeline connected"
                } else {
                  "Disconnected"
                },
              ),
            },
          ),
          span(
            list{Attrs.class_("text-xs text-gray-600 ml-auto font-mono")},
            list{text(st.pipelineUrl)},
          ),
        },
      ),
      // Pipeline stats (if available)
      switch st.pipelineStatus {
      | Some(status) =>
        div(
          list{Attrs.class_("space-y-4")},
          list{
            // Stats row
            div(
              list{Attrs.class_("grid grid-cols-3 gap-3")},
              list{
                statCard("Nodes", Int.toString(status.nodeCount), "text-cyan-400"),
                statCard("Connections", Int.toString(status.connectionCount), "text-purple-400"),
                statCard(
                  "Health",
                  StapelnEngine.healthLabel(status.health),
                  StapelnEngine.healthColour(status.health),
                ),
              },
            ),
            // Security posture
            div(
              list{Attrs.class_("p-3 bg-gray-800 rounded")},
              list{
                div(
                  list{Attrs.class_("flex items-center justify-between mb-2")},
                  list{
                    span(
                      list{Attrs.class_("text-xs font-medium text-gray-400 uppercase")},
                      list{text("Security Posture")},
                    ),
                    span(
                      list{
                        Attrs.class_(
                          if status.securityPosture.score >= 0.8 {
                            "text-sm font-medium text-emerald-400"
                          } else if status.securityPosture.score >= 0.5 {
                            "text-sm font-medium text-amber-400"
                          } else {
                            "text-sm font-medium text-red-400"
                          },
                        ),
                      },
                      list{text(StapelnEngine.posturePercentage(status.securityPosture))},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("grid grid-cols-2 gap-2")},
                  list{
                    boolBadge("SLSA Compliant", status.securityPosture.slsaCompliant),
                    boolBadge("SBOM Present", status.securityPosture.sbomPresent),
                    boolBadge("Signature Valid", status.securityPosture.signatureValid),
                    constraintRow(
                      "Vulnerabilities",
                      Int.toString(status.securityPosture.vulnerabilities) ++
                      " (" ++
                      Int.toString(status.securityPosture.criticalVulns) ++ " critical)",
                    ),
                  },
                ),
              },
            ),
            // Validation status
            div(
              list{Attrs.class_("flex items-center gap-2")},
              list{
                span(
                  list{
                    Attrs.class_(
                      if status.validationPassing {
                        "text-xs font-medium text-emerald-400"
                      } else {
                        "text-xs font-medium text-red-400"
                      },
                    ),
                  },
                  list{
                    text(
                      if status.validationPassing {
                        "Validation Passing"
                      } else {
                        "Validation Failing"
                      },
                    ),
                  },
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer ml-auto",
                    ),
                    Events.onClick(Stapeln(RefreshStatus)),
                    KeyboardNav.onActivate(Stapeln(RefreshStatus)),
                  },
                  list{text("Refresh")},
                ),
              },
            ),
            // Optimisation suggestions
            if Array.length(status.suggestions) > 0 {
              div(
                list{Attrs.class_("space-y-2")},
                list{
                  div(
                    list{
                      Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider"),
                    },
                    list{text(`Suggestions (${Int.toString(Array.length(status.suggestions))})`)},
                  ),
                  div(
                    list{Attrs.class_("space-y-2")},
                    status.suggestions->Array.map(suggestionRow)->List.fromArray,
                  ),
                },
              )
            } else {
              div(
                list{Attrs.class_("text-xs text-gray-500 italic")},
                list{text("No optimisation suggestions")},
              )
            },
          },
        )
      | None =>
        div(
          list{Attrs.class_("p-6 text-center")},
          list{
            div(
              list{Attrs.class_("text-gray-500 text-sm mb-3")},
              list{text("No pipeline data available")},
            ),
            button(
              list{
                Attrs.class_(
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                ),
                Events.onClick(Stapeln(RefreshStatus)),
                KeyboardNav.onActivate(Stapeln(RefreshStatus)),
              },
              list{text("Refresh Status")},
            ),
          },
        )
      },
    },
  )
}

// ============================================================================
// Panel-W: Results & Artifacts
// ============================================================================

/// Render an artifact format tab button.
let formatTab = (fmt: artifactFormat, active: artifactFormat): Tea_Vdom.t<msg> => {
  let isActive = fmt === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{
      Attrs.class_(cls),
      Events.onClick(Stapeln(RequestGenerate(StapelnEngine.artifactFormatLabel(fmt)))),
    },
    list{text(StapelnEngine.artifactFormatLabel(fmt))},
  )
}

/// Render a single validation finding row.
let findingRow = (f: validationFinding): Tea_Vdom.t<msg> => {
  let levelCls = StapelnEngine.findingLevelColour(f.level)
  div(
    list{Attrs.class_("flex items-start gap-2 py-1.5 border-b border-gray-800")},
    list{
      span(
        list{Attrs.class_(`text-xs font-medium ${levelCls} uppercase w-14 shrink-0`)},
        list{text(f.level)},
      ),
      span(list{Attrs.class_("text-xs text-gray-500 font-mono w-16 shrink-0")}, list{text(f.rule)}),
      div(
        list{Attrs.class_("flex-1")},
        list{
          span(list{Attrs.class_("text-xs text-gray-300")}, list{text(f.message)}),
          switch f.line {
          | Some(ln) =>
            span(
              list{Attrs.class_("text-xs text-gray-600 ml-2")},
              list{text("L" ++ Int.toString(ln))},
            )
          | None => text("")
          },
        },
      ),
      if f.autoFixAvailable {
        span(list{Attrs.class_("text-xs text-emerald-500 shrink-0")}, list{text("fix")})
      } else {
        text("")
      },
    },
  )
}

/// Panel-W: Generated artifacts, security scan results, and deploy readiness.
let viewResults = (model: model): Tea_Vdom.t<msg> => {
  let st = model.stapeln
  div(
    list{Attrs.class_("p-4 space-y-4")},
    list{
      // Header
      h3(
        list{Attrs.class_("text-lg font-semibold text-white mb-2")},
        list{text("Results & Artifacts")},
      ),
      // Format tabs
      div(
        list{Attrs.class_("flex items-center gap-2 mb-3")},
        StapelnEngine.allFormats
        ->Array.map(fmt => formatTab(fmt, st.selectedFormat))
        ->List.fromArray,
      ),
      // Generated artifact preview
      div(
        list{Attrs.class_("space-y-2")},
        list{
          div(
            list{Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider")},
            list{text("Generated " ++ StapelnEngine.artifactFormatLabel(st.selectedFormat))},
          ),
          switch st.generatedArtifact {
          | Some(content) =>
            pre(
              list{
                Attrs.class_(
                  "p-3 bg-gray-900 rounded text-xs text-gray-300 font-mono overflow-auto max-h-64 border border-gray-800",
                ),
              },
              list{text(content)},
            )
          | None =>
            div(
              list{Attrs.class_("p-4 bg-gray-900 rounded text-center")},
              list{
                div(
                  list{Attrs.class_("text-gray-500 text-sm mb-2")},
                  list{text("No artifact generated yet")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-3 py-1.5 text-xs bg-cyan-700 text-white rounded hover:bg-cyan-600 cursor-pointer",
                    ),
                    Events.onClick(
                      Stapeln(
                        RequestGenerate(StapelnEngine.artifactFormatLabel(st.selectedFormat)),
                      ),
                    ),
                  },
                  list{text("Generate " ++ StapelnEngine.artifactFormatLabel(st.selectedFormat))},
                ),
              },
            )
          },
        },
      ),
      // Validation results
      switch st.lastValidation {
      | Some(validation) =>
        div(
          list{Attrs.class_("space-y-2")},
          list{
            // Summary bar
            div(
              list{Attrs.class_("flex items-center gap-3")},
              list{
                div(
                  list{Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider")},
                  list{text("Security Scan")},
                ),
                span(
                  list{
                    Attrs.class_(
                      if validation.passed {
                        "px-2 py-0.5 text-xs rounded bg-emerald-900 text-emerald-300"
                      } else {
                        "px-2 py-0.5 text-xs rounded bg-red-900 text-red-300"
                      },
                    ),
                  },
                  list{
                    text(
                      if validation.passed {
                        "PASSED"
                      } else {
                        "FAILED"
                      },
                    ),
                  },
                ),
                span(
                  list{Attrs.class_("text-xs text-gray-500 ml-auto")},
                  list{
                    text(
                      Int.toString(validation.errorCount) ++
                      " errors, " ++
                      Int.toString(validation.warningCount) ++
                      " warnings, " ++
                      Int.toString(validation.infoCount) ++ " info",
                    ),
                  },
                ),
              },
            ),
            // Finding rows
            if Array.length(validation.findings) > 0 {
              div(
                list{Attrs.class_("space-y-0")},
                validation.findings->Array.map(findingRow)->List.fromArray,
              )
            } else {
              div(
                list{Attrs.class_("text-xs text-emerald-500 italic")},
                list{text("No findings — clean scan")},
              )
            },
          },
        )
      | None =>
        div(
          list{Attrs.class_("space-y-2")},
          list{
            div(
              list{Attrs.class_("flex items-center gap-3")},
              list{
                div(
                  list{Attrs.class_("text-xs font-medium text-gray-400 uppercase tracking-wider")},
                  list{text("Security Scan")},
                ),
                span(
                  list{Attrs.class_("text-xs text-gray-500 italic")},
                  list{text("Not yet scanned")},
                ),
              },
            ),
            button(
              list{
                Attrs.class_(
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                ),
                Events.onClick(Stapeln(RequestValidation)),
                KeyboardNav.onActivate(Stapeln(RequestValidation)),
              },
              list{text("Run Validation")},
            ),
          },
        )
      },
      // Deploy readiness indicator
      div(
        list{Attrs.class_("pt-3 border-t border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between")},
            list{
              span(
                list{Attrs.class_("text-xs font-medium text-gray-400 uppercase")},
                list{text("Deploy Readiness")},
              ),
              {
                let ready =
                  st.connected &&
                  st.generatedArtifact->Option.isSome &&
                  st.lastValidation->Option.mapOr(false, v => v.passed)
                span(
                  list{
                    Attrs.class_(
                      if ready {
                        "px-3 py-1 text-xs font-medium bg-emerald-700 text-white rounded"
                      } else {
                        "px-3 py-1 text-xs font-medium bg-gray-800 text-gray-500 rounded"
                      },
                    ),
                  },
                  list{
                    text(
                      if ready {
                        "READY"
                      } else {
                        "NOT READY"
                      },
                    ),
                  },
                )
              },
            },
          ),
        },
      ),
      // Error display
      switch st.error {
      | Some(err) =>
        div(
          list{Attrs.class_("p-3 bg-red-950 border border-red-800 rounded")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                span(list{Attrs.class_("text-xs text-red-400")}, list{text(err)}),
                button(
                  list{
                    Attrs.class_("text-xs text-red-500 hover:text-red-400 cursor-pointer"),
                    Events.onClick(Stapeln(DismissError)),
                    KeyboardNav.onActivate(Stapeln(DismissError)),
                  },
                  list{text("dismiss")},
                ),
              },
            ),
          },
        )
      | None => text("")
      },
    },
  )
}

// ============================================================================
// Unified Panel View
// ============================================================================

/// Main entry point — renders the Stapeln panel content based on the active
/// tab. Called from the panel switcher or layout engine.
let view = (model: model): Tea_Vdom.t<msg> => {
  let st = model.stapeln
  div(
    list{Attrs.class_("h-full flex flex-col bg-gray-950")},
    list{
      // Tab bar
      div(
        list{
          Attrs.class_("flex items-center gap-2 px-4 py-2 border-b border-gray-800 bg-gray-900"),
        },
        list{
          button(
            list{
              Attrs.class_(
                if st.activeTab === "constraints" {
                  "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
                },
              ),
              Events.onClick(Stapeln(SetActiveTab("constraints"))),
            },
            list{text("Constraints")},
          ),
          button(
            list{
              Attrs.class_(
                if st.activeTab === "reasoning" {
                  "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
                },
              ),
              Events.onClick(Stapeln(SetActiveTab("reasoning"))),
            },
            list{text("Reasoning")},
          ),
          button(
            list{
              Attrs.class_(
                if st.activeTab === "results" {
                  "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
                },
              ),
              Events.onClick(Stapeln(SetActiveTab("results"))),
            },
            list{text("Results")},
          ),
          // Loading indicator
          if st.loading {
            span(
              list{Attrs.class_("text-xs text-gray-500 ml-auto animate-pulse")},
              list{text("Loading...")},
            )
          } else {
            text("")
          },
        },
      ),
      // Panel content
      div(
        list{Attrs.class_("flex-1 overflow-auto")},
        list{
          switch st.activeTab {
          | "constraints" => viewConstraints(model)
          | "reasoning" => viewReasoning(model)
          | "results" => viewResults(model)
          | _ => viewConstraints(model)
          },
        },
      ),
    },
  )
}
