// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL DLC Workshop Commands — Tauri invoke wrappers for DLC puzzle
/// pack creation, testing, and packaging operations.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Load puzzles from the DLC directory.
let loadPuzzles = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_load_puzzles", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load puzzles")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Save a puzzle to disk.
let savePuzzle = (
  data: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_save_puzzle", {"data": data})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save puzzle")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run the solution test suite for a puzzle.
let runTest = (
  puzzleId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_run_test", {"puzzleId": puzzleId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Test run failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run all tests in the DLC pack.
let runAllTests = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_run_all_tests", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Test suite failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Browse DLC assets.
let browseAssets = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_browse_assets", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to browse assets")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Package the DLC pack for distribution.
let packageDlc = (
  data: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_package", {"data": data})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to package DLC")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Import a puzzle from a file.
let importPuzzle = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_import_puzzle", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to import puzzle")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export a puzzle to a file.
let exportPuzzle = (
  puzzleId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("dlc_export_puzzle", {"puzzleId": puzzleId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export puzzle")))
      Promise.resolve()
    })
    ->ignore
  })
}
