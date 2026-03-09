// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// DOMPurify.res — FFI binding to DOMPurify (cure53), the industry-standard
// HTML sanitisation library recommended by OWASP.
//
// DOMPurify uses the browser's own DOM parser to build a tree, then walks
// every node removing or neutralising unsafe elements and attributes. This
// eliminates the entire class of mutation XSS (mXSS) attacks that regex-based
// sanitisers cannot catch.
//
// This binding provides a graceful fallback: if DOMPurify is not loaded
// (e.g. in test environments or SSR), all operations return None so the
// caller can fall back to the built-in regex sanitiser.
//
// Usage in SafeDOMCore:
//   let sanitised = switch DOMPurify.sanitize(html) {
//   | Some(clean) => clean
//   | None => regexFallbackSanitise(html) // Built-in defence-in-depth
//   }
//
// DOMPurify must be loaded before the app bundle. Add to index.html:
//   <script src="https://cdnjs.cloudflare.com/ajax/libs/dompurify/3.3.2/purify.min.js"
//           integrity="sha384-..."
//           crossorigin="anonymous"></script>
//
// Or install via deno.json / import map and bundle it.

/// Check whether DOMPurify is available in the global scope.
/// Returns true if window.DOMPurify exists and has a sanitize method.
let isAvailable: unit => bool = () => {
  %raw(`typeof globalThis.DOMPurify !== 'undefined' && typeof globalThis.DOMPurify.sanitize === 'function'`)
}

/// Configuration for DOMPurify.sanitize().
/// Maps to the DOMPurify config object.
type config = {
  /// Allowlisted HTML tags. If empty, uses DOMPurify defaults.
  allowedTags?: array<string>,
  /// Allowlisted HTML attributes. If empty, uses DOMPurify defaults.
  allowedAttr?: array<string>,
  /// Forbid specific tags (blocklist on top of defaults).
  forbidTags?: array<string>,
  /// Forbid specific attributes.
  forbidAttr?: array<string>,
  /// Return a DOM node instead of string (we always want string).
  returnDom?: bool,
  /// Allow custom elements.
  customElementHandling?: bool,
}

/// Default configuration that blocks the most dangerous elements.
/// Removes: script, iframe, object, embed, form, base, meta (with http-equiv),
/// svg (event handlers), math, link (stylesheet injection), template.
let defaultConfig: config = {
  forbidTags: [
    "script",
    "iframe",
    "object",
    "embed",
    "form",
    "base",
    "meta",
    "link",
    "template",
    "math",
    "svg",
  ],
  forbidAttr: [
    "onerror",
    "onload",
    "onclick",
    "onmouseover",
    "onfocus",
    "onblur",
    "onsubmit",
    "onchange",
    "oninput",
    "onkeydown",
    "onkeyup",
    "onkeypress",
    "formaction",
    "xlink:href",
    "action",
  ],
}

/// Sanitise HTML using DOMPurify with default high-assurance config.
/// Returns Some(sanitised) if DOMPurify is available, None otherwise.
let sanitize = (_html: string): option<string> => {
  if isAvailable() {
    let _forbidTags = defaultConfig.forbidTags
    let _forbidAttr = defaultConfig.forbidAttr
    let result: string = %raw(`
      globalThis.DOMPurify.sanitize(_html, {
        FORBID_TAGS: _forbidTags || [],
        FORBID_ATTR: _forbidAttr || [],
        ALLOW_ARIA_ATTR: true,
        ALLOW_DATA_ATTR: false,
        RETURN_DOM: false,
        RETURN_DOM_FRAGMENT: false,
        WHOLE_DOCUMENT: false
      })
    `)
    Some(result)
  } else {
    None
  }
}

/// Sanitise HTML using a custom DOMPurify configuration.
/// Returns Some(sanitised) if DOMPurify is available, None otherwise.
let sanitizeWithConfig = (_html: string, cfg: config): option<string> => {
  if isAvailable() {
    let _forbidTags = switch cfg.forbidTags {
    | Some(tags) => tags
    | None => []
    }
    let _forbidAttr = switch cfg.forbidAttr {
    | Some(attrs) => attrs
    | None => []
    }
    let _allowedTags = switch cfg.allowedTags {
    | Some(tags) => tags
    | None => []
    }
    let _allowedAttr = switch cfg.allowedAttr {
    | Some(attrs) => attrs
    | None => []
    }
    let _hasAllowedTags = Option.isSome(cfg.allowedTags)
    let _hasAllowedAttr = Option.isSome(cfg.allowedAttr)
    let result: string = %raw(`
      (function() {
        var config = {
          FORBID_TAGS: _forbidTags,
          FORBID_ATTR: _forbidAttr,
          ALLOW_ARIA_ATTR: true,
          ALLOW_DATA_ATTR: false,
          RETURN_DOM: false
        };
        if (_hasAllowedTags) config.ALLOWED_TAGS = _allowedTags;
        if (_hasAllowedAttr) config.ALLOWED_ATTR = _allowedAttr;
        return globalThis.DOMPurify.sanitize(_html, config);
      })()
    `)
    Some(result)
  } else {
    None
  }
}

/// Get DOMPurify version string, if available.
let version = (): option<string> => {
  if isAvailable() {
    let v: string = %raw(`globalThis.DOMPurify.version || "unknown"`)
    Some(v)
  } else {
    None
  }
}
