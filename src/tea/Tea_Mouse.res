// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Mouse.res — Mouse event subscriptions for the TEA architecture.

/// Mouse position
type position = {
  clientX: float,
  clientY: float,
  pageX: float,
  pageY: float,
}

/// Subscribe to mouse clicks anywhere on the document
let clicks = (tagger: position => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("mouse-clicks", dispatch => {
    let _handler = (_e: Dom.event) => {
      let pos: position = %raw(`({
        clientX: _e.clientX || 0,
        clientY: _e.clientY || 0,
        pageX: _e.pageX || 0,
        pageY: _e.pageY || 0
      })`)
      dispatch(tagger(pos))
    }
    let _: unit = %raw(`document.addEventListener("click", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("click", _handler)`)
    }
  })
}

/// Subscribe to mouse movement anywhere on the document
let moves = (tagger: position => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("mouse-moves", dispatch => {
    let _handler = (_e: Dom.event) => {
      let pos: position = %raw(`({
        clientX: _e.clientX || 0,
        clientY: _e.clientY || 0,
        pageX: _e.pageX || 0,
        pageY: _e.pageY || 0
      })`)
      dispatch(tagger(pos))
    }
    let _: unit = %raw(`document.addEventListener("mousemove", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("mousemove", _handler)`)
    }
  })
}

/// Subscribe to mouse button down
let downs = (tagger: position => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("mouse-downs", dispatch => {
    let _handler = (_e: Dom.event) => {
      let pos: position = %raw(`({
        clientX: _e.clientX || 0,
        clientY: _e.clientY || 0,
        pageX: _e.pageX || 0,
        pageY: _e.pageY || 0
      })`)
      dispatch(tagger(pos))
    }
    let _: unit = %raw(`document.addEventListener("mousedown", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("mousedown", _handler)`)
    }
  })
}

/// Subscribe to mouse button up
let ups = (tagger: position => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("mouse-ups", dispatch => {
    let _handler = (_e: Dom.event) => {
      let pos: position = %raw(`({
        clientX: _e.clientX || 0,
        clientY: _e.clientY || 0,
        pageX: _e.pageX || 0,
        pageY: _e.pageY || 0
      })`)
      dispatch(tagger(pos))
    }
    let _: unit = %raw(`document.addEventListener("mouseup", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("mouseup", _handler)`)
    }
  })
}
