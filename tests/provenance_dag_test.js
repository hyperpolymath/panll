// SPDX-License-Identifier: MPL-2.0

/**
 * Provenance DAG Tests — buildDag, ancestors, descendants, blastRadius,
 * dagNodeKindLabel, dagNodeKindColour.
 */

import { assertEquals, assert, assertExists } from "jsr:@std/assert";
import {
  buildDag,
  ancestors,
  descendants,
  blastRadius,
  dagNodeKindLabel,
  dagNodeKindColour,
} from "../src/core/ProvenanceEngine.res.js";

// -- Helper: create a file provenance entry --

function makeFileProv(filePath, overrides) {
  return {
    filePath,
    analysedAt: Date.now(),
    regions: [],
    summary: {
      totalLines: 100,
      verifiedLines: 0,
      humanReviewedLines: 80,
      aiAssistedLines: 10,
      unreviewedAiLines: 0,
      unknownLines: 10,
      authorCount: 1,
      coAuthorCount: 0,
      hasViolations: false,
      unsoundMarkers: 0,
      ...(overrides || {}),
    },
  };
}

// -- buildDag --

Deno.test("buildDag creates nodes from file provenance entries", () => {
  const files = [
    makeFileProv("src/main.res"),
    makeFileProv("src/utils.res"),
  ];
  const dag = buildDag(files);
  assertEquals(dag.nodes.length, 2);
  assertEquals(dag.roots.length, 2);
  assertEquals(dag.leaves.length, 2);
  assertEquals(dag.edges.length, 0);
});

Deno.test("buildDag assigns HumanReviewed trust when majority human", () => {
  const files = [makeFileProv("src/main.res", { humanReviewedLines: 60, totalLines: 100 })];
  const dag = buildDag(files);
  assertEquals(dag.nodes[0].trustLevel, "HumanReviewed");
});

Deno.test("buildDag assigns Verified trust when majority verified", () => {
  const files = [makeFileProv("src/proven.res", {
    verifiedLines: 60,
    humanReviewedLines: 20,
    totalLines: 100,
  })];
  const dag = buildDag(files);
  assertEquals(dag.nodes[0].trustLevel, "Verified");
});

Deno.test("buildDag assigns AiAssisted trust when majority AI-assisted", () => {
  const files = [makeFileProv("src/gen.res", {
    verifiedLines: 0,
    humanReviewedLines: 10,
    aiAssistedLines: 60,
    totalLines: 100,
  })];
  const dag = buildDag(files);
  assertEquals(dag.nodes[0].trustLevel, "AiAssisted");
});

Deno.test("buildDag assigns UnreviewedAi when unreviewed AI lines present", () => {
  const files = [makeFileProv("src/bot.res", {
    verifiedLines: 0,
    humanReviewedLines: 10,
    aiAssistedLines: 10,
    unreviewedAiLines: 5,
    totalLines: 100,
  })];
  const dag = buildDag(files);
  assertEquals(dag.nodes[0].trustLevel, "UnreviewedAi");
});

Deno.test("buildDag sets computedAt timestamp", () => {
  const before = Date.now();
  const dag = buildDag([makeFileProv("src/a.res")]);
  const after = Date.now();
  assert(dag.computedAt >= before);
  assert(dag.computedAt <= after);
});

// -- ancestors / descendants with edges --

function makeDagWithEdges() {
  // A -> B -> C chain
  return {
    nodes: [
      { id: "A", label: "A", kind: "SourceNode", trustLevel: "HumanReviewed", contentHash: "", createdAt: 0, verified: false },
      { id: "B", label: "B", kind: "BuildNode", trustLevel: "HumanReviewed", contentHash: "", createdAt: 0, verified: false },
      { id: "C", label: "C", kind: "DependencyNode", trustLevel: "HumanReviewed", contentHash: "", createdAt: 0, verified: false },
    ],
    edges: [
      { fromId: "A", toId: "B", edgeType: "DependsOn" },
      { fromId: "B", toId: "C", edgeType: "DependsOn" },
    ],
    roots: ["A"],
    leaves: ["C"],
    computedAt: Date.now(),
  };
}

Deno.test("ancestors of C returns B and A", () => {
  const dag = makeDagWithEdges();
  const anc = ancestors(dag, "C");
  assert(anc.includes("B"));
  assert(anc.includes("A"));
  assertEquals(anc.length, 2);
});

Deno.test("ancestors of A returns empty array (root node)", () => {
  const dag = makeDagWithEdges();
  const anc = ancestors(dag, "A");
  assertEquals(anc.length, 0);
});

Deno.test("descendants of A returns B and C", () => {
  const dag = makeDagWithEdges();
  const desc = descendants(dag, "A");
  assert(desc.includes("B"));
  assert(desc.includes("C"));
  assertEquals(desc.length, 2);
});

Deno.test("descendants of C returns empty array (leaf node)", () => {
  const dag = makeDagWithEdges();
  const desc = descendants(dag, "C");
  assertEquals(desc.length, 0);
});

// -- blastRadius --

Deno.test("blastRadius of A returns [1, 2] (1 direct, 2 transitive)", () => {
  const dag = makeDagWithEdges();
  const [direct, transitive] = blastRadius(dag, "A");
  assertEquals(direct, 1);
  assertEquals(transitive, 2);
});

Deno.test("blastRadius of C returns [0, 0] (leaf node)", () => {
  const dag = makeDagWithEdges();
  const [direct, transitive] = blastRadius(dag, "C");
  assertEquals(direct, 0);
  assertEquals(transitive, 0);
});

// -- dagNodeKindLabel --

Deno.test("dagNodeKindLabel maps all kinds", () => {
  assertEquals(dagNodeKindLabel("SourceNode"), "Source");
  assertEquals(dagNodeKindLabel("BuildNode"), "Build");
  assertEquals(dagNodeKindLabel("DependencyNode"), "Dependency");
  assertEquals(dagNodeKindLabel("ProofNode"), "Proof");
  assertEquals(dagNodeKindLabel("AttestationNode"), "Attestation");
});

// -- dagNodeKindColour --

Deno.test("dagNodeKindColour returns Tailwind text classes", () => {
  assert(dagNodeKindColour("SourceNode").startsWith("text-"));
  assert(dagNodeKindColour("BuildNode").startsWith("text-"));
  assert(dagNodeKindColour("DependencyNode").startsWith("text-"));
  assert(dagNodeKindColour("ProofNode").startsWith("text-"));
  assert(dagNodeKindColour("AttestationNode").startsWith("text-"));
});

Deno.test("dagNodeKindColour returns distinct colours", () => {
  const colours = new Set([
    dagNodeKindColour("SourceNode"),
    dagNodeKindColour("BuildNode"),
    dagNodeKindColour("DependencyNode"),
    dagNodeKindColour("ProofNode"),
    dagNodeKindColour("AttestationNode"),
  ]);
  assertEquals(colours.size, 5);
});
