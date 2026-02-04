// SPDX-License-Identifier: PMPL-1.0-or-later

/// TEA Subscriptions - External event sources.
///
/// Subscriptions allow the TEA application to receive messages from
/// external sources like timers, WebSockets, or browser events.

/// A subscription that produces messages of type 'msg
type rec t<'msg> =
  | None
  | Registration(string, ('msg => unit) => unit => unit)
  | Batch(array<t<'msg>>)

/// No subscription
let none: t<'msg> = None

/// Create a subscription with a unique key and enabler function
/// The enabler function receives a dispatch function and returns a cleanup function
let registration = (key: string, enable: ('msg => unit) => unit => unit): t<'msg> => {
  Registration(key, enable)
}

/// Batch multiple subscriptions together
let batch = (subs: list<t<'msg>>): t<'msg> => {
  let subArray = List.toArray(subs)
  // Filter out None subscriptions
  let filtered = Array.filter(subArray, sub => {
    switch sub {
    | None => false
    | _ => true
    }
  })

  switch Array.length(filtered) {
  | 0 => None
  | 1 => Array.getUnsafe(filtered, 0)
  | _ => Batch(filtered)
  }
}

/// Map a subscription's message type
let rec map = (sub: t<'a>, f: 'a => 'b): t<'b> => {
  switch sub {
  | None => None
  | Registration(key, enable) =>
    Registration(
      key,
      dispatch => {
        enable(a => dispatch(f(a)))
      },
    )
  | Batch(subs) => Batch(Array.map(subs, s => map(s, f)))
  }
}

/// Get all registration keys from a subscription (for diffing)
let rec getKeys = (sub: t<'msg>): array<string> => {
  switch sub {
  | None => []
  | Registration(key, _) => [key]
  | Batch(subs) => Array.flatMap(subs, getKeys)
  }
}

/// Enable a subscription and return cleanup function
let rec enable = (sub: t<'msg>, dispatch: 'msg => unit): (unit => unit) => {
  switch sub {
  | None => () => ()
  | Registration(_key, enabler) => enabler(dispatch)
  | Batch(subs) => {
      let cleanups = Array.map(subs, s => enable(s, dispatch))
      () => Array.forEach(cleanups, cleanup => cleanup())
    }
  }
}
