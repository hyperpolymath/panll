// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * TentaclesEngine Tests — colour mappings, label helpers, agent lifecycle,
 * OODA phase progression, array queries, and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  tentacleHex,
  tentacleTextClass,
  tentacleBorderClass,
  tentacleBgClass,
  tentacleLabel,
  tentacleShortLabel,
  tentacleRole,
  stageLabel,
  oodaLabel,
  oodaIcon,
  categoryLabel,
  allTentacles,
  allCategories,
  allStages,
  defaultPersonality,
  defaultNames,
  tentacleTeaches,
  initAgent,
  agentDisplayName,
  findAgent,
  updateAgent,
  busyCount,
  errorCount,
  totalConstraints,
  totalResults,
  nextPhase,
  cycleComplete,
  advancePhase,
  startTask,
  failTask,
  init,
} from "../src/core/TentaclesEngine.res.js";

// -- tentacleHex --

Deno.test("tentacleHex returns correct hex for each tentacle", () => {
  assertEquals(tentacleHex("Red"), "#E74C3C");
  assertEquals(tentacleHex("Orange"), "#E67E22");
  assertEquals(tentacleHex("Yellow"), "#F1C40F");
  assertEquals(tentacleHex("Green"), "#2ECC71");
  assertEquals(tentacleHex("Blue"), "#3498DB");
  assertEquals(tentacleHex("Indigo"), "#9B59B6");
  assertEquals(tentacleHex("Violet"), "#8E44AD");
});

// -- tentacleTextClass --

Deno.test("tentacleTextClass returns Tailwind text classes", () => {
  assertEquals(tentacleTextClass("Red"), "text-red-400");
  assertEquals(tentacleTextClass("Orange"), "text-orange-400");
  assertEquals(tentacleTextClass("Yellow"), "text-yellow-400");
  assertEquals(tentacleTextClass("Green"), "text-emerald-400");
  assertEquals(tentacleTextClass("Blue"), "text-blue-400");
  assertEquals(tentacleTextClass("Indigo"), "text-purple-400");
  assertEquals(tentacleTextClass("Violet"), "text-violet-400");
});

// -- tentacleBorderClass --

Deno.test("tentacleBorderClass returns Tailwind border classes", () => {
  assertEquals(tentacleBorderClass("Red"), "border-red-500");
  assertEquals(tentacleBorderClass("Orange"), "border-orange-500");
  assertEquals(tentacleBorderClass("Yellow"), "border-yellow-500");
  assertEquals(tentacleBorderClass("Green"), "border-emerald-500");
  assertEquals(tentacleBorderClass("Blue"), "border-blue-500");
  assertEquals(tentacleBorderClass("Indigo"), "border-purple-500");
  assertEquals(tentacleBorderClass("Violet"), "border-violet-500");
});

// -- tentacleBgClass --

Deno.test("tentacleBgClass returns Tailwind bg classes", () => {
  assertEquals(tentacleBgClass("Red"), "bg-red-900/20");
  assertEquals(tentacleBgClass("Orange"), "bg-orange-900/20");
  assertEquals(tentacleBgClass("Yellow"), "bg-yellow-900/20");
  assertEquals(tentacleBgClass("Green"), "bg-emerald-900/20");
  assertEquals(tentacleBgClass("Blue"), "bg-blue-900/20");
  assertEquals(tentacleBgClass("Indigo"), "bg-purple-900/20");
  assertEquals(tentacleBgClass("Violet"), "bg-violet-900/20");
});

// -- tentacleLabel --

Deno.test("tentacleLabel returns full descriptive labels", () => {
  assertEquals(tentacleLabel("Red"), "Red (Parser)");
  assertEquals(tentacleLabel("Orange"), "Orange (Concurrency)");
  assertEquals(tentacleLabel("Yellow"), "Yellow (Type System)");
  assertEquals(tentacleLabel("Green"), "Green (AST Architect)");
  assertEquals(tentacleLabel("Blue"), "Blue (Auditor)");
  assertEquals(tentacleLabel("Indigo"), "Indigo (Metaprogrammer)");
  assertEquals(tentacleLabel("Violet"), "Violet (Governance)");
});

// -- tentacleShortLabel --

Deno.test("tentacleShortLabel returns colour names", () => {
  assertEquals(tentacleShortLabel("Red"), "Red");
  assertEquals(tentacleShortLabel("Orange"), "Orange");
  assertEquals(tentacleShortLabel("Yellow"), "Yellow");
  assertEquals(tentacleShortLabel("Green"), "Green");
  assertEquals(tentacleShortLabel("Blue"), "Blue");
  assertEquals(tentacleShortLabel("Indigo"), "Indigo");
  assertEquals(tentacleShortLabel("Violet"), "Violet");
});

// -- tentacleRole --

Deno.test("tentacleRole returns compiler role descriptions", () => {
  assertEquals(tentacleRole("Red"), "Parser");
  assertEquals(tentacleRole("Orange"), "Concurrency Engine");
  assertEquals(tentacleRole("Yellow"), "Type System");
  assertEquals(tentacleRole("Green"), "AST Architect");
  assertEquals(tentacleRole("Blue"), "Auditor");
  assertEquals(tentacleRole("Indigo"), "Metaprogrammer");
  assertEquals(tentacleRole("Violet"), "Governance");
});

// -- stageLabel --

Deno.test("stageLabel returns stage names with age ranges", () => {
  assertEquals(stageLabel("Cuttle"), "Cuttle (8-12)");
  assertEquals(stageLabel("Squidlet"), "Squidlet (13-14)");
  assertEquals(stageLabel("Duet"), "Duet (15)");
  assertEquals(stageLabel("Octopus"), "Octopus (16+)");
});

// -- oodaLabel --

Deno.test("oodaLabel returns correct phase names", () => {
  assertEquals(oodaLabel("Observe"), "Observe");
  assertEquals(oodaLabel("Orient"), "Orient");
  assertEquals(oodaLabel("Decide"), "Decide");
  assertEquals(oodaLabel("Act"), "Act");
});

// -- oodaIcon --

Deno.test("oodaIcon returns bracketed letter glyphs", () => {
  assertEquals(oodaIcon("Observe"), "[O]");
  assertEquals(oodaIcon("Orient"), "[R]");
  assertEquals(oodaIcon("Decide"), "[D]");
  assertEquals(oodaIcon("Act"), "[A]");
});

// -- categoryLabel --

Deno.test("categoryLabel returns tab bar labels", () => {
  assertEquals(categoryLabel("AgentView"), "Agent");
  assertEquals(categoryLabel("Orchestra"), "Orchestra");
  assertEquals(categoryLabel("StageConfig"), "Stage");
  assertEquals(categoryLabel("Progress"), "Progress");
});

// -- allTentacles --

Deno.test("allTentacles has 7 entries in spectrum order", () => {
  assertEquals(allTentacles.length, 7);
  assertEquals(allTentacles, ["Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet"]);
});

Deno.test("allTentacles entries all have valid hex colours", () => {
  for (const id of allTentacles) {
    const hex = tentacleHex(id);
    assert(typeof hex === "string" && hex.startsWith("#"), `Missing hex for ${id}`);
  }
});

// -- allCategories --

Deno.test("allCategories has 4 entries", () => {
  assertEquals(allCategories.length, 4);
  assertEquals(allCategories, ["AgentView", "Orchestra", "StageConfig", "Progress"]);
});

// -- allStages --

Deno.test("allStages has 4 entries in order", () => {
  assertEquals(allStages.length, 4);
  assertEquals(allStages, ["Cuttle", "Squidlet", "Duet", "Octopus"]);
});

// -- defaultPersonality --

Deno.test("defaultPersonality returns valid personality for each tentacle", () => {
  for (const id of allTentacles) {
    const p = defaultPersonality(id);
    assert(typeof p.voice === "string" && p.voice.length > 0, `Missing voice for ${id}`);
    assert(typeof p.catchphrase === "string" && p.catchphrase.length > 0, `Missing catchphrase for ${id}`);
    assert(Array.isArray(p.encouragement) && p.encouragement.length > 0, `Missing encouragement for ${id}`);
    assert(Array.isArray(p.corrections) && p.corrections.length > 0, `Missing corrections for ${id}`);
    assert(Array.isArray(p.celebrations) && p.celebrations.length > 0, `Missing celebrations for ${id}`);
  }
});

// -- defaultNames --

Deno.test("defaultNames returns stage-specific names for each tentacle", () => {
  for (const id of allTentacles) {
    const n = defaultNames(id);
    assert(typeof n.cuttle === "string" && n.cuttle.length > 0, `Missing cuttle name for ${id}`);
    assert(typeof n.squidlet === "string" && n.squidlet.length > 0, `Missing squidlet name for ${id}`);
    assert(typeof n.duet === "string" && n.duet.length > 0, `Missing duet name for ${id}`);
    assert(typeof n.octopus === "string" && n.octopus.length > 0, `Missing octopus name for ${id}`);
  }
});

Deno.test("defaultNames Red returns expected values", () => {
  const n = defaultNames("Red");
  assertEquals(n.cuttle, "Ruby Cuttle");
  assertEquals(n.squidlet, "Scarlet Squidlet");
  assertEquals(n.duet, "Crimson Duet");
  assertEquals(n.octopus, "Red Octopus");
});

// -- tentacleTeaches --

Deno.test("tentacleTeaches returns non-empty topic arrays", () => {
  for (const id of allTentacles) {
    const topics = tentacleTeaches(id);
    assert(Array.isArray(topics) && topics.length > 0, `Missing topics for ${id}`);
  }
});

Deno.test("tentacleTeaches Red covers parsing topics", () => {
  const topics = tentacleTeaches("Red");
  assertEquals(topics, ["Tokenisation", "Grammars", "Syntax trees", "Error recovery"]);
});

// -- initAgent --

Deno.test("initAgent creates agent with correct defaults", () => {
  const agent = initAgent("Blue", "Cuttle");
  assertEquals(agent.id, "Blue");
  assertEquals(agent.stage, "Cuttle");
  assertEquals(agent.compilerRole, "Auditor");
  assertEquals(agent.currentPhase, "Observe");
  assertEquals(agent.busy, false);
  assertEquals(agent.currentTask, undefined);
  assertEquals(agent.lastError, undefined);
  assertEquals(agent.constraints.length, 0);
  assertEquals(agent.reasoning.length, 0);
  assertEquals(agent.results.length, 0);
});

Deno.test("initAgent assigns correct personality and names", () => {
  const agent = initAgent("Green", "Squidlet");
  assertEquals(agent.stage, "Squidlet");
  assertEquals(agent.personality.voice, defaultPersonality("Green").voice);
  assertEquals(agent.names.squidlet, "Emerald Squidlet");
});

// -- agentDisplayName --

Deno.test("agentDisplayName returns stage-appropriate name", () => {
  assertEquals(agentDisplayName(initAgent("Red", "Cuttle")), "Ruby Cuttle");
  assertEquals(agentDisplayName(initAgent("Red", "Squidlet")), "Scarlet Squidlet");
  assertEquals(agentDisplayName(initAgent("Red", "Duet")), "Crimson Duet");
  assertEquals(agentDisplayName(initAgent("Red", "Octopus")), "Red Octopus");
});

// -- findAgent --

Deno.test("findAgent returns matching agent", () => {
  const agents = [initAgent("Red", "Cuttle"), initAgent("Blue", "Cuttle")];
  const found = findAgent(agents, "Blue");
  assert(found !== undefined);
  assertEquals(found.id, "Blue");
});

Deno.test("findAgent returns undefined when not found", () => {
  const agents = [initAgent("Red", "Cuttle")];
  const found = findAgent(agents, "Violet");
  assertEquals(found, undefined);
});

// -- updateAgent --

Deno.test("updateAgent applies function to matching agent only", () => {
  const agents = [initAgent("Red", "Cuttle"), initAgent("Blue", "Cuttle")];
  const updated = updateAgent(agents, "Red", a => ({ ...a, busy: true }));
  assertEquals(updated[0].busy, true);
  assertEquals(updated[1].busy, false);
});

// -- busyCount --

Deno.test("busyCount counts busy agents", () => {
  const agents = [
    { ...initAgent("Red", "Cuttle"), busy: true },
    initAgent("Blue", "Cuttle"),
    { ...initAgent("Green", "Cuttle"), busy: true },
  ];
  assertEquals(busyCount(agents), 2);
});

Deno.test("busyCount returns 0 for no busy agents", () => {
  const agents = [initAgent("Red", "Cuttle"), initAgent("Blue", "Cuttle")];
  assertEquals(busyCount(agents), 0);
});

// -- errorCount --

Deno.test("errorCount counts agents with errors", () => {
  const agents = [
    { ...initAgent("Red", "Cuttle"), lastError: "some error" },
    initAgent("Blue", "Cuttle"),
  ];
  assertEquals(errorCount(agents), 1);
});

Deno.test("errorCount returns 0 when no errors", () => {
  const agents = [initAgent("Red", "Cuttle")];
  assertEquals(errorCount(agents), 0);
});

// -- totalConstraints --

Deno.test("totalConstraints sums constraints across agents", () => {
  const agents = [
    { ...initAgent("Red", "Cuttle"), constraints: ["a", "b"] },
    { ...initAgent("Blue", "Cuttle"), constraints: ["c"] },
  ];
  assertEquals(totalConstraints(agents), 3);
});

Deno.test("totalConstraints returns 0 for empty constraints", () => {
  const agents = [initAgent("Red", "Cuttle")];
  assertEquals(totalConstraints(agents), 0);
});

// -- totalResults --

Deno.test("totalResults sums results across agents", () => {
  const agents = [
    { ...initAgent("Red", "Cuttle"), results: ["x"] },
    { ...initAgent("Blue", "Cuttle"), results: ["y", "z"] },
  ];
  assertEquals(totalResults(agents), 3);
});

// -- nextPhase --

Deno.test("nextPhase cycles through OODA phases", () => {
  assertEquals(nextPhase("Observe"), "Orient");
  assertEquals(nextPhase("Orient"), "Decide");
  assertEquals(nextPhase("Decide"), "Act");
  assertEquals(nextPhase("Act"), "Observe");
});

// -- cycleComplete --

Deno.test("cycleComplete returns true only for Act->Observe transition", () => {
  assertEquals(cycleComplete("Act", "Observe"), true);
  assertEquals(cycleComplete("Observe", "Orient"), false);
  assertEquals(cycleComplete("Orient", "Decide"), false);
  assertEquals(cycleComplete("Decide", "Act"), false);
});

// -- advancePhase --

Deno.test("advancePhase moves agent to next OODA phase", () => {
  const agent = initAgent("Red", "Cuttle");
  const [updated, completed] = advancePhase(agent);
  assertEquals(updated.currentPhase, "Orient");
  assertEquals(completed, false);
});

Deno.test("advancePhase completes cycle at Act->Observe", () => {
  const agent = { ...initAgent("Red", "Cuttle"), currentPhase: "Act", busy: true, currentTask: "test" };
  const [updated, completed] = advancePhase(agent);
  assertEquals(updated.currentPhase, "Observe");
  assertEquals(completed, true);
  assertEquals(updated.busy, false);
  assertEquals(updated.currentTask, undefined);
});

Deno.test("advancePhase preserves busy state mid-cycle", () => {
  const agent = { ...initAgent("Red", "Cuttle"), currentPhase: "Orient", busy: true };
  const [updated, completed] = advancePhase(agent);
  assertEquals(updated.currentPhase, "Decide");
  assertEquals(completed, false);
  assertEquals(updated.busy, true);
});

// -- startTask --

Deno.test("startTask sets agent to busy at Observe phase", () => {
  const agent = initAgent("Red", "Cuttle");
  const started = startTask(agent, "parse tokens");
  assertEquals(started.busy, true);
  assertEquals(started.currentPhase, "Observe");
  assertEquals(started.currentTask, "parse tokens");
  assertEquals(started.lastError, undefined);
});

// -- failTask --

Deno.test("failTask stops agent and records error", () => {
  const agent = { ...initAgent("Red", "Cuttle"), busy: true, currentTask: "parse tokens" };
  const failed = failTask(agent, "syntax error");
  assertEquals(failed.busy, false);
  assertEquals(failed.currentTask, undefined);
  assertEquals(failed.lastError, "syntax error");
});

// -- init --

Deno.test("init creates state with 7 agents", () => {
  const state = init();
  assertEquals(state.agents.length, 7);
});

Deno.test("init sets selectedAgent to Red", () => {
  const state = init();
  assertEquals(state.selectedAgent, "Red");
});

Deno.test("init sets activeCategory to Orchestra", () => {
  const state = init();
  assertEquals(state.activeCategory, "Orchestra");
});

Deno.test("init sets globalStage to Cuttle", () => {
  const state = init();
  assertEquals(state.globalStage, "Cuttle");
});

Deno.test("init sets orchestraCompact to false", () => {
  const state = init();
  assertEquals(state.orchestraCompact, false);
});

Deno.test("init has empty pendingBroadcasts", () => {
  const state = init();
  assertEquals(state.pendingBroadcasts.length, 0);
});

Deno.test("init sets ffiConnected to false", () => {
  const state = init();
  assertEquals(state.ffiConnected, false);
});

Deno.test("init sets ffiLastCheck to 0.0", () => {
  const state = init();
  assertEquals(state.ffiLastCheck, 0.0);
});

Deno.test("init sets ffiError to undefined (None)", () => {
  const state = init();
  assertEquals(state.ffiError, undefined);
});

Deno.test("init agents are all at Cuttle stage", () => {
  const state = init();
  for (const agent of state.agents) {
    assertEquals(agent.stage, "Cuttle");
  }
});

Deno.test("init agents cover all 7 tentacle IDs", () => {
  const state = init();
  const ids = state.agents.map(a => a.id);
  assertEquals(ids, allTentacles);
});
