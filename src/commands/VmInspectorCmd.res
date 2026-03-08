// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL VM Inspector Commands — Tauri async bindings for the reversible
/// VM debugger. Handles VM state reading, step execution, breakpoint
/// management, and state export.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Read the current VM state from the running game (inter-webview).
let readVmState = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vm_inspector_read_state", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read VM state")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Step the VM forward by one instruction.
let stepForward = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vm_inspector_step_forward", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to step VM forward")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Step the VM backward by one instruction (reverse execution).
let stepBackward = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vm_inspector_step_backward", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to step VM backward")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run the VM until the next breakpoint or program end.
let runToBreakpoint = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vm_inspector_run", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to run VM")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load a VM program from assembly text.
let loadProgram = (
  assembly: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vm_inspector_load_program", {"assembly": assembly})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load VM program")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export the current VM state as a JSON snapshot.
let exportSnapshot = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vm_inspector_export_snapshot", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export VM snapshot")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read VM state from a serialised JSON file (file-based connection mode).
let readVmStateFromFile = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vm_inspector_read_file", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read VM state file")))
      Promise.resolve()
    })
    ->ignore
  })
}
