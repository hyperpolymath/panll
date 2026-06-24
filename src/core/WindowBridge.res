// SPDX-License-Identifier: MPL-2.0

/// PanLL WindowBridge — FFI bindings for cross-window communication.
///
/// Provides a safe ReScript interface to browser APIs used by the tiling
/// system for detached panel windows. All bindings are defensive — they
/// use try/catch internally to handle browsers that block popups or lack
/// BroadcastChannel support (Safari < 15.4, older WebViews).
///
/// The tiling system uses BroadcastChannel for message passing between the
/// main PanLL window and detached panel windows. Each channel is named after
/// the detached window (windowName) so messages are scoped correctly.
///
/// DESIGN NOTE: We use `%raw` rather than `@module`/`@send` bindings because
/// the BroadcastChannel API requires constructor invocation and event listener
/// patterns that are awkward to express with ReScript's `@new` and `@send`.
/// The raw JS is minimal and wrapped in try/catch for safety.
///
/// SECURITY NOTE: BroadcastChannel messages are same-origin only, which is
/// sufficient for PanLL's use case (all windows serve from the same origin).
/// Message payloads are JSON strings — the caller is responsible for
/// serialisation and deserialisation.

/// Opaque type representing a BroadcastChannel instance.
///
/// Consumers should not inspect or manipulate this value directly.
/// Use createChannel, postMessage, onMessage, and closeChannel instead.
type broadcastChannel

/// Open a new browser window for a detached panel.
///
/// Wraps window.open(url, name, features). Returns Some(windowRef) on
/// success or None if the popup was blocked by the browser. The windowRef
/// is a Dom.element representing the Window object (typed as element for
/// ReScript DOM compatibility).
///
/// Parameters:
///   - url: the URL to load in the new window (e.g. "/detached?panel=farm")
///   - name: the window.name for the new window (used as BroadcastChannel target)
///   - features: window features string (e.g. "width=800,height=600")
let openWindow: (string, string, string) => option<Dom.element> = %raw(`
  function(url, name, features) {
    try {
      var w = window.open(url, name, features);
      if (w == null) return undefined;
      return w;
    } catch (e) {
      return undefined;
    }
  }
`)

/// Create a new BroadcastChannel with the given channel name.
///
/// The channel name should match the windowName of the detached panel
/// so that messages are scoped to that specific panel's communication.
///
/// Falls back to a no-op stub object if BroadcastChannel is not supported
/// by the browser, allowing the rest of the code to call postMessage and
/// onMessage without runtime errors (they will simply do nothing).
let createChannel: string => broadcastChannel = %raw(`
  function(name) {
    try {
      if (typeof BroadcastChannel !== 'undefined') {
        return new BroadcastChannel(name);
      }
      // Stub for unsupported browsers — methods are no-ops.
      return {
        postMessage: function() {},
        close: function() {},
        addEventListener: function() {},
        removeEventListener: function() {}
      };
    } catch (e) {
      return {
        postMessage: function() {},
        close: function() {},
        addEventListener: function() {},
        removeEventListener: function() {}
      };
    }
  }
`)

/// Post a JSON string message to the BroadcastChannel.
///
/// The message is broadcast to all other BroadcastChannel instances with
/// the same name (i.e. the detached panel window listening on this channel).
///
/// Does nothing if the channel is a no-op stub (unsupported browser).
let postMessage: (broadcastChannel, string) => unit = %raw(`
  function(channel, message) {
    try {
      channel.postMessage(message);
    } catch (e) {
      // Silently ignore — channel may be closed or browser unsupported.
    }
  }
`)

/// Listen for messages on the BroadcastChannel.
///
/// Registers a callback that receives the message data (string) whenever
/// a message arrives on the channel. Returns a cleanup function that
/// removes the listener when called.
///
/// The cleanup function MUST be called when the component unmounts or the
/// channel is no longer needed, to prevent memory leaks.
///
/// Parameters:
///   - channel: the BroadcastChannel to listen on
///   - callback: function called with the message data string
///
/// Returns: a cleanup function (unit => unit) that removes the listener
let onMessage: (broadcastChannel, string => unit) => unit => unit = %raw(`
  function(channel, callback) {
    try {
      var handler = function(event) {
        try {
          callback(event.data);
        } catch (e) {
          // Prevent listener errors from crashing the channel.
        }
      };
      channel.addEventListener('message', handler);
      return function() {
        try {
          channel.removeEventListener('message', handler);
        } catch (e) {
          // Ignore cleanup errors.
        }
      };
    } catch (e) {
      // Return a no-op cleanup if addEventListener failed.
      return function() {};
    }
  }
`)

/// Close a BroadcastChannel, releasing its resources.
///
/// After closing, no further messages can be sent or received on this
/// channel. Any pending onMessage listeners are automatically removed
/// by the browser. Calling close on an already-closed channel is safe
/// (caught internally).
let closeChannel: broadcastChannel => unit = %raw(`
  function(channel) {
    try {
      channel.close();
    } catch (e) {
      // Ignore — channel may already be closed.
    }
  }
`)

/// Close a detached panel's browser window.
///
/// Wraps windowRef.close(). The windowRef is the Dom.element returned by
/// openWindow. Closing a window that is already closed is safe (caught
/// internally). After closing, the tiling engine should mark the panel
/// as dead or remove it from the detachedPanels array.
let closeWindow: Dom.element => unit = %raw(`
  function(windowRef) {
    try {
      windowRef.close();
    } catch (e) {
      // Ignore — window may already be closed or cross-origin.
    }
  }
`)
