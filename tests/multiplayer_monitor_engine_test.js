// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * MultiplayerMonitorEngine Tests — categories, connections, filtering, latency
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  connectionLabel,
  connectionColour,
  filterPlayers,
  unresolvedDiffs,
  contestedLocks,
  averageLatency,
  defaultState,
} from "../src/core/MultiplayerMonitorEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("MultiplayerDashboard"), "Dashboard");
  assertEquals(categoryLabel("MultiplayerChannels"), "Channels");
  assertEquals(categoryLabel("MultiplayerStateDiff"), "State Diff");
  assertEquals(categoryLabel("MultiplayerLatency"), "Latency");
  assertEquals(categoryLabel("MultiplayerDeviceLocks"), "Device Locks");
});

// -- connectionLabel / connectionColour --

Deno.test("connectionLabel returns correct strings", () => {
  assertEquals(connectionLabel("WsDisconnected"), "Disconnected");
  assertEquals(connectionLabel("WsConnecting"), "Connecting...");
  assertEquals(connectionLabel("WsConnected"), "Connected");
  assertEquals(connectionLabel("WsReconnecting"), "Reconnecting...");
  assertEquals(connectionLabel({ _0: "timeout" }), "Error: timeout");
});

Deno.test("connectionColour returns correct classes", () => {
  assertEquals(connectionColour("WsDisconnected"), "text-gray-500");
  assertEquals(connectionColour("WsConnected"), "text-emerald-400");
  assertEquals(connectionColour("WsConnecting"), "text-amber-400");
  assertEquals(connectionColour({ _0: "x" }), "text-red-400");
});

// -- filterPlayers --

Deno.test("filterPlayers returns all when showing spectators", () => {
  const players = [{ isSpectator: false }, { isSpectator: true }];
  assertEquals(filterPlayers(players, true).length, 2);
});

Deno.test("filterPlayers excludes spectators when hidden", () => {
  const players = [{ isSpectator: false }, { isSpectator: true }];
  assertEquals(filterPlayers(players, false).length, 1);
});

// -- unresolvedDiffs --

Deno.test("unresolvedDiffs filters resolved diffs", () => {
  const diffs = [{ resolved: false }, { resolved: true }, { resolved: false }];
  assertEquals(unresolvedDiffs(diffs).length, 2);
});

// -- contestedLocks --

Deno.test("contestedLocks counts contested locks", () => {
  const locks = [
    { contestedBy: ["p2"] },
    { contestedBy: [] },
    { contestedBy: ["p3", "p4"] },
  ];
  assertEquals(contestedLocks(locks), 2);
});

// -- averageLatency --

Deno.test("averageLatency returns 0 for empty", () => {
  assertEquals(averageLatency([]), 0);
});

Deno.test("averageLatency computes average", () => {
  const players = [{ latencyMs: 10 }, { latencyMs: 20 }, { latencyMs: 30 }];
  assertEquals(averageLatency(players), 20);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.activeCategory, "MultiplayerDashboard");
  assertEquals(defaultState.wsConnection, "WsDisconnected");
  assertEquals(defaultState.players.length, 0);
  assertEquals(defaultState.autoReconnect, true);
  assertEquals(defaultState.showSpectators, true);
  assertEquals(defaultState.loading, false);
});
