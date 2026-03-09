// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Debug.res — Time-travel debugger for the TEA architecture.
//
// Wraps a standard TEA program to record every (msg, model) pair.
// Access via console: window.__tea_debug.history(), .back(), .forward(),
// .goto(n), .model(), .export()

/// History entry
type historyEntry<'model, 'msg> = {
  index: int,
  msg: 'msg,
  msgString: string,
  model: 'model,
  timestamp: float,
}

/// Debug state
type debugState<'model, 'msg> = {
  mutable history: array<historyEntry<'model, 'msg>>,
  mutable currentIndex: int,
  mutable isTimeTravelling: bool,
  msgToString: 'msg => string,
}

/// Create a debug-wrapped TEA program with time-travel support.
let program = (
  ~init: unit => ('model, Tea_Cmd.t<'msg>),
  ~update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  ~view: 'model => Tea_Vdom.t<'msg>,
  ~subscriptions: 'model => Tea_Sub.t<'msg>,
  ~msgToString: 'msg => string,
  (),
): Tea_App.programInterface<'msg, 'model> => {
  let debugState: debugState<'model, 'msg> = {
    history: [],
    currentIndex: -1,
    isTimeTravelling: false,
    msgToString,
  }

  let debugInit = () => {
    let (model, cmd) = init()
    debugState.currentIndex = 0
    (model, cmd)
  }

  let debugUpdate = (model: 'model, msg: 'msg): ('model, Tea_Cmd.t<'msg>) => {
    if debugState.isTimeTravelling {
      (model, Tea_Cmd.none)
    } else {
      let (newModel, cmd) = update(model, msg)

      if debugState.currentIndex < Array.length(debugState.history) - 1 {
        debugState.history = Array.slice(debugState.history, ~start=0, ~end=debugState.currentIndex + 1)
      }

      let entry: historyEntry<'model, 'msg> = {
        index: Array.length(debugState.history),
        msg,
        msgString: msgToString(msg),
        model: newModel,
        timestamp: Date.now(),
      }
      Array.push(debugState.history, entry)->ignore
      debugState.currentIndex = Array.length(debugState.history) - 1

      (newModel, cmd)
    }
  }

  let _program = Tea_App.standardProgram(
    ~init=debugInit,
    ~update=debugUpdate,
    ~view,
    ~subscriptions,
    (),
  )

  let _debugState = debugState
  let _: unit = %raw(`
    globalThis.__tea_debug = {
      history: function() {
        var h = _debugState.history;
        console.group("TEA Debug History (" + h.length + " entries)");
        for (var i = 0; i < h.length; i++) {
          var marker = i === _debugState.currentIndex ? " <-- current" : "";
          console.log("#" + i + ": " + h[i].msgString + marker);
        }
        console.groupEnd();
        return h.length;
      },
      back: function() {
        if (_debugState.currentIndex > 0) {
          _debugState.isTimeTravelling = true;
          _debugState.currentIndex--;
          console.log("Back to #" + _debugState.currentIndex);
          _debugState.isTimeTravelling = false;
        }
      },
      forward: function() {
        if (_debugState.currentIndex < _debugState.history.length - 1) {
          _debugState.isTimeTravelling = true;
          _debugState.currentIndex++;
          console.log("Forward to #" + _debugState.currentIndex);
          _debugState.isTimeTravelling = false;
        }
      },
      goto: function(index) {
        if (index >= 0 && index < _debugState.history.length) {
          _debugState.isTimeTravelling = true;
          _debugState.currentIndex = index;
          console.log("Jumped to #" + index);
          _debugState.isTimeTravelling = false;
        }
      },
      model: function() {
        if (_debugState.currentIndex >= 0 && _debugState.currentIndex < _debugState.history.length) {
          return _debugState.history[_debugState.currentIndex].model;
        }
        return _program.getModel();
      },
      export: function() {
        return JSON.stringify(_debugState.history.map(function(e) {
          return { index: e.index, msg: e.msgString, timestamp: e.timestamp };
        }), null, 2);
      }
    }
  `)

  Console.log("TEA Debug enabled. Access via window.__tea_debug")

  _program
}
