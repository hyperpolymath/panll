// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ProtocolBridgeEngine Tests — default state, tab labels, channel counting,
 * latency averaging, and protocol rule formatting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countConnectedChannels,
  countChannelsByStatus,
  channelStatusLabel,
  averageLatency,
  averageSampleLatency,
  countExceededThreshold,
  formatProtocolRule,
} from "../src/core/ProtocolBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.channels.length, 0);
  assertEquals(defaultState.messageLog.length, 0);
  assertEquals(defaultState.latencySamples.length, 0);
  assertEquals(defaultState.protocolRules.length, 0);
  assertEquals(defaultState.connected, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Channels"), "Channels");
  assertEquals(tabLabel("Messages"), "Messages");
  assertEquals(tabLabel("Latency"), "Latency");
  assertEquals(tabLabel("Rules"), "Rules");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- channelStatusLabel --

Deno.test("channelStatusLabel returns correct labels", () => {
  assertEquals(channelStatusLabel("ChannelActive"), "Active");
  assertEquals(channelStatusLabel("ChannelIdle"), "Idle");
  assertEquals(channelStatusLabel("ChannelDegraded"), "Degraded");
  assertEquals(channelStatusLabel("ChannelDisconnected"), "Disconnected");
  assertEquals(channelStatusLabel("ChannelError"), "Error");
});

// -- countConnectedChannels with empty array --

Deno.test("countConnectedChannels returns 0 for empty array", () => {
  assertEquals(countConnectedChannels([]), 0);
});

// -- averageLatency with empty array --

Deno.test("averageLatency returns 0 for empty array", () => {
  assertEquals(averageLatency([]), 0.0);
});

// -- averageSampleLatency with empty array --

Deno.test("averageSampleLatency returns 0 for empty array", () => {
  assertEquals(averageSampleLatency([]), 0.0);
});

// -- countExceededThreshold with empty array --

Deno.test("countExceededThreshold returns 0 for empty array", () => {
  assertEquals(countExceededThreshold([]), 0);
});
