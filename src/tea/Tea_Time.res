// SPDX-License-Identifier: MPL-2.0

/// TEA Time - Time-based subscriptions
///
/// Provides subscriptions for intervals and timeouts.

/// Subscribe to a repeating interval
let every = (intervalMs: float, tagger: float => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("time-interval-" ++ Float.toString(intervalMs), dispatch => {
    let intervalId = setInterval(() => {
      dispatch(tagger(Date.now()))
    }, Int.fromFloat(intervalMs))

    // Return cleanup function
    () => clearInterval(intervalId)
  })
}

/// Subscribe to a one-time timeout
let after = (delayMs: float, msg: 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("time-timeout-" ++ Float.toString(delayMs), dispatch => {
    let timeoutId = setTimeout(() => {
      dispatch(msg)
    }, Int.fromFloat(delayMs))

    // Return cleanup function
    () => clearTimeout(timeoutId)
  })
}
