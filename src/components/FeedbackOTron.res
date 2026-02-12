// SPDX-License-Identifier: PMPL-1.0-or-later

/// Feedback-O-Tron Component
///
/// The "Voice of the Arena" module for collective governance.
/// Captures context-aware reports on Agent performance and
/// enables crowdsourced constraint suggestions.

open Msg
open Tea.Html

/// Report types for Orbital Decay
type reportType =
  | Hallucination
  | ConstraintViolation
  | PerformanceIssue
  | UXFriction
  | FeatureRequest

/// Get report type label
let getReportLabel = (rt: reportType): string => {
  switch rt {
  | Hallucination => "Hallucination"
  | ConstraintViolation => "Constraint Violation"
  | PerformanceIssue => "Performance Issue"
  | UXFriction => "UX Friction"
  | FeatureRequest => "Feature Request"
  }
}

/// Map report type to string value
let reportTypeToString = (rt: reportType): string => {
  switch rt {
  | Hallucination => "Hallucination"
  | ConstraintViolation => "ConstraintViolation"
  | PerformanceIssue => "PerformanceIssue"
  | UXFriction => "UXFriction"
  | FeatureRequest => "FeatureRequest"
  }
}

/// Get report type colour
let getReportColour = (rt: reportType): string => {
  switch rt {
  | Hallucination => "bg-red-600"
  | ConstraintViolation => "bg-amber-600"
  | PerformanceIssue => "bg-orange-600"
  | UXFriction => "bg-yellow-600"
  | FeatureRequest => "bg-blue-600"
  }
}

/// Render a report type button
let renderReportTypeButton = (
  rt: reportType,
  selectedType: option<string>,
): Tea_Vdom.t<msg> => {
  let baseClass = "px-3 py-1 rounded text-xs transition-all"
  let colour = getReportColour(rt)
  let isSelected = selectedType === Some(reportTypeToString(rt))
  let selectedClass = isSelected
    ? `${colour} text-white`
    : "bg-gray-800 text-gray-400 hover:bg-gray-700"

  button(
    list{
      Attrs.class_(`${baseClass} ${selectedClass}`),
      Events.onClick(Feedback(SetReportType(reportTypeToString(rt)))),
    },
    list{text(getReportLabel(rt))},
  )
}

/// Render the feedback form
let renderFeedbackForm = (
  pendingReport: option<string>,
  feedbackError: option<string>,
  selectedType: option<string>,
): Tea_Vdom.t<msg> => {
  let reportTypes = [Hallucination, ConstraintViolation, PerformanceIssue, UXFriction, FeatureRequest]
  let errorView = switch feedbackError {
  | Some(err) =>
    div(
      list{Attrs.class_("mt-2 text-xs text-red-400")},
      list{text(err)},
    )
  | None => noNode
  }

  div(
    list{Attrs.class_("fixed inset-0 bg-black/80 flex items-center justify-center z-50")},
    list{
      div(
        list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg w-[500px] max-h-[80vh] overflow-auto"), Attrs.role("dialog"), Attrs.ariaLabel("Feedback Form")},
        list{
          // Header
          div(
            list{Attrs.class_("p-4 border-b border-gray-700")},
            list{
              div(
                list{Attrs.class_("flex items-center justify-between")},
                list{
                  div(
                    list{Attrs.class_("text-lg font-semibold text-gray-200")},
                    list{text("Feedback-O-Tron")},
                  ),
                  button(
                    list{
                      Attrs.class_("text-gray-500 hover:text-gray-300"),
                      Events.onClick(Feedback(CancelFeedback)),
                    },
                    list{text("×")},
                  ),
                },
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-1")},
                list{text("Report Orbital Decay to the Community")},
              ),
            },
          ),

          // Report type selection
          div(
            list{Attrs.class_("p-4 border-b border-gray-800")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 mb-2")},
                list{text("REPORT TYPE")},
              ),
              div(
                list{Attrs.class_("flex flex-wrap gap-2"), Attrs.role("radiogroup")},
                reportTypes
                ->Array.map(rt => renderReportTypeButton(rt, selectedType))
                ->List.fromArray,
              ),
            },
          ),

          // Description
          div(
            list{Attrs.class_("p-4 border-b border-gray-800")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 mb-2")},
                list{text("DESCRIPTION")},
              ),
              textarea(
                list{
                  Attrs.class_(
                    "w-full h-24 bg-gray-800 border border-gray-700 rounded p-3 text-sm text-gray-300 resize-none focus:border-gray-500 focus:outline-none",
                  ),
                  Attrs.placeholder("Describe the issue..."),
                  Attrs.value(Option.getOr(pendingReport, "")),
                  Events.onInput(value => Feedback(SubmitFeedback(value))),
                },
                list{},
              ),
              errorView,
            },
          ),

          // Context snapshot info
          div(
            list{Attrs.class_("p-4 border-b border-gray-800")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 mb-2")},
                list{text("CONTEXT SNAPSHOT")},
              ),
              div(
                list{Attrs.class_("grid grid-cols-3 gap-2 text-xs")},
                list{
                  div(
                    list{Attrs.class_("bg-indigo-900/30 p-2 rounded")},
                    list{
                      div(
                        list{Attrs.class_("text-indigo-400")},
                        list{text("Pane-L")},
                      ),
                      div(
                        list{Attrs.class_("text-gray-500")},
                        list{text("Captured")},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("bg-emerald-900/30 p-2 rounded")},
                    list{
                      div(
                        list{Attrs.class_("text-emerald-400")},
                        list{text("Pane-N")},
                      ),
                      div(
                        list{Attrs.class_("text-gray-500")},
                        list{text("Captured")},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("bg-gray-800/50 p-2 rounded")},
                    list{
                      div(
                        list{Attrs.class_("text-gray-400")},
                        list{text("Pane-W")},
                      ),
                      div(
                        list{Attrs.class_("text-gray-500")},
                        list{text("Captured")},
                      ),
                    },
                  ),
                },
              ),
            },
          ),

          // Actions
          div(
            list{Attrs.class_("p-4 flex justify-end gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 bg-gray-800 hover:bg-gray-700 rounded text-sm text-gray-400 transition-colors",
                  ),
                  Events.onClick(Feedback(CancelFeedback)),
                },
                list{text("Cancel")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded text-sm text-white transition-colors",
                  ),
                  Events.onClick(Feedback(FeedbackSubmitted)),
                },
                list{text("Submit Report")},
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render the feedback trigger button
let renderTriggerButton = (): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        "fixed bottom-4 left-4 px-3 py-2 bg-gray-800 hover:bg-gray-700 border border-gray-700 rounded text-xs text-gray-400 transition-colors",
      ),
      Events.onClick(Feedback(OpenFeedback)),
    },
    list{text("Report Issue")},
  )
}

/// Main Feedback-O-Tron view
let view = (
  feedbackPending: option<string>,
  feedbackError: option<string>,
  selectedType: option<string>,
): Tea_Vdom.t<msg> => {
  switch feedbackPending {
  | Some(_) => renderFeedbackForm(feedbackPending, feedbackError, selectedType)
  | None => renderTriggerButton()
  }
}
