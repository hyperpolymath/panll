// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// IdentityCmd — TEA command wrappers for identity snapshot operations.

let invoke = RuntimeBridge.invoke

/// Capture a new identity snapshot with the given name and state payloads.
let captureSnapshot = (
  name: string,
  panllState: string,
  settingsJson: string,
  serviceUrls: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "identity_save",
      {
        "name": name,
        "panll_state": panllState,
        "settings": settingsJson,
        "service_urls": serviceUrls,
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Identity capture failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load a full identity snapshot by ID.
let loadSnapshot = (id: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("identity_load", {"id": id})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Identity load failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all available identity snapshots (metadata only).
let listSnapshots = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("identity_list", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Identity list failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete an identity snapshot by ID.
let deleteSnapshot = (id: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("identity_delete", {"id": id})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Identity delete failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Broadcast an identity snapshot to team members via Burble.
let broadcastSnapshot = (snapshotJson: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("team_broadcast_state", {"snapshot": snapshotJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Team broadcast failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
