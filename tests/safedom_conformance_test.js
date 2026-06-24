// SPDX-License-Identifier: MPL-2.0

/**
 * SafeDOM Conformance Tests
 *
 * These tests verify that SafeDOM's runtime behaviour conforms to the safety
 * properties that would be formally proven via Idris2 dependent types:
 *
 * 1. Totality: sanitise always returns a result (never throws)
 * 2. Idempotency: sanitise(sanitise(x)) === sanitise(x)
 * 3. Monotonicity: sanitise never increases the size of input
 * 4. Safety: sanitise removes all known dangerous patterns
 * 5. Preservation: sanitise preserves safe content unchanged
 * 6. Structural: nesting validator catches all misnested tags
 * 7. Size bounds: content over 1MB is rejected
 * 8. Selector validity: valid CSS selectors pass, invalid ones are rejected
 */

import { assertEquals, assert, assertNotEquals } from "jsr:@std/assert";
import {
  ProvenSelector,
  ProvenHTML,
  MountTracer,
} from "../src/core/SafeDOMCore.res.js";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Reset MountTracer between tests to avoid trace pollution. */
function resetTracer() {
  MountTracer.clear();
}

// =========================================================================
// 1. Totality — sanitise always returns a result, never throws
// =========================================================================

Deno.test("Totality - empty string does not throw", () => {
  const [result, method] = ProvenHTML.sanitise("");
  assertEquals(typeof result, "string");
  assert(method === "DualLayer" || method === "RegexFallback");
});

Deno.test("Totality - null-like string does not throw", () => {
  const [result, _method] = ProvenHTML.sanitise("null");
  assertEquals(typeof result, "string");
});

Deno.test("Totality - huge string (100KB) does not throw", () => {
  const huge = "<p>" + "x".repeat(100_000) + "</p>";
  const [result, _method] = ProvenHTML.sanitise(huge);
  assertEquals(typeof result, "string");
});

Deno.test("Totality - unicode content does not throw", () => {
  const [result, _method] = ProvenHTML.sanitise("<p>\u{1F600}\u{1F4A9}\u00E9\u00F1</p>");
  assertEquals(typeof result, "string");
});

Deno.test("Totality - deeply nested tags do not throw", () => {
  let html = "";
  for (let i = 0; i < 100; i++) html += "<div>";
  for (let i = 0; i < 100; i++) html += "</div>";
  const [result, _method] = ProvenHTML.sanitise(html);
  assertEquals(typeof result, "string");
});

Deno.test("Totality - only whitespace does not throw", () => {
  const [result, _method] = ProvenHTML.sanitise("   \t\n  ");
  assertEquals(typeof result, "string");
});

Deno.test("Totality - regexSanitise on empty string does not throw", () => {
  const result = ProvenHTML.regexSanitise("");
  assertEquals(result, "");
});

// =========================================================================
// 2. Idempotency — sanitise(sanitise(x)) === sanitise(x)
// =========================================================================

Deno.test("Idempotency - clean HTML", () => {
  const input = "<p>Hello <strong>world</strong></p>";
  const [once, _m1] = ProvenHTML.sanitise(input);
  const [twice, _m2] = ProvenHTML.sanitise(once);
  assertEquals(once, twice);
});

Deno.test("Idempotency - dangerous HTML", () => {
  const input = '<div onclick="alert(1)"><script>xss</script><p>safe</p></div>';
  const [once, _m1] = ProvenHTML.sanitise(input);
  const [twice, _m2] = ProvenHTML.sanitise(once);
  assertEquals(once, twice);
});

Deno.test("Idempotency - mixed content with javascript: URLs", () => {
  const input = '<a href="javascript:void(0)">link</a><p>text</p>';
  const [once, _m1] = ProvenHTML.sanitise(input);
  const [twice, _m2] = ProvenHTML.sanitise(once);
  assertEquals(once, twice);
});

Deno.test("Idempotency - regexSanitise is idempotent", () => {
  const input = '<img onerror="alert(1)" src=x><iframe src="evil"></iframe>';
  const once = ProvenHTML.regexSanitise(input);
  const twice = ProvenHTML.regexSanitise(once);
  assertEquals(once, twice);
});

// =========================================================================
// 3. Monotonicity — sanitise never increases input size for dangerous content
// =========================================================================

Deno.test("Monotonicity - script tag removal reduces size", () => {
  const input = "<script>alert(document.cookie)</script><p>safe</p>";
  const [result, _method] = ProvenHTML.sanitise(input);
  assert(result.length <= input.length);
});

Deno.test("Monotonicity - event handler removal reduces size", () => {
  const input = '<div onmouseover="steal()" onclick="exfil()">text</div>';
  const [result, _method] = ProvenHTML.sanitise(input);
  assert(result.length <= input.length);
});

Deno.test("Monotonicity - iframe removal reduces size", () => {
  const input = '<iframe src="https://evil.example.com/phish"></iframe><p>ok</p>';
  const [result, _method] = ProvenHTML.sanitise(input);
  assert(result.length <= input.length);
});

// =========================================================================
// 4. Safety — OWASP Top 10 XSS vectors are neutralised
// =========================================================================

Deno.test("Safety - script tag completely removed", () => {
  const [result, _m] = ProvenHTML.sanitise("<script>document.location='evil'</script>");
  assertEquals(result.includes("<script"), false);
  assertEquals(result.includes("document.location"), false);
});

Deno.test("Safety - onerror handler removed", () => {
  const [result, _m] = ProvenHTML.sanitise('<img src=x onerror="fetch(\'evil\')">');
  assertEquals(result.includes("onerror"), false);
});

Deno.test("Safety - javascript: protocol neutralised", () => {
  const [result, _m] = ProvenHTML.sanitise('<a href="javascript:alert(1)">click</a>');
  assertEquals(result.includes("javascript:"), false);
});

Deno.test("Safety - data: URL in src removed", () => {
  const [result, _m] = ProvenHTML.sanitise('<img src="data:text/html,<script>alert(1)</script>">');
  assertEquals(result.includes("data:text/html"), false);
});

Deno.test("Safety - SVG with payload stripped", () => {
  const [result, _m] = ProvenHTML.sanitise('<svg><animate onbegin="alert(1)"></animate></svg>');
  assertEquals(result.includes("<svg"), false);
});

Deno.test("Safety - object/embed tags stripped", () => {
  const [result, _m] = ProvenHTML.sanitise('<object data="evil.swf"></object><embed src="evil.swf">');
  assertEquals(result.includes("<object"), false);
  assertEquals(result.includes("<embed"), false);
});

// =========================================================================
// 5. Preservation — safe HTML passes through unchanged
// =========================================================================

Deno.test("Preservation - paragraph text unchanged", () => {
  const input = "<p>Hello world</p>";
  const result = ProvenHTML.regexSanitise(input);
  assertEquals(result, input);
});

Deno.test("Preservation - div with class unchanged", () => {
  const input = '<div class="container">content</div>';
  const result = ProvenHTML.regexSanitise(input);
  assertEquals(result, input);
});

Deno.test("Preservation - em, strong, span unchanged", () => {
  const input = "<em>italic</em> <strong>bold</strong> <span>text</span>";
  const result = ProvenHTML.regexSanitise(input);
  assertEquals(result, input);
});

Deno.test("Preservation - nested safe elements unchanged", () => {
  const input = "<div><ul><li>item 1</li><li>item 2</li></ul></div>";
  const result = ProvenHTML.regexSanitise(input);
  assertEquals(result, input);
});

Deno.test("Preservation - void elements (br, hr, img with safe src) unchanged", () => {
  const input = '<p>line<br>break</p><hr><img src="photo.jpg" alt="photo">';
  const result = ProvenHTML.regexSanitise(input);
  assertEquals(result, input);
});

// =========================================================================
// 6. Structural soundness — nesting validator catches malformed HTML
// =========================================================================

Deno.test("Structural - misnested <b><i></b></i> detected", () => {
  const r = ProvenHTML.checkTagNesting("<b><i></b></i>");
  assertEquals(r.TAG, "Error");
  assert(r._0.includes("Misnested"));
});

Deno.test("Structural - unclosed <div> detected", () => {
  const r = ProvenHTML.checkTagNesting("<div><p>text</p>");
  assertEquals(r.TAG, "Error");
  assert(r._0.includes("Unclosed"));
});

Deno.test("Structural - unexpected closing tag detected", () => {
  const r = ProvenHTML.checkTagNesting("</span>");
  assertEquals(r.TAG, "Error");
  assert(r._0.includes("Unexpected"));
});

Deno.test("Structural - well-formed HTML passes", () => {
  const r = ProvenHTML.checkTagNesting("<div><span><a>link</a></span></div>");
  assertEquals(r.TAG, "Ok");
});

// =========================================================================
// 7. Size bounds — content over 1MB is rejected by validate
// =========================================================================

Deno.test("Size bounds - content under 1MB accepted", () => {
  resetTracer();
  const html = "<p>" + "a".repeat(1000) + "</p>";
  const r = ProvenHTML.validate(html);
  assertEquals(r.TAG, "Ok");
});

Deno.test("Size bounds - content over 1MB rejected", () => {
  resetTracer();
  // 1MB = 1048576 bytes. Create content that exceeds this after sanitisation.
  const html = "<p>" + "x".repeat(1_048_580) + "</p>";
  const r = ProvenHTML.validate(html);
  assertEquals(r.TAG, "Error");
  assert(r._0.includes("1MB"));
});

// =========================================================================
// 8. Selector validity — valid selectors pass, invalid ones rejected
// =========================================================================

Deno.test("Selector validity - #app passes", () => {
  const r = ProvenSelector.validate("#app");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Selector validity - .my-class passes", () => {
  const r = ProvenSelector.validate(".my-class");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Selector validity - empty string rejected", () => {
  const r = ProvenSelector.validate("");
  assertEquals(r.TAG, "Error");
});

Deno.test("Selector validity - over 255 chars rejected", () => {
  const r = ProvenSelector.validate("#" + "a".repeat(256));
  assertEquals(r.TAG, "Error");
  assert(r._0.includes("maximum length"));
});

Deno.test("Selector validity - XSS in selector rejected", () => {
  const r = ProvenSelector.validate('<script>alert(1)</script>');
  assertEquals(r.TAG, "Error");
  assert(r._0.includes("invalid CSS characters"));
});

Deno.test("Selector validity - curly braces rejected", () => {
  const r = ProvenSelector.validate("div{color:red}");
  assertEquals(r.TAG, "Error");
  assert(r._0.includes("invalid CSS characters"));
});
