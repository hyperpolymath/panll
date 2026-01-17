// SPDX-License-Identifier: AGPL-3.0-or-later

/// TEA Commands - Side effects in the TEA architecture.
///
/// Commands represent side effects that should be performed by the runtime.
/// They are opaque values that get executed after the update function returns.

/// A command that can produce messages of type 'msg
type t<'msg> = array<unit => option<'msg>>

/// No command - no side effects (function to avoid value restriction)
let none = (): t<'msg> => []

/// Create a command from a function that may produce a message
let msg = (m: 'msg): t<'msg> => [() => Some(m)]

/// Batch multiple commands together
let batch = (cmds: array<t<'msg>>): t<'msg> => Array.flat(cmds)

/// Map a command's message type
let map = (cmd: t<'a>, f: 'a => 'b): t<'b> => {
  Array.map(cmd, thunk => {
    () => {
      switch thunk() {
      | Some(a) => Some(f(a))
      | None => None
      }
    }
  })
}

/// Execute all commands and collect messages
let execute = (cmd: t<'msg>): array<'msg> => {
  cmd
  ->Array.map(thunk => thunk())
  ->Array.filter(Option.isSome)
  ->Array.map(opt => Option.getExn(opt))
}
