// SPDX-License-Identifier: AGPL-3.0-or-later

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

/// Simple program without subscriptions
type simpleProgramConfig<'model, 'msg> = {
  init: unit => ('model, Tea_Cmd.t<'msg>),
  update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  view: 'model => Tea_Vdom.t<'msg>,
}

/// Application state
type appState<'model, 'msg> = {
  mutable model: 'model,
  mutable subscriptionCleanup: option<unit => unit>,
}

/// Create a standard program
let standardProgram = (config: programConfig<'model, 'msg>) => {
  (container: Tea_Render.domElement, onReady: unit => unit) => {
    // Initialise model and commands
    let (initialModel, initialCmd) = config.init()

    // Create mutable app state
    let state = {
      model: initialModel,
      subscriptionCleanup: None,
    }

    // Dispatch function - the heart of TEA
    let rec dispatch = (msg: 'msg): unit => {
      // Update model
      let (newModel, cmd) = config.update(state.model, msg)
      state.model = newModel

      // Execute commands
      let cmdMsgs = Tea_Cmd.execute(cmd)
      Array.forEach(cmdMsgs, dispatch)

      // Re-render
      render()
    }
    and render = (): unit => {
      let vdom = config.view(state.model)
      Tea_Render.render(container, vdom, dispatch)
    }

    // Initial render
    render()

    // Execute initial commands
    let cmdMsgs = Tea_Cmd.execute(initialCmd)
    Array.forEach(cmdMsgs, dispatch)

    // Set up subscriptions
    let sub = config.subscriptions(state.model)
    if sub.key !== "__none__" {
      state.subscriptionCleanup = Some(sub.enable(dispatch))
    }

    // Signal ready
    onReady()

    state
  }
}

/// Create a simple program (no subscriptions)
let simpleProgram = (config: simpleProgramConfig<'model, 'msg>) => {
  standardProgram({
    init: config.init,
    update: config.update,
    view: config.view,
    subscriptions: _ => Tea_Sub.none,
  })
}
