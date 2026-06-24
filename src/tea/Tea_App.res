// SPDX-License-Identifier: MPL-2.0

/// TEA Application - The core TEA runtime.
///
/// This module provides the main application loop that ties together
/// the Model, Update, View, and Subscriptions.

/// Program configuration
type programConfig<'model, 'msg> = {
  init: unit => ('model, Tea_Cmd.t<'msg>),
  update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  view: 'model => Tea_Vdom.t<'msg>,
  subscriptions: 'model => Tea_Sub.t<'msg>,
}

/// Application state (internal)
type appState<'model, 'msg> = {
  mutable model: 'model,
  mutable currentSub: Tea_Sub.t<'msg>,
  mutable subscriptionCleanup: unit => unit,
  mutable isDispatching: bool, // Prevent recursive dispatch
  mutable messageQueue: array<'msg>,
  mutable renderState: option<Tea_Render.renderState<'msg>>,
  mutable container: option<Tea_Render.domElement>,
}

/// Program interface for external control
type programInterface<'msg, 'model> = {
  shutdown: unit => unit,
  getModel: unit => 'model,
}

/// Create a standard TEA program
let standardProgram = (
  ~init: unit => ('model, Tea_Cmd.t<'msg>),
  ~update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  ~view: 'model => Tea_Vdom.t<'msg>,
  ~subscriptions: 'model => Tea_Sub.t<'msg>,
  (),
): programInterface<'msg, 'model> => {
  let config = {init, update, view, subscriptions}

  // Initialize model and commands
  let (initialModel, initialCmd) = config.init()

  // Create mutable app state
  let state: appState<'model, 'msg> = {
    model: initialModel,
    currentSub: Tea_Sub.none,
    subscriptionCleanup: () => (),
    isDispatching: false,
    messageQueue: [],
    renderState: None,
    container: None,
  }

  // Live diagnostic — writes to the blue bar at the bottom of the page
  let diagWrite: string => unit = %raw(`
    function(text) {
      var d = document.getElementById('panll-diag');
      if (d) d.textContent = text;
    }
  `)

  let diagCount = ref(0)

  // Message dispatch function
  let rec dispatch = (msg: 'msg): unit => {
    // Queue message if already dispatching (prevent recursion)
    if state.isDispatching {
      Array.push(state.messageQueue, msg)
    } else {
      state.isDispatching = true
      diagCount := diagCount.contents + 1

      // Show the message tag in the diagnostic bar for debugging
      let msgTag: string = %raw(`
        (function() {
          var m = msg;
          if (m && m.TAG) return m.TAG;
          if (typeof m === 'string') return m;
          if (typeof m === 'object' && m !== null) return JSON.stringify(Object.keys(m)).slice(0,60);
          return String(m);
        })()
      `)
      diagWrite("#" ++ Int.toString(diagCount.contents) ++ " " ++ msgTag)

      try {
        // Process this message
        processMessage(msg)

        // Process queued messages
        while Array.length(state.messageQueue) > 0 {
          let queuedMsg = Array.shift(state.messageQueue)
          switch queuedMsg {
          | Some(m) => processMessage(m)
          | None => ()
          }
        }
      } catch {
      | exn => {
          Console.error2("[PanLL TEA] dispatch crash — recovering:", exn)
          let errMsg: string = %raw(`(function() {
            var e = exn;
            if (e && e.RE_EXN_ID) return 'ReScript: ' + e.RE_EXN_ID + ' ' + JSON.stringify(e._1 || e._2 || '').slice(0,200);
            if (e && e.message) return e.message;
            if (e && e.stack) return e.stack.split('\\n')[0];
            return JSON.stringify(e).slice(0,300);
          })()`)
          diagWrite("CRASH: " ++ errMsg)

          // Drain the queue to avoid replaying the crashing message
          state.messageQueue = []
        }
      }

      state.isDispatching = false
    }
  }

  and processMessage = (msg: 'msg): unit => {
    // Update model
    let (newModel, cmd) = config.update(state.model, msg)
    state.model = newModel

    // Re-render — wrapped in try/catch so a crashing view() doesn't kill dispatch
    try {
      render()
    } catch {
    | exn => {
        Console.error2("[PanLL TEA] render crash:", exn)
        let errMsg: string = %raw(`(function() {
            var e = exn;
            if (e && e.RE_EXN_ID) return 'ReScript: ' + e.RE_EXN_ID + ' ' + JSON.stringify(e._1 || e._2 || '').slice(0,200);
            if (e && e.message) return e.message;
            if (e && e.stack) return e.stack.split('\\n')[0];
            return JSON.stringify(e).slice(0,300);
          })()`)
        diagWrite("RENDER CRASH: " ++ errMsg)
      }
    }

    // Update subscriptions if they changed
    try {
      updateSubscriptions()
    } catch {
    | exn => Console.error2("[PanLL TEA] subscription crash:", exn)
    }

    // Execute commands (may dispatch more messages)
    Tea_Cmd.execute(cmd, dispatch)
  }

  and render = (): unit => {
    let vdom = config.view(state.model)

    switch (state.container, state.renderState) {
    | (Some(container), Some(renderState)) => // Update existing render
      Tea_Render.update(container, vdom, renderState)
    | (Some(container), None) => {
        // Initial render - create render state
        let renderState = Tea_Render.createState(dispatch)
        Tea_Render.render(container, vdom, renderState)
        state.renderState = Some(renderState)
      }
    | (None, _) => // No container - validate and mount to #app via SafeMount
      switch SafeMount.validateAndFind("#app") {
      | Error(reason) => Console.warn(reason)
      | Ok(container) => {
          let renderState = Tea_Render.createState(dispatch)
          Tea_Render.render(container, vdom, renderState)
          state.renderState = Some(renderState)
          state.container = Some(container)
          SafeMount.trace("tea-app-init", "mounted to #app")
        }
      }
    }
  }

  and updateSubscriptions = (): unit => {
    let newSub = config.subscriptions(state.model)

    // Check if subscriptions changed (compare keys)
    let oldKeys = Tea_Sub.getKeys(state.currentSub)
    let newKeys = Tea_Sub.getKeys(newSub)

    let changed =
      Array.length(oldKeys) !== Array.length(newKeys) ||
        Array.some(oldKeys, key => !Array.includes(newKeys, key))

    if changed {
      // Clean up old subscriptions
      state.subscriptionCleanup()

      // Enable new subscriptions
      state.currentSub = newSub
      state.subscriptionCleanup = Tea_Sub.enable(newSub, dispatch)
    }
  }

  // Initialise safety layers (DOMPurify, Trusted Types, MountTracer)
  let _safetyReport = SafeMount.initSafety()

  // Initial render
  render()

  // Set up initial subscriptions
  let initialSub = config.subscriptions(state.model)
  state.currentSub = initialSub
  state.subscriptionCleanup = Tea_Sub.enable(initialSub, dispatch)

  // Execute initial commands
  Tea_Cmd.execute(initialCmd, dispatch)

  // Expose debug API on window for agent/developer introspection.
  // window.__panll.getModel()  — read full model state as JS object
  // window.__panll.dispatch(msg) — inject a TEA message
  // window.__panll.snapshot()   — JSON summary of key state fields
  // window.__panll.diagCount    — number of messages dispatched
  let _exposeDebugApi: (unit => 'model, 'msg => unit, ref<int>) => unit = %raw(`
    function(getModel, dispatch, diagCount) {
      window.__panll = {
        getModel: getModel,
        dispatch: dispatch,
        diagCount: diagCount,
        snapshot: function() {
          var m = getModel();
          return {
            viewMode: m.viewMode,
            activePanel: m.panelSwitcher ? m.panelSwitcher.activePanel : null,
            panelBarVisible: m.panelBarVisible,
            paneLVisible: m.paneLVisible,
            paneNVisible: m.paneNVisible,
            paneWVisible: m.paneWVisible,
            fullscreen: m.fullscreenActive,
            constraintCount: m.paneL ? m.paneL.constraints.length : 0,
            tokenCount: m.paneN ? m.paneN.tokens.length : 0,
            inferenceActive: m.paneN ? m.paneN.inferenceActive : false,
            eventChainCount: m.paneW ? m.paneW.eventChain.length : 0,
            focusDimming: m.focusDimming ? m.focusDimming.mode : null,
            humidity: m.humidity,
            orbitalStability: m.orbital ? m.orbital.stability : null,
            echidnaConnected: m.echidna ? m.echidna.connected : false,
            keybindingCount: m.keybindings ? m.keybindings.bindings.length : 0,
            dispatched: diagCount.contents
          };
        }
      };
      window.__panll_log && window.__panll_log('debug API ready');
    }
  `)
  _exposeDebugApi(() => state.model, dispatch, diagCount)

  // Return program interface
  {
    shutdown: () => {
      state.subscriptionCleanup()
    },
    getModel: () => state.model,
  }
}

/// Create a simple program (no subscriptions)
let simpleProgram = (
  ~init: unit => ('model, Tea_Cmd.t<'msg>),
  ~update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  ~view: 'model => Tea_Vdom.t<'msg>,
  (),
): programInterface<'msg, 'model> => {
  standardProgram(~init, ~update, ~view, ~subscriptions=_ => Tea_Sub.none, ())
}
