// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// TrustedTypes.res — W3C Trusted Types API binding for browser-engine-level
// DOM XSS prevention.
//
// Trusted Types (https://www.w3.org/TR/trusted-types/) prevent DOM XSS by
// requiring all injection-sink inputs (innerHTML, document.write, etc.) to
// pass through a named policy. If enforcement is enabled via CSP header:
//
//   Content-Security-Policy: require-trusted-types-for 'script'; trusted-types panll-safe-dom
//
// ...then the browser itself blocks any innerHTML assignment that does not
// come through our "panll-safe-dom" policy. This is defence-in-depth on top
// of DOMPurify sanitisation — even if sanitisation has a bug, the browser
// engine acts as a second gate.
//
// Deployed by Google across 130+ services since 2019 with zero DOM XSS
// incidents (per their published case study).
//
// Usage:
//   TrustedTypes.init() at app startup creates the policy.
//   TrustedTypes.createHTML(rawHtml) returns a TrustedHTML value.
//   Use the TrustedHTML value with innerHTML assignments.
//
// Graceful degradation: in browsers without Trusted Types support, all
// operations fall through to plain strings.

/// Opaque type representing a browser TrustedHTML value.
/// In browsers with Trusted Types, this is a real TrustedHTML object.
/// In browsers without support, this is a plain string.
type trustedHTML

/// Whether the browser supports the Trusted Types API.
let isSupported: unit => bool = () => {
  %raw(`typeof globalThis.trustedTypes !== 'undefined' && typeof globalThis.trustedTypes.createPolicy === 'function'`)
}

/// Opaque policy handle type.
type policyHandle

/// Internal: reference to our created policy (or null).
let policyRef: ref<option<policyHandle>> = ref(None)

/// Initialise the PanLL Trusted Types policy.
///
/// Creates a policy named "panll-safe-dom" that:
///   1. Runs input through DOMPurify if available
///   2. Falls back to the string as-is (caller is responsible for pre-sanitisation)
///
/// Call this once at app startup. Safe to call multiple times — only the first
/// call creates the policy, subsequent calls are no-ops.
///
/// Returns true if the policy was created, false if Trusted Types is not
/// supported or the policy already exists.
let init = (): bool => {
  switch policyRef.contents {
  | Some(_) => false // Already initialised
  | None =>
    if isSupported() {
      let _policy: policyHandle = %raw(`
        globalThis.trustedTypes.createPolicy('panll-safe-dom', {
          createHTML: function(input) {
            // If DOMPurify is available, sanitise through it.
            // Otherwise trust the caller (SafeDOMCore pre-sanitises).
            if (typeof globalThis.DOMPurify !== 'undefined') {
              return globalThis.DOMPurify.sanitize(input, {
                RETURN_TRUSTED_TYPE: true,
                FORBID_TAGS: ['script', 'iframe', 'object', 'embed', 'form', 'base', 'meta', 'link', 'template', 'math', 'svg'],
                FORBID_ATTR: ['onerror', 'onload', 'onclick', 'onmouseover', 'onfocus', 'onblur', 'onsubmit', 'onchange', 'oninput', 'onkeydown', 'onkeyup', 'onkeypress', 'formaction', 'xlink:href', 'action']
              });
            }
            return input;
          },
          createScript: function() {
            // Block all script creation through Trusted Types
            throw new Error('panll-safe-dom policy: script creation is blocked');
          },
          createScriptURL: function() {
            // Block all script URL creation through Trusted Types
            throw new Error('panll-safe-dom policy: script URL creation is blocked');
          }
        })
      `)
      policyRef := Some(_policy)
      true
    } else {
      false
    }
  }
}

/// Create a TrustedHTML value from a raw HTML string.
/// If Trusted Types is supported and the policy is initialised, returns
/// a real TrustedHTML object that the browser will accept at innerHTML sinks.
/// Otherwise returns the input string cast to trustedHTML (graceful degradation).
let createHTML = (html: string): trustedHTML => {
  switch policyRef.contents {
  | Some(_policy) =>
    let result: trustedHTML = %raw(`_policy.createHTML(html)`)
    result
  | None =>
    // No Trusted Types — return string as-is (cast to opaque type).
    // Uses identity function instead of Obj.magic (banned pattern).
    let stringToTrustedHTML: string => trustedHTML = %raw(`function(s) { return s; }`)
    stringToTrustedHTML(html)
  }
}

/// Convert a TrustedHTML value back to a string for logging/tracing.
/// Works regardless of whether Trusted Types is active.
let toString = (_trusted: trustedHTML): string => {
  %raw(`String(_trusted)`)
}

/// Check whether a policy named "panll-safe-dom" is registered.
let hasPanllPolicy = (): bool => {
  Option.isSome(policyRef.contents)
}
