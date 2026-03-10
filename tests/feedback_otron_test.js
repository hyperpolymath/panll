// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * FeedbackOTron Tests — report type labels, colours, string conversion,
 * and view function exports.
 */

import { assertEquals, assert, assertExists } from "jsr:@std/assert";
import {
  getReportLabel,
  reportTypeToString,
  getReportColour,
  renderReportTypeButton,
  renderBojContext,
  renderFeedbackForm,
  renderTriggerButton,
  view,
} from "../src/components/FeedbackOTron.res.js";

// -- getReportLabel --

Deno.test("getReportLabel returns human-readable labels for all types", () => {
  assertEquals(getReportLabel("Hallucination"), "Hallucination");
  assertEquals(getReportLabel("ConstraintViolation"), "Constraint Violation");
  assertEquals(getReportLabel("PerformanceIssue"), "Performance Issue");
  assertEquals(getReportLabel("UXFriction"), "UX Friction");
  assertEquals(getReportLabel("FeatureRequest"), "Feature Request");
});

// -- reportTypeToString --

Deno.test("reportTypeToString returns string identifiers for all types", () => {
  assertEquals(reportTypeToString("Hallucination"), "Hallucination");
  assertEquals(reportTypeToString("ConstraintViolation"), "ConstraintViolation");
  assertEquals(reportTypeToString("PerformanceIssue"), "PerformanceIssue");
  assertEquals(reportTypeToString("UXFriction"), "UXFriction");
  assertEquals(reportTypeToString("FeatureRequest"), "FeatureRequest");
});

// -- getReportColour --

Deno.test("getReportColour returns Tailwind bg classes", () => {
  assertEquals(getReportColour("Hallucination"), "bg-red-600");
  assertEquals(getReportColour("ConstraintViolation"), "bg-amber-600");
  assertEquals(getReportColour("PerformanceIssue"), "bg-orange-600");
  assertEquals(getReportColour("UXFriction"), "bg-yellow-600");
  assertEquals(getReportColour("FeatureRequest"), "bg-blue-600");
});

// -- view function export --

Deno.test("view function is exported and callable", () => {
  assertExists(view);
  assertEquals(typeof view, "function");
});

Deno.test("renderTriggerButton is exported and callable", () => {
  assertExists(renderTriggerButton);
  assertEquals(typeof renderTriggerButton, "function");
});

Deno.test("renderFeedbackForm is exported and callable", () => {
  assertExists(renderFeedbackForm);
  assertEquals(typeof renderFeedbackForm, "function");
});

// -- view returns trigger button when no feedback pending --

Deno.test("view returns trigger button vdom when feedbackPending is undefined", () => {
  const bojState = {
    connected: false,
    cartridges: [],
    umoja: { active: false, peers: [] },
    invokeResult: undefined,
    error: undefined,
  };
  const result = view(undefined, undefined, "Hallucination", bojState);
  assertExists(result);
  // The result should be a TEA virtual DOM node (an object with tag/attrs/children)
  assertEquals(typeof result, "object");
});

// -- renderBojContext produces vdom --

Deno.test("renderBojContext produces vdom for disconnected state", () => {
  const bojState = {
    connected: false,
    cartridges: [],
    umoja: { active: false, peers: [] },
    invokeResult: undefined,
    error: undefined,
  };
  const result = renderBojContext(bojState);
  assertExists(result);
  assertEquals(typeof result, "object");
});

Deno.test("renderBojContext handles connected state with cartridges", () => {
  const bojState = {
    connected: true,
    cartridges: [
      { name: "core", loaded: true },
      { name: "net", loaded: false },
    ],
    umoja: { active: true, peers: ["peer1", "peer2"] },
    invokeResult: { success: true, durationMs: 42 },
    error: undefined,
  };
  const result = renderBojContext(bojState);
  assertExists(result);
});
