// SPDX-License-Identifier: MPL-2.0

/// PanLL Capture Bar — reusable vertical capture strip for panels (DD-022).
///
/// Per the user's design: icons are SIDE-ORIENTED (vertical strip on the panel
/// edge) so people don't instinctively click them thinking they're selfie buttons.
/// The strip appears on the right edge of each panel/pane.
///
/// Icons:
/// - Camera: screenshot this panel
/// - Record: start/stop recording this panel
/// - Clone: duplicate this panel's state
/// - Compare: enter comparison mode with this panel

open Msg
open Tea.Html

/// A single capture bar button.
let captureButton = (
  label: string,
  icon: string,
  tooltip: string,
  onClick: msg,
  active: bool,
): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        `w-6 h-6 flex items-center justify-center rounded text-xs ${active
            ? "bg-red-700 text-white"
            : "bg-gray-800/80 text-gray-500 hover:text-gray-300 hover:bg-gray-700"} transition-colors`,
      ),
      Events.onClick(onClick),
      Attrs.title(tooltip),
      Attrs.ariaLabel(label),
    },
    list{text(icon)},
  )
}

/// Render the capture bar for a panel. `panelId` identifies which panel
/// this bar is attached to. `isRecording` indicates if this panel is
/// currently being recorded.
let view = (panelId: string, isRecording: bool, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{
        Attrs.class_(
          "absolute right-0 top-1/2 -translate-y-1/2 flex flex-col gap-1 p-1 bg-gray-950/70 rounded-l z-30",
        ),
        Attrs.role("toolbar"),
        Attrs.ariaLabel("Capture controls for " ++ panelId),
      },
      list{
        captureButton(
          "Screenshot " ++ panelId,
          "C", // Camera icon placeholder (would be SVG in production)
          "Screenshot this panel",
          Capture(CaptureScreenshot(panelId)),
          false,
        ),
        captureButton(
          (isRecording ? "Stop recording " : "Record ") ++ panelId,
          "R", // Record icon placeholder
          isRecording ? "Stop recording this panel" : "Start recording this panel",
          isRecording ? Capture(StopRecording) : Capture(StartRecording(panelId)),
          isRecording,
        ),
        captureButton(
          "Clone " ++ panelId,
          "D", // Duplicate/clone icon placeholder
          "Clone this panel's state into an independent copy",
          Capture(ClonePanel(panelId)),
          false,
        ),
        captureButton(
          "Compare " ++ panelId,
          "=", // Compare icon placeholder
          "Enter comparison mode with this panel",
          Capture(ToggleCaptureSelection(panelId)),
          false,
        ),
      },
    )
  }
}
