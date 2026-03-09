// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ProvisionerEngine Tests — labels, colours, install status, portfolios, default state
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  isolationLabel,
  isolationShortLabel,
  isolationColour,
  installStatusLabel,
  installStatusColour,
  defaultState,
} from "../src/core/ProvisionerEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("Portfolios"), "Portfolios");
  assertEquals(categoryLabel("Configurator"), "Configurator");
  assertEquals(categoryLabel("Installed"), "Installed");
  assertEquals(categoryLabel("CustomPortfolio"), "Custom");
});

// -- isolationLabel --

Deno.test("isolationLabel returns correct strings", () => {
  assertEquals(isolationLabel("Native"), "Native (in-process)");
  assertEquals(isolationLabel("StandardPod"), "Standard Pod (Alpine)");
  assertEquals(isolationLabel("HardenedPod"), "Hardened Pod (Chainguard)");
});

// -- isolationShortLabel --

Deno.test("isolationShortLabel returns short forms", () => {
  assertEquals(isolationShortLabel("Native"), "Native");
  assertEquals(isolationShortLabel("StandardPod"), "Pod");
  assertEquals(isolationShortLabel("HardenedPod"), "Hardened");
});

// -- isolationColour --

Deno.test("isolationColour returns correct classes", () => {
  assertEquals(isolationColour("Native"), "text-green-400");
  assertEquals(isolationColour("StandardPod"), "text-blue-400");
  assertEquals(isolationColour("HardenedPod"), "text-purple-400");
});

// -- installStatusLabel --

Deno.test("installStatusLabel returns correct strings", () => {
  assertEquals(installStatusLabel("NotInstalled"), "Not installed");
  assertEquals(installStatusLabel("Installing"), "Installing...");
  assertEquals(installStatusLabel("Installed"), "Installed");
  assertEquals(installStatusLabel("Removing"), "Removing...");
  assertEquals(installStatusLabel({ _0: "disk full" }), "Failed: disk full");
});

// -- installStatusColour --

Deno.test("installStatusColour returns correct classes", () => {
  assertEquals(installStatusColour("NotInstalled"), "text-gray-500");
  assertEquals(installStatusColour("Installed"), "text-green-400");
  assertEquals(installStatusColour("Installing"), "text-amber-400");
  assertEquals(installStatusColour("Removing"), "text-amber-400");
  assertEquals(installStatusColour({ _0: "error" }), "text-red-400");
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.activeCategory, "Portfolios");
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.error, undefined);
  assertEquals(defaultState.filterText, "");
  assertEquals(defaultState.configs.length, 12);
  assertEquals(defaultState.installStatus.length, 12);
});
