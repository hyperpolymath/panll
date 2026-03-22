// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Feedback Commands — Backend command wrapper for saving Feedback-O-Tron reports.
///
/// Persists feedback reports to `~/.panll/feedback/<timestamp>.json` via the
/// Rust backend. The report includes the feedback text, report type, and
/// optional BoJ context snapshot.

let invoke = RuntimeBridge.invoke

/// Save a feedback report to disk via the Rust backend.
let saveReport = (
  reportJson: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("feedback_save_report", {"reportJson": reportJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save feedback report")))
      Promise.resolve()
    })
    ->ignore
  })
}
