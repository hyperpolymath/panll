// SPDX-License-Identifier: MPL-2.0

/**
 * ReleaseManagerEngine Tests — labels, colours, formatting, default state
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  channelLabel,
  channelColour,
  platformLabel,
  allPlatforms,
  statusLabel,
  statusColour,
  formatSize,
  defaultState,
} from "../src/core/ReleaseManagerEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("ReleaseOverview"), "Overview");
  assertEquals(categoryLabel("ReleaseChangelog"), "Changelog");
  assertEquals(categoryLabel("ReleaseArtifacts"), "Artifacts");
  assertEquals(categoryLabel("ReleaseDistribution"), "Distribution");
});

// -- channelLabel / channelColour --

Deno.test("channelLabel returns correct strings", () => {
  assertEquals(channelLabel("ChannelDev"), "Dev");
  assertEquals(channelLabel("ChannelAlpha"), "Alpha");
  assertEquals(channelLabel("ChannelBeta"), "Beta");
  assertEquals(channelLabel("ChannelRC"), "Release Candidate");
  assertEquals(channelLabel("ChannelStable"), "Stable");
});

Deno.test("channelColour returns correct classes", () => {
  assertEquals(channelColour("ChannelDev"), "text-gray-400");
  assertEquals(channelColour("ChannelStable"), "text-emerald-400");
});

// -- platformLabel --

Deno.test("platformLabel returns correct strings", () => {
  assertEquals(platformLabel("PlatformWeb"), "Web");
  assertEquals(platformLabel("PlatformDesktopLinux"), "Linux");
  assertEquals(platformLabel("PlatformMobileIOS"), "iOS");
});

// -- allPlatforms --

Deno.test("allPlatforms has 6 entries", () => {
  assertEquals(allPlatforms.length, 6);
});

// -- statusLabel / statusColour --

Deno.test("statusLabel returns correct strings", () => {
  assertEquals(statusLabel("ReleaseDraft"), "Draft");
  assertEquals(statusLabel("ReleaseBuilding"), "Building...");
  assertEquals(statusLabel("ReleaseReady"), "Ready");
  assertEquals(statusLabel("ReleasePublished"), "Published");
  assertEquals(statusLabel({ _0: "OOM" }), "Failed: OOM");
});

Deno.test("statusColour returns correct classes", () => {
  assertEquals(statusColour("ReleaseDraft"), "text-gray-400");
  assertEquals(statusColour("ReleasePublished"), "text-emerald-400");
  assertEquals(statusColour({ _0: "err" }), "text-red-400");
});

// -- formatSize --

Deno.test("formatSize formats bytes", () => {
  assertEquals(formatSize(500), "500B");
});

Deno.test("formatSize formats kilobytes", () => {
  assertEquals(formatSize(2048), "2KB");
});

Deno.test("formatSize formats megabytes", () => {
  assertEquals(formatSize(5242880), "5MB");
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.activeCategory, "ReleaseOverview");
  assertEquals(defaultState.currentVersion, "0.0.0");
  assertEquals(defaultState.nextVersion, "0.1.0");
  assertEquals(defaultState.channel, "ChannelDev");
  assertEquals(defaultState.releases.length, 0);
  assertEquals(defaultState.autoChangelog, true);
  assertEquals(defaultState.signArtifacts, true);
  assertEquals(defaultState.loading, false);
});
