// SPDX-License-Identifier: MPL-2.0

/**
 * ConnectionManager Tests — status transitions, predicates, labels, colours
 *
 * ReScript option<T>: Some(x) → x, None → undefined
 */

import { assertEquals } from "jsr:@std/assert";
import {
  startChecking,
  connectSuccess,
  connectFailure,
  disconnect,
  isConnected,
  hasError,
  errorMessage,
  statusLabel,
  statusColour,
} from "../src/core/ConnectionManager.res.js";

// -- State transitions --

Deno.test("startChecking transitions to ServiceChecking", () => {
  assertEquals(startChecking("ServiceDisconnected"), "ServiceChecking");
  assertEquals(startChecking("ServiceConnected"), "ServiceChecking");
});

Deno.test("connectSuccess transitions to ServiceConnected", () => {
  assertEquals(connectSuccess("ServiceChecking"), "ServiceConnected");
});

Deno.test("connectFailure transitions to ServiceError", () => {
  const result = connectFailure("ServiceChecking", "timeout");
  assertEquals(result.TAG, "ServiceError");
  assertEquals(result._0, "timeout");
});

Deno.test("disconnect transitions to ServiceDisconnected", () => {
  assertEquals(disconnect("ServiceConnected"), "ServiceDisconnected");
});

// -- Predicates --

Deno.test("isConnected returns true for ServiceConnected", () => {
  assertEquals(isConnected("ServiceConnected"), true);
});

Deno.test("isConnected returns false for other states", () => {
  assertEquals(isConnected("ServiceDisconnected"), false);
  assertEquals(isConnected("ServiceChecking"), false);
  assertEquals(isConnected({ TAG: "ServiceError", _0: "err" }), false);
});

Deno.test("hasError returns true for ServiceError", () => {
  assertEquals(hasError({ TAG: "ServiceError", _0: "fail" }), true);
});

Deno.test("hasError returns false for non-error states", () => {
  assertEquals(hasError("ServiceConnected"), false);
  assertEquals(hasError("ServiceDisconnected"), false);
  assertEquals(hasError("ServiceChecking"), false);
});

// -- errorMessage (option<string>: Some → value, None → undefined) --

Deno.test("errorMessage returns string for ServiceError", () => {
  const result = errorMessage({ TAG: "ServiceError", _0: "network down" });
  assertEquals(result, "network down");
});

Deno.test("errorMessage returns undefined for non-error states", () => {
  assertEquals(errorMessage("ServiceConnected"), undefined);
  assertEquals(errorMessage("ServiceDisconnected"), undefined);
});

// -- Labels --

Deno.test("statusLabel returns correct strings", () => {
  assertEquals(statusLabel("ServiceConnected"), "Connected");
  assertEquals(statusLabel("ServiceDisconnected"), "Disconnected");
  assertEquals(statusLabel("ServiceChecking"), "Checking...");
  assertEquals(
    statusLabel({ TAG: "ServiceError", _0: "timeout" }),
    "Error: timeout",
  );
});

// -- Colours --

Deno.test("statusColour returns Tailwind classes", () => {
  assertEquals(statusColour("ServiceConnected"), "text-emerald-400");
  assertEquals(statusColour("ServiceDisconnected"), "text-gray-500");
  assertEquals(statusColour("ServiceChecking"), "text-amber-400");
  assertEquals(
    statusColour({ TAG: "ServiceError", _0: "x" }),
    "text-red-400",
  );
});

// -- Full lifecycle --

Deno.test("full connection lifecycle", () => {
  let status = "ServiceDisconnected";
  assertEquals(isConnected(status), false);

  status = startChecking(status);
  assertEquals(statusLabel(status), "Checking...");

  status = connectSuccess(status);
  assertEquals(isConnected(status), true);
  assertEquals(statusLabel(status), "Connected");

  status = connectFailure(status, "server restarted");
  assertEquals(hasError(status), true);
  assertEquals(errorMessage(status), "server restarted");

  status = disconnect(status);
  assertEquals(isConnected(status), false);
  assertEquals(statusLabel(status), "Disconnected");
});
