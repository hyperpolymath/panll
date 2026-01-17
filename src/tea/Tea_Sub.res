// SPDX-License-Identifier: AGPL-3.0-or-later

/// TEA Subscriptions - External event sources.
///
/// Subscriptions allow the TEA application to receive messages from
/// external sources like timers, WebSockets, or browser events.

/// A subscription that produces messages of type 'msg
type t<'msg> = {
  key: string,
  enable: ('msg => unit) => unit => unit, // Returns cleanup function
}

/// No subscription
let none: t<'msg> = {
  key: "__none__",
  enable: _ => () => (),
}

/// Batch multiple subscriptions (simplified - just returns first non-none)
let batch = (subs: array<t<'msg>>): t<'msg> => {
  switch Array.find(subs, s => s.key !== "__none__") {
  | Some(s) => s
  | None => none
  }
}

/// Map a subscription's message type
let map = (sub: t<'a>, f: 'a => 'b): t<'b> => {
  {
    key: sub.key,
    enable: dispatch => {
      sub.enable(a => dispatch(f(a)))
    },
  }
}

/// Create a subscription from a key and enabler function
let make = (key: string, enable: ('msg => unit) => unit => unit): t<'msg> => {
  {key, enable}
}
