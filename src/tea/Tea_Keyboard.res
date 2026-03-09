// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Keyboard.res — Keyboard event subscriptions for the TEA architecture.

/// Key event information
type keyEvent = {
  key: string,
  code: string,
  altKey: bool,
  ctrlKey: bool,
  metaKey: bool,
  shiftKey: bool,
  repeat: bool,
}

/// Subscribe to keydown events on the document
let downs = (tagger: keyEvent => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("keyboard-downs", dispatch => {
    let _handler = (_e: Dom.event) => {
      let ke: keyEvent = %raw(`({
        key: _e.key || "",
        code: _e.code || "",
        altKey: !!_e.altKey,
        ctrlKey: !!_e.ctrlKey,
        metaKey: !!_e.metaKey,
        shiftKey: !!_e.shiftKey,
        repeat: !!_e.repeat
      })`)
      dispatch(tagger(ke))
    }
    let _: unit = %raw(`document.addEventListener("keydown", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("keydown", _handler)`)
    }
  })
}

/// Subscribe to keyup events on the document
let ups = (tagger: keyEvent => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("keyboard-ups", dispatch => {
    let _handler = (_e: Dom.event) => {
      let ke: keyEvent = %raw(`({
        key: _e.key || "",
        code: _e.code || "",
        altKey: !!_e.altKey,
        ctrlKey: !!_e.ctrlKey,
        metaKey: !!_e.metaKey,
        shiftKey: !!_e.shiftKey,
        repeat: !!_e.repeat
      })`)
      dispatch(tagger(ke))
    }
    let _: unit = %raw(`document.addEventListener("keyup", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("keyup", _handler)`)
    }
  })
}

/// Subscribe to a specific key being pressed (e.g. "Escape", "Enter")
let onKey = (targetKey: string, msg: 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("keyboard-key-" ++ targetKey, dispatch => {
    let _targetKey = targetKey
    let _handler = (_e: Dom.event) => {
      let key: string = %raw(`_e.key || ""`)
      if key === _targetKey {
        dispatch(msg)
      }
    }
    let _: unit = %raw(`document.addEventListener("keydown", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("keydown", _handler)`)
    }
  })
}

/// Subscribe to a keyboard shortcut (ctrl/cmd + key)
let onShortcut = (
  ~ctrl: bool=false,
  ~alt: bool=false,
  ~shift: bool=false,
  ~meta: bool=false,
  key: string,
  msg: 'msg,
): Tea_Sub.t<'msg> => {
  let id = `keyboard-shortcut-${ctrl ? "c" : ""}${alt ? "a" : ""}${shift ? "s" : ""}${meta ? "m" : ""}-${key}`
  Tea_Sub.registration(id, dispatch => {
    let _ctrl = ctrl
    let _alt = alt
    let _shift = shift
    let _meta = meta
    let _key = key
    let _handler = (_e: Dom.event) => {
      let matches: bool = %raw(`
        _e.key === _key &&
        !!_e.ctrlKey === _ctrl &&
        !!_e.altKey === _alt &&
        !!_e.shiftKey === _shift &&
        !!_e.metaKey === _meta
      `)
      if matches {
        let _: unit = %raw(`_e.preventDefault()`)
        dispatch(msg)
      }
    }
    let _: unit = %raw(`document.addEventListener("keydown", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("keydown", _handler)`)
    }
  })
}
