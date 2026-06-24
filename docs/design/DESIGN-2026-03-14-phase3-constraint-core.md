<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Revised Five-Phase Architecture Note

**PanLL / eNSAID / Phase-3 Constraint-Core Reframing**
**Date**: 2026-03-14
**Author**: Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
**Status**: Accepted

## Executive view

The original five phases still make sense, but Phase 3 is no longer just one stage among peers. It becomes the semantic core of the system.

That means the surrounding phases should be reinterpreted like this:

- Phase 1 builds the substrate the constraint engine needs
- Phase 2 captures satisfiable intent before code appears
- Phase 3 propagates, checks, and repairs obligations
- Phase 4 turns unsatisfied obligations into policy and gating
- Phase 5 makes the live constraint state legible to humans

So the architecture is still five phases, but it is now much more of a hub-and-spoke model centered on Phase 3.

## Impact summary

| Phase | Old role | New role | Impact | Change now? |
|-------|----------|----------|--------|-------------|
| 1 | infrastructure | semantic substrate | moderate/substantial | yes |
| 2 | creation-time checks | intent capture + satisfiability | moderate | yes |
| 3 | wiring checks | constraint propagation engine | major | yes |
| 4 | prevent half-baked panels | policy/gating over constraint state | small/moderate | later, lightly |
| 5 | audit visibility | operator-facing constraint observability | moderate | later, after 3 stabilises |

## Phase-by-phase restatement

### Phase 1 — Constraint Substrate

**Old meaning:** Pure infrastructure. Invisible, but everything depends on it.

**New meaning:** Build the language and machinery that make the later phases meaningful.

This phase now owns:

- contract vocabulary
- internal representation of panel obligations
- panel graph extraction hooks
- constraint kinds
- propagation machinery
- diagnostics model
- patch planning primitives

**Why it changes:** If Phase 3 becomes a compiler-like constraint engine, then Phase 1 cannot remain generic plumbing. It has to provide the semantic substrate for constraint evaluation.

**What must change now:**

- define the smallest viable contract vocabulary
- define invariant categories
- define dependency relationships between obligations
- define machine-readable diagnostic codes
- define repairability classes

**What can wait:**

- fancy DSL syntax
- advanced fixpoint machinery
- proof-style formalism
- rich visual graph tooling

**Judgment:** This is one of the two most important phases to revisit immediately.

### Phase 2 — Intent Capture and Satisfiability

**Old meaning:** Catch problems at creation time, the cheapest point to fix.

**New meaning:** Ensure that the thing being requested is coherent and satisfiable before generation or wiring begins.

This phase should now validate:

- incomplete contracts
- contradictory options
- missing required declarations
- impossible combinations
- under-specified panel definitions

**Why it changes:** Once constraints are first-class, creation-time checking stops being a bag of ad hoc heuristics and becomes front-loaded contract validation.

**What must change now:**

- shift from file-template validation to contract validation
- require explicit declaration of key obligations
- reject incoherent requests early
- emit Phase-3-compatible obligation records rather than bespoke warnings

**What can wait:**

- conversational authoring assistant niceties
- advanced "did you mean?" repair suggestions
- interactive constraint editing UI

**Judgment:** Needs meaningful reframing now, but not a radical rewrite.

### Phase 3 — Constraint Propagation and Wiring Realization

**Old meaning:** Catch wiring failures after files exist.

**New meaning:** Act as the constraint core of the entire system.

This phase should:

- ingest contract declarations
- infer repo facts
- propagate obligations
- identify bottlenecks
- distinguish root failures from downstream noise
- classify failures as repairable or non-repairable
- optionally synthesize safe repairs

**Why it changes:** This is where the "Theory of Constraints as first-class" idea lands properly.

Instead of merely reporting:

- missing route
- missing message
- missing test

it can report:

- primary bottleneck
- blocked downstream obligations
- constraint dependency chain
- minimum repair set

That is much more powerful than linting.

**What must change now:**

- redesign this phase around obligations, dependencies, and propagation
- define root-vs-derived failures
- define safe repair classes
- make it the single producer of canonical build/audit truth

**What can wait:**

- richer bespoke language
- advanced planner/repair synthesis
- formal solver backends
- multi-panel global optimisation

**Judgment:** This is the real redesign. It is the heart of the shift.

### Phase 4 — Completion Policy and Gating

**Old meaning:** Prevent half-baked panels.

**New meaning:** Translate constraint status into policy decisions.

Examples:

- do not register panel as live unless required obligations are satisfied
- do not merge unless minimum viability obligations are green
- allow experimental/draft mode under explicit exemption rules
- differentiate "exists," "wired," "viable," and "ship-ready"

**Why it changes:** A strong Phase 3 makes Phase 4 simpler. Phase 4 should not independently rediscover logic that Phase 3 already knows.

**What must change now:** Mostly wording and design intent:

- define gating thresholds
- define states like draft / experimental / viable / releasable
- define exemption and override semantics

**What can wait:**

- deep implementation work
- complex policy dashboards
- multi-role approval workflows

**Judgment:** This phase changes less than it first appears. It becomes a policy consumer, not a logic engine.

### Phase 5 — Audit and Operator Trust

**Old meaning:** Show the human audit results so they trust the bot.

**New meaning:** Expose the live state of the constraint system in human-usable form.

Instead of a flat pass/fail list, Phase 5 should show:

- active bottleneck
- unsatisfied obligations
- dependency chain
- repair suggestions
- repairability status
- confidence / health / completeness state
- what changed since last run

**Why it changes:** If Phase 3 becomes richer, Phase 5 gets richer too — but mostly as a presentation layer.

**What must change now:** Only enough to ensure the data model is anticipated:

- define what operators need to see
- define the trust states
- define the minimum useful report shape

**What can wait:**

- polished visual dashboard
- timeline/history views
- comparative runs
- embedded "operator cockpit" UI

**Judgment:** Needs reframing, but implementation can mostly wait until the Phase 3 data model settles.

## Recommended new wording for the five phases

### Phase 1 — Constraint Substrate

Build the internal language, graph model, and diagnostic vocabulary that make constraint-aware panel realization possible.

### Phase 2 — Intent Capture and Satisfiability

Catch incoherent, incomplete, or contradictory panel contracts before generation and wiring begin.

### Phase 3 — Constraint Propagation and Wiring Realization

Evaluate panel obligations against repo reality, identify bottlenecks and missing joins, and generate safe repairs where possible.

### Phase 4 — Completion Policy and Gating

Use constraint satisfaction status to block half-realized panels and define the thresholds for draft, viable, and releasable states.

### Phase 5 — Audit and Operator Trust

Make constraint state, bottlenecks, and repair outcomes visible enough that a human operator can trust the system.

## What should change first

### Change now

1. **Reword all five phases** — even before implementation. This aligns the mental model.
2. **Redesign Phase 3 as the semantic core** — this is the big move.
3. **Tighten Phase 1 around substrate, not generic plumbing** — without this, Phase 3 will sprawl or become ad hoc.
4. **Reframe Phase 2 around satisfiability** — prevents garbage from reaching the constraint engine.

### Change later

5. **Rebuild Phase 4 around policy thresholds** — likely smaller than feared.
6. **Rebuild Phase 5 around bottleneck visibility and trust** — important, but downstream of the core model.

## Practical risk assessment

- **Small risk:** Phase 4 and 5 become slightly misaligned if left untouched for a while.
- **Medium risk:** Phase 2 remains too template-centric and feeds weak intent into the new engine.
- **Biggest risk:** Phase 3 becomes clever but underspecified because Phase 1 did not provide a strong enough vocabulary.

That last one is the main trap.

## Strongest recommendation

Treat this as a controlled re-centering, not a wholesale rewrite.

That means:

- do not scrap the five-phase model
- do not redesign every phase equally
- do promote Phase 3 into the core
- do retool Phase 1 and 2 first
- do let Phase 4 and 5 become thinner consumers

**In one sentence:** You need moderate architectural changes around the edges, but only one true redesign in the middle.
