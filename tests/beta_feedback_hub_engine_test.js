// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * BetaFeedbackHubEngine Tests — default state, tab labels, category/priority/
 * sentiment/status labels, counting, filtering, and net votes.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  categoryLabel,
  priorityLabel,
  sentimentLabel,
  statusLabel,
  countByCategory,
  countBySentiment,
  filterEntries,
  netVotes,
} from "../src/core/BetaFeedbackHubEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.entries.length, 0);
  assertEquals(defaultState.filter, "");
  assertEquals(defaultState.sortByUpvotes, false);
  assertEquals(defaultState.submitting, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabInbox"), "Inbox");
  assertEquals(tabLabel("TabTriaged"), "Triaged");
  assertEquals(tabLabel("TabSentiment"), "Sentiment");
  assertEquals(tabLabel("TabSubmit"), "Submit");
  assertEquals(tabLabel("TabAnalytics"), "Analytics");
});

// -- allTabs --

Deno.test("allTabs contains all five tabs", () => {
  assertEquals(allTabs.length, 5);
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("FeedbackBug"), "Bug");
  assertEquals(categoryLabel("FeedbackFeature"), "Feature Request");
  assertEquals(categoryLabel("FeedbackBalance"), "Balance");
  assertEquals(categoryLabel("FeedbackUx"), "UX");
  assertEquals(categoryLabel("FeedbackPerformance"), "Performance");
  assertEquals(categoryLabel("FeedbackOther"), "Other");
});

// -- priorityLabel --

Deno.test("priorityLabel returns correct labels", () => {
  assertEquals(priorityLabel("FeedbackCritical"), "Critical");
  assertEquals(priorityLabel("FeedbackHigh"), "High");
  assertEquals(priorityLabel("FeedbackMedium"), "Medium");
  assertEquals(priorityLabel("FeedbackLow"), "Low");
});

// -- sentimentLabel --

Deno.test("sentimentLabel returns correct labels", () => {
  assertEquals(sentimentLabel("SentimentPositive"), "Positive");
  assertEquals(sentimentLabel("SentimentNeutral"), "Neutral");
  assertEquals(sentimentLabel("SentimentNegative"), "Negative");
  assertEquals(sentimentLabel("SentimentUnknown"), "Unknown");
});

// -- statusLabel --

Deno.test("statusLabel returns correct labels", () => {
  assertEquals(statusLabel("FeedbackNew"), "New");
  assertEquals(statusLabel("FeedbackTriaged"), "Triaged");
  assertEquals(statusLabel("FeedbackResolved"), "Resolved");
});

// -- countByCategory with empty array --

Deno.test("countByCategory returns 0 for empty array", () => {
  assertEquals(countByCategory([], "FeedbackBug"), 0);
});

// -- filterEntries with empty array --

Deno.test("filterEntries returns empty for empty array", () => {
  assertEquals(filterEntries([], "", undefined).length, 0);
});
