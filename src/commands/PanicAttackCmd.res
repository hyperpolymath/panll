// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL panic-attack command wrappers — Tauri invoke bridge for
/// the panic-attack stress testing and weak point analysis panel.
///
/// All commands invoke the panic-attack binary via the Tauri backend,
/// returning JSON results. Uses `Tea_Cmd.call` for async operations.

@val external invoke: (string, 'a) => promise<string> = "__TAURI__.core.invoke"

/// Check panic-attack capability (is the binary available? what mode?).
let checkCapability = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("check_panic_attacker_capability", {})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to probe panic-attack capability")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run a static analysis scan (assail) on a target directory.
/// Returns JSON with weak points, statistics, and recommendations.
let assail = (
  targetPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("panic_attack_assail", {"target_path": targetPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Scan failed — is panic-attack installed?")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run a full assault (static analysis + stress testing) on a target.
/// Returns JSON with combined assail + attack results.
let assault = (
  targetPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("panic_attack_assault", {"target_path": targetPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Assault scan failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// View a saved report by path.
let viewReport = (
  reportPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("panic_attack_view_report", {"report_path": reportPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load report")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Compare two reports (diff).
let diffReports = (
  leftPath: string,
  rightPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("panic_attack_diff", {"left_path": leftPath, "right_path": rightPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to compare reports")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List saved scan reports.
let listReports = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("panic_attack_list_reports", {})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list reports")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export a report as SARIF format for GitHub Security tab.
let exportSarif = (
  reportPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("panic_attack_export_sarif", {"report_path": reportPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export SARIF")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export a report as PanLL event-chain model.
let exportEventChain = (
  reportPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("panic_attack_export_panll", {"report_path": reportPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export event chain")))
      Promise.resolve()
    })
    ->ignore
  })
}
