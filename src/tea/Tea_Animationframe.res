// SPDX-License-Identifier: MPL-2.0

/// TEA Animation Frame - Request animation frame subscriptions
///
/// Provides subscriptions for smooth animations using requestAnimationFrame.

@val external requestAnimationFrame: (float => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"

/// Subscribe to animation frames
let onAnimationFrame = (tagger: float => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("animation-frame", dispatch => {
    let id = ref(0)
    let rec callback = (time: float) => {
      dispatch(tagger(time))
      id := requestAnimationFrame(callback)
    }
    id := requestAnimationFrame(callback)

    // Return cleanup function
    () => cancelAnimationFrame(id.contents)
  })
}
