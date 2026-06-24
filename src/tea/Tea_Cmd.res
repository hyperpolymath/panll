// SPDX-License-Identifier: MPL-2.0

/// TEA Commands - Side effects in the TEA architecture.
///
/// Commands represent side effects that should be performed by the runtime.
/// They are opaque values that get executed after the update function returns.

/// Callbacks for command execution
type callbacks<'msg> = {enqueue: 'msg => unit}

/// A command that can produce messages of type 'msg
type rec t<'msg> =
  | None
  | Msg('msg)
  | Batch(array<t<'msg>>)
  | Call(callbacks<'msg> => unit)

/// No command - no side effects
let none: t<'msg> = None

/// Create a command that immediately sends a message
let msg = (m: 'msg): t<'msg> => Msg(m)

/// Batch multiple commands together
let batch = (cmds: list<t<'msg>>): t<'msg> => {
  let cmdArray = List.toArray(cmds)
  switch Array.length(cmdArray) {
  | 0 => None
  | 1 => Array.getUnsafe(cmdArray, 0)
  | _ => Batch(cmdArray)
  }
}

/// Create a command from a callback function
/// This is the main way to integrate async operations (Promises, etc.)
let call = (f: callbacks<'msg> => unit): t<'msg> => Call(f)

/// Map a command's message type
let rec map = (cmd: t<'a>, f: 'a => 'b): t<'b> => {
  switch cmd {
  | None => None
  | Msg(a) => Msg(f(a))
  | Batch(cmds) => Batch(Array.map(cmds, c => map(c, f)))
  | Call(callback) => Call(callbacks => callback({enqueue: a => callbacks.enqueue(f(a))}))
  }
}

/// Execute a command and collect immediate messages
/// Async commands are started but their results come later via callbacks
let rec execute = (cmd: t<'msg>, dispatch: 'msg => unit): unit => {
  switch cmd {
  | None => ()
  | Msg(m) => dispatch(m)
  | Batch(cmds) => Array.forEach(cmds, c => execute(c, dispatch))
  | Call(f) => {
      let callbacks = {enqueue: dispatch}
      f(callbacks)
    }
  }
}
