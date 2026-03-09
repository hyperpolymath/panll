// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Test.res — Testing helpers for TEA applications.
//
// Test the model-update-view cycle without requiring a DOM.
//
// Usage:
//   let sim = Tea_Test.simulate(~init, ~update)
//   sim->Tea_Test.send(Increment)
//   assert(sim->Tea_Test.model == {count: 1})

/// A simulation of a TEA application for testing
type simulation<'model, 'msg> = {
  mutable model: 'model,
  update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
  mutable messages: array<'msg>,
  mutable commands: array<Tea_Cmd.t<'msg>>,
}

/// Create a simulation from init and update functions
let simulate = (
  ~init: unit => ('model, Tea_Cmd.t<'msg>),
  ~update: ('model, 'msg) => ('model, Tea_Cmd.t<'msg>),
): simulation<'model, 'msg> => {
  let (initialModel, initialCmd) = init()
  {
    model: initialModel,
    update,
    messages: [],
    commands: initialCmd === Tea_Cmd.none ? [] : [initialCmd],
  }
}

/// Send a message to the simulation, updating the model
let send = (sim: simulation<'model, 'msg>, msg: 'msg): unit => {
  let (newModel, cmd) = sim.update(sim.model, msg)
  sim.model = newModel
  Array.push(sim.messages, msg)->ignore
  if cmd !== Tea_Cmd.none {
    Array.push(sim.commands, cmd)->ignore
  }
}

/// Send multiple messages in sequence
let sendAll = (sim: simulation<'model, 'msg>, msgs: array<'msg>): unit => {
  Array.forEach(msgs, msg => send(sim, msg))
}

/// Get the current model
let model = (sim: simulation<'model, 'msg>): 'model => sim.model

/// Get all messages that have been sent
let messageHistory = (sim: simulation<'model, 'msg>): array<'msg> => sim.messages

/// Get the number of messages sent
let messageCount = (sim: simulation<'model, 'msg>): int => Array.length(sim.messages)

/// Check if any commands were produced
let hasCommands = (sim: simulation<'model, 'msg>): bool => Array.length(sim.commands) > 0

/// Reset the simulation to initial state
let reset = (
  sim: simulation<'model, 'msg>,
  ~init: unit => ('model, Tea_Cmd.t<'msg>),
): unit => {
  let (initialModel, _) = init()
  sim.model = initialModel
  sim.messages = []
  sim.commands = []
}

/// Assert that the current model satisfies a predicate
let assertModel = (sim: simulation<'model, 'msg>, predicate: 'model => bool, label: string): bool => {
  if predicate(sim.model) {
    true
  } else {
    Console.error(`Tea_Test assertion failed: ${label}`)
    false
  }
}

/// Run a scenario: array of (msg, predicate, label)
let runScenario = (
  sim: simulation<'model, 'msg>,
  steps: array<('msg, 'model => bool, string)>,
): array<(int, string, bool)> => {
  Array.mapWithIndex(steps, ((msg, predicate, label), i) => {
    send(sim, msg)
    let passed = predicate(sim.model)
    if !passed {
      Console.error(`Step ${Int.toString(i)}: ${label} — FAILED`)
    }
    (i, label, passed)
  })
}

/// Render a view to HTML string for snapshot testing (delegates to Tea_Ssr)
let viewSnapshot = (view: 'model => Tea_Vdom.t<'msg>, aModel: 'model): string => {
  Tea_Ssr.toString(view(aModel))
}
