// SPDX-License-Identifier: MPL-2.0

/**
 * SafeDOMCore Benchmarks — Deno.bench() performance tests
 *
 * Measures throughput of:
 *   - ProvenSelector.validate (selector validation)
 *   - ProvenHTML.regexSanitise / sanitise / checkTagNesting / validate
 *   - MountTracer record / entries / filterByPrefix
 *   - Full pipeline (validate selector + validate HTML)
 *   - Regex-only vs full pipeline comparison
 *
 * Run: deno bench tests/safedom_bench_test.js
 */

import {
  MountTracer,
  ProvenSelector,
  ProvenHTML,
} from "../src/core/SafeDOMCore.res.js";

// ---------------------------------------------------------------------------
// Payload generators
// ---------------------------------------------------------------------------

/** Generate a ~1KB HTML snippet with divs, spans, paragraphs. */
function generateMediumHTML() {
  const fragments = [];
  for (let i = 0; i < 20; i++) {
    fragments.push(
      `<div class="row-${i}"><span class="label">Item ${i}</span>` +
      `<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p></div>`
    );
  }
  return fragments.join("\n");
}

/** Generate a ~100KB HTML document from repeated section blocks. */
function generateLargeHTML() {
  const section = `<section class="block"><h2>Heading</h2>` +
    `<p>Paragraph with <strong>bold</strong> and <em>italic</em> text.</p>` +
    `<ul><li>Item A</li><li>Item B</li><li>Item C</li></ul></section>\n`;
  const repeats = Math.ceil(102400 / section.length);
  return `<div id="root">${section.repeat(repeats)}</div>`;
}

/** Generate deeply nested divs to the given depth. */
function generateDeepHTML(depth) {
  let html = "";
  for (let i = 0; i < depth; i++) html += `<div class="level-${i}">`;
  html += "leaf";
  for (let i = depth - 1; i >= 0; i--) html += "</div>";
  return html;
}

/** Generate N sibling divs at the same level. */
function generateWideHTML(count) {
  let html = "<div id=\"wide-root\">";
  for (let i = 0; i < count; i++) {
    html += `<div class="sibling-${i}">text</div>`;
  }
  html += "</div>";
  return html;
}

/** Generate a mixed payload: deep nesting + wide siblings + void elements. */
function generateMixedHTML() {
  let html = "<article>";
  // 20 deep chains, each with 10 siblings containing void elements
  for (let chain = 0; chain < 20; chain++) {
    html += `<section><div class="chain-${chain}"><div><div>`;
    for (let sib = 0; sib < 10; sib++) {
      html += `<p>Text <br><img src="x.png" alt="img"> end</p>`;
    }
    html += "</div></div></div></section>";
  }
  html += "</article>";
  return html;
}

// Pre-build payloads once so setup cost does not skew measurements
const SMALL_HTML = "<p>Hello</p>";
const MEDIUM_HTML = generateMediumHTML();
const LARGE_HTML = generateLargeHTML();
const XSS_PAYLOAD =
  `<div><script>alert(1)</script><img onerror=alert(1) src=x></div>`;
const SHALLOW_HTML = "<div><p>text</p></div>";
const DEEP_HTML = generateDeepHTML(50);
const WIDE_HTML = generateWideHTML(100);
const MIXED_HTML = generateMixedHTML();

const SIMPLE_SELECTOR = "#app";
const COMPLEX_SELECTOR = "div.container > span[data-id='123']:not(.hidden)";

// ---------------------------------------------------------------------------
// 1. Selector validation throughput
// ---------------------------------------------------------------------------

Deno.bench({
  name: "ProvenSelector.validate — simple selector (#app)",
  group: "selector-validation",
  fn() {
    ProvenSelector.validate(SIMPLE_SELECTOR);
  },
});

Deno.bench({
  name: "ProvenSelector.validate — complex selector (combinators + pseudo)",
  group: "selector-validation",
  fn() {
    ProvenSelector.validate(COMPLEX_SELECTOR);
  },
});

Deno.bench({
  name: "ProvenSelector.validate — reject empty string",
  group: "selector-validation",
  fn() {
    ProvenSelector.validate("");
  },
});

Deno.bench({
  name: "ProvenSelector.validate — reject special chars (< > { })",
  group: "selector-validation",
  fn() {
    ProvenSelector.validate("<div>{bad}</div>");
  },
});

// ---------------------------------------------------------------------------
// 2. HTML sanitisation throughput
// ---------------------------------------------------------------------------

Deno.bench({
  name: "regexSanitise — small HTML (~14 B)",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.regexSanitise(SMALL_HTML);
  },
});

Deno.bench({
  name: "regexSanitise — medium HTML (~1 KB)",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.regexSanitise(MEDIUM_HTML);
  },
});

Deno.bench({
  name: "regexSanitise — large HTML (~100 KB)",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.regexSanitise(LARGE_HTML);
  },
});

Deno.bench({
  name: "regexSanitise — XSS payload (script + onerror)",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.regexSanitise(XSS_PAYLOAD);
  },
});

Deno.bench({
  name: "sanitise (dual-layer) — small HTML",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.sanitise(SMALL_HTML);
  },
});

Deno.bench({
  name: "sanitise (dual-layer) — medium HTML (~1 KB)",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.sanitise(MEDIUM_HTML);
  },
});

Deno.bench({
  name: "sanitise (dual-layer) — large HTML (~100 KB)",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.sanitise(LARGE_HTML);
  },
});

Deno.bench({
  name: "sanitise (dual-layer) — XSS payload",
  group: "html-sanitisation",
  fn() {
    ProvenHTML.sanitise(XSS_PAYLOAD);
  },
});

// ---------------------------------------------------------------------------
// 3. Stack-based tag nesting validation
// ---------------------------------------------------------------------------

Deno.bench({
  name: "checkTagNesting — shallow (2 levels)",
  group: "tag-nesting",
  fn() {
    ProvenHTML.checkTagNesting(SHALLOW_HTML);
  },
});

Deno.bench({
  name: "checkTagNesting — deep (50 levels)",
  group: "tag-nesting",
  fn() {
    ProvenHTML.checkTagNesting(DEEP_HTML);
  },
});

Deno.bench({
  name: "checkTagNesting — wide (100 siblings)",
  group: "tag-nesting",
  fn() {
    ProvenHTML.checkTagNesting(WIDE_HTML);
  },
});

Deno.bench({
  name: "checkTagNesting — mixed (deep + wide + void elements)",
  group: "tag-nesting",
  fn() {
    ProvenHTML.checkTagNesting(MIXED_HTML);
  },
});

// ---------------------------------------------------------------------------
// 4. MountTracer overhead
// ---------------------------------------------------------------------------

Deno.bench({
  name: "MountTracer.record — 1000 entries",
  group: "mount-tracer",
  fn() {
    MountTracer.clear();
    for (let i = 0; i < 1000; i++) {
      MountTracer.record(`bench-event-${i % 10}`, `detail-${i}`);
    }
  },
});

Deno.bench({
  name: "MountTracer.entries — retrieve after 1000 records",
  group: "mount-tracer",
  fn(b) {
    // Setup: fill 1000 entries outside the timed region
    MountTracer.clear();
    for (let i = 0; i < 1000; i++) {
      MountTracer.record(`bench-event-${i % 10}`, `detail-${i}`);
    }
    b.start();
    MountTracer.entries();
    b.end();
  },
});

Deno.bench({
  name: "MountTracer.filterByPrefix — over 1000 entries",
  group: "mount-tracer",
  fn(b) {
    // Setup: fill 1000 entries outside the timed region
    MountTracer.clear();
    for (let i = 0; i < 1000; i++) {
      MountTracer.record(`bench-event-${i % 10}`, `detail-${i}`);
    }
    b.start();
    MountTracer.filterByPrefix("bench-event-5");
    b.end();
  },
});

// ---------------------------------------------------------------------------
// 5. Full pipeline (validate selector + sanitise + nesting check)
// ---------------------------------------------------------------------------

Deno.bench({
  name: "ProvenHTML.validate — clean small HTML (full pipeline)",
  group: "full-pipeline",
  fn() {
    ProvenHTML.validate(SMALL_HTML);
  },
});

Deno.bench({
  name: "ProvenHTML.validate — clean medium HTML (full pipeline)",
  group: "full-pipeline",
  fn() {
    ProvenHTML.validate(MEDIUM_HTML);
  },
});

Deno.bench({
  name: "ProvenHTML.validate — dirty XSS payload (full pipeline)",
  group: "full-pipeline",
  fn() {
    ProvenHTML.validate(XSS_PAYLOAD);
  },
});

Deno.bench({
  name: "ProvenHTML.validate — large clean HTML (full pipeline)",
  group: "full-pipeline",
  fn() {
    ProvenHTML.validate(LARGE_HTML);
  },
});

Deno.bench({
  name: "Full pipeline: selector + HTML validate (clean)",
  group: "full-pipeline",
  fn() {
    ProvenSelector.validate(SIMPLE_SELECTOR);
    ProvenHTML.validate(SMALL_HTML);
  },
});

Deno.bench({
  name: "Full pipeline: selector + HTML validate (dirty XSS)",
  group: "full-pipeline",
  fn() {
    ProvenSelector.validate(SIMPLE_SELECTOR);
    ProvenHTML.validate(XSS_PAYLOAD);
  },
});

// ---------------------------------------------------------------------------
// 6. Comparison: regex-only vs full pipeline
// ---------------------------------------------------------------------------

Deno.bench({
  name: "Regex-only — regexSanitise on medium HTML",
  group: "regex-vs-full",
  baseline: true,
  fn() {
    ProvenHTML.regexSanitise(MEDIUM_HTML);
  },
});

Deno.bench({
  name: "Full validate (sanitise + size + nesting) — medium HTML",
  group: "regex-vs-full",
  fn() {
    ProvenHTML.validate(MEDIUM_HTML);
  },
});

Deno.bench({
  name: "Nesting-only overhead — checkTagNesting on medium HTML",
  group: "regex-vs-full",
  fn() {
    ProvenHTML.checkTagNesting(MEDIUM_HTML);
  },
});

Deno.bench({
  name: "Regex-only — regexSanitise on large HTML",
  group: "regex-vs-full-large",
  baseline: true,
  fn() {
    ProvenHTML.regexSanitise(LARGE_HTML);
  },
});

Deno.bench({
  name: "Full validate (sanitise + size + nesting) — large HTML",
  group: "regex-vs-full-large",
  fn() {
    ProvenHTML.validate(LARGE_HTML);
  },
});

Deno.bench({
  name: "Nesting-only overhead — checkTagNesting on large HTML",
  group: "regex-vs-full-large",
  fn() {
    ProvenHTML.checkTagNesting(LARGE_HTML);
  },
});
