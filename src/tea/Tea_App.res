// SPDX-License-Identifier: PMPL-1.0-or-later

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

  // Message dispatch function
  let rec dispatch = (msg: 'msg): unit => {
    // Queue message if already dispatching (prevent recursion)
    if state.isDispatching {
      Array.push(state.messageQueue, msg)
    } else {
      state.isDispatching = true

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

      state.isDispatching = false
    }
  }

  and processMessage = (msg: 'msg): unit => {
    // Update model
    let (newModel, cmd) = config.update(state.model, msg)
    state.model = newModel

    // Re-render
    render()

    // Update subscriptions if they changed
    updateSubscriptions()

    // Execute commands (may dispatch more messages)
    Tea_Cmd.execute(cmd, dispatch)
  }

  and render = (): unit => {
    let vdom = config.view(state.model)

    switch (state.container, state.renderState) {
    | (Some(container), Some(renderState)) => {
        // Update existing render
        Tea_Render.update(container, vdom, renderState)
      }
    | (Some(container), None) => {
        // Initial render - create render state
        let renderState = Tea_Render.createState(dispatch)
        Tea_Render.render(container, vdom, renderState)
        state.renderState = Some(renderState)
      }
    | (None, _) => {
        // No container - try to mount to #app
        switch Tea_Render.mount("#app", vdom, dispatch) {
        | Some(renderState) => {
            state.renderState = Some(renderState)
            state.container = Tea_Render.querySelector("#app")
          }
        | None => Console.warn("No #app element found - rendering disabled")
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

  // Initial render
  render()

  // Set up initial subscriptions
  let initialSub = config.subscriptions(state.model)
  state.currentSub = initialSub
  state.subscriptionCleanup = Tea_Sub.enable(initialSub, dispatch)

  // Execute initial commands
  Tea_Cmd.execute(initialCmd, dispatch)

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
