// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Window.res — Window/document event subscriptions for the TEA architecture.

/// Window dimensions
type size = {width: int, height: int}

/// Subscribe to window resize events
let onResize = (tagger: size => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-resize", dispatch => {
    let _handler = (_: Dom.event) => {
      let w: int = %raw(`window.innerWidth`)
      let h: int = %raw(`window.innerHeight`)
      dispatch(tagger({width: w, height: h}))
    }
    let _: unit = %raw(`window.addEventListener("resize", _handler)`)
    () => {
      let _: unit = %raw(`window.removeEventListener("resize", _handler)`)
    }
  })
}

/// Subscribe to document visibility changes (tab focus/blur)
let onVisibilityChange = (tagger: bool => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-visibility", dispatch => {
    let _handler = (_: Dom.event) => {
      let hidden: bool = %raw(`document.hidden`)
      dispatch(tagger(!hidden))
    }
    let _: unit = %raw(`document.addEventListener("visibilitychange", _handler)`)
    () => {
      let _: unit = %raw(`document.removeEventListener("visibilitychange", _handler)`)
    }
  })
}

/// Subscribe to window focus (tab becomes active)
let onFocus = (msg: 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-focus", dispatch => {
    let _handler = (_: Dom.event) => dispatch(msg)
    let _: unit = %raw(`window.addEventListener("focus", _handler)`)
    () => {
      let _: unit = %raw(`window.removeEventListener("focus", _handler)`)
    }
  })
}

/// Subscribe to window blur (tab becomes inactive)
let onBlur = (msg: 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-blur", dispatch => {
    let _handler = (_: Dom.event) => dispatch(msg)
    let _: unit = %raw(`window.addEventListener("blur", _handler)`)
    () => {
      let _: unit = %raw(`window.removeEventListener("blur", _handler)`)
    }
  })
}

/// Subscribe to scroll events on the window
let onScroll = (tagger: float => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-scroll", dispatch => {
    let _handler = (_: Dom.event) => {
      let scrollY: float = %raw(`window.scrollY || window.pageYOffset || 0`)
      dispatch(tagger(scrollY))
    }
    let _: unit = %raw(`window.addEventListener("scroll", _handler, { passive: true })`)
    () => {
      let _: unit = %raw(`window.removeEventListener("scroll", _handler)`)
    }
  })
}

/// Subscribe to the online/offline status
let onOnline = (tagger: bool => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-online", dispatch => {
    let _onlineHandler = (_: Dom.event) => dispatch(tagger(true))
    let _offlineHandler = (_: Dom.event) => dispatch(tagger(false))
    let _: unit = %raw(`window.addEventListener("online", _onlineHandler)`)
    let _: unit = %raw(`window.addEventListener("offline", _offlineHandler)`)
    () => {
      let _: unit = %raw(`window.removeEventListener("online", _onlineHandler)`)
      let _: unit = %raw(`window.removeEventListener("offline", _offlineHandler)`)
    }
  })
}

/// Subscribe to browser hash changes (for simple routing)
let onHashChange = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-hashchange", dispatch => {
    let _handler = (_: Dom.event) => {
      let hash: string = %raw(`window.location.hash || ""`)
      dispatch(tagger(hash))
    }
    let _: unit = %raw(`window.addEventListener("hashchange", _handler)`)
    () => {
      let _: unit = %raw(`window.removeEventListener("hashchange", _handler)`)
    }
  })
}

/// Subscribe to popstate events (browser back/forward navigation)
let onPopState = (msg: 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("window-popstate", dispatch => {
    let _handler = (_: Dom.event) => dispatch(msg)
    let _: unit = %raw(`window.addEventListener("popstate", _handler)`)
    () => {
      let _: unit = %raw(`window.removeEventListener("popstate", _handler)`)
    }
  })
}

/// Get current window size (command, not subscription)
let getSize = (tagger: size => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let w: int = %raw(`window.innerWidth`)
    let h: int = %raw(`window.innerHeight`)
    callbacks.enqueue(tagger({width: w, height: h}))
  })
}
