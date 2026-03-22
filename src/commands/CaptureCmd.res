// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Capture Commands — IPC wrappers for screenshot, recording,
/// and demo operations (DD-022).
///
/// These functions bridge the ReScript TEA loop with the Rust backend
/// for capture persistence and demo package management. Each function
/// returns a Tea_Cmd that dispatches a result message back into the
/// update loop via `callbacks.enqueue`.

open Msg

/// Backend invoke binding via RuntimeBridge.
let invoke = RuntimeBridge.invoke

/// Save a screenshot to disk. The base64 data is captured in the frontend
/// via html2canvas and sent to Rust for file I/O.
let saveScreenshot = (
  captureId: string,
  panelId: string,
  base64Data: string,
  format: string,
): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("save_screenshot", {
      "captureId": captureId,
      "panelId": panelId,
      "base64Data": base64Data,
      "format": format,
    })
    ->Promise.then(result => {
      callbacks.enqueue(Capture(ScreenshotSaved(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Capture(ScreenshotSaved(Error("Failed to save screenshot"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Invoke the system print dialog for a panel.
let printPanel = (panelId: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("print_panel", {"panelId": panelId})
    ->Promise.then(result => {
      callbacks.enqueue(Capture(PrintResult(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Capture(PrintResult(Error("Failed to print panel"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Save a demo package to disk.
let saveDemo = (demoJson: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("save_demo", {"demoJson": demoJson})
    ->Promise.then(result => {
      callbacks.enqueue(Capture(DemoSaved(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Capture(DemoSaved(Error("Failed to save demo"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load all demo packages from disk.
let loadDemos = (): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("load_demos", ())
    ->Promise.then(result => {
      callbacks.enqueue(Capture(DemosLoaded(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Capture(DemosLoaded(Error("Failed to load demos"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete a demo package from disk.
let deleteDemo = (demoId: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(_callbacks => {
    invoke("delete_demo", {"demoId": demoId})->ignore
  })
}
