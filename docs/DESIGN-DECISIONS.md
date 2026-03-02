<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->

# PanLL Design Decisions

**Last updated: 2026-03-02**
**Living document — updated as decisions are made or revised**

## DD-001: eNSAID Is a Specification, PanLL Is an Implementation

**Date:** 2026-02-27
**Status:** Accepted
**Context:** Need to separate the idea from the tool so others can build competing implementations.

**Decision:** eNSAID (Environment for NeSy-Agentic Integrated Development) is a specification. PanLL is the reference implementation. The spec lives in its own repo with its own governance. PanLL claims `IMPLEMENTS eNSAID` and that claim is verifiable.

**Consequences:**
- Contributors contribute to the eNSAID ecosystem, not just PanLL
- Every panel written works with any compliant eNSAID environment
- Pattern: HTTP → Apache/Nginx/Caddy. SQL → Postgres/MySQL. LSP → every language server.
- If someone builds a better eNSAID, the idea survives

**The V for Vendetta Principle:** You can kill PanLL. You cannot kill the idea. Ideas are bulletproof.

---

## DD-002: Binary Star Architecture (Human-Machine Co-Orbit)

**Date:** 2026-01-15
**Status:** Accepted
**Context:** Traditional IDEs treat AI as subordinate tool. Need genuine co-working.

**Decision:** Model Human and Machine as Binary Star system — two gravitationally bound entities orbiting a shared Barycentre (the task). Three panels: Panel-L (Symbolic/Human constraints), Panel-N (Neural/Machine reasoning), Panel-W (World/Barycentre results). Neither Human nor Machine is primary.

**Consequences:**
- Operator sees Machine reasoning in real-time (Panel-N)
- Machine constrained by symbolic rules visible to both (Panel-L)
- Shared output space validates mutual understanding (Panel-W)
- Higher cognitive load initially, offset by Vexometer monitoring

---

## DD-003: The Elm Architecture (TEA) for State Management

**Date:** 2026-01-20
**Status:** Accepted
**Context:** Complex UI with 14 panels, cognitive governance, orbital tracking needs deterministic state.

**Decision:** Model-Update-View with Commands and Subscriptions. Single immutable model record. All state changes flow through typed messages. Custom TEA implementation extended for PanLL's needs.

**Technical detail:** The main `model` type composes all domain slices via `include` re-exports. Each panel has its own Model/Engine/Cmd/Component files following a proven 8-file pattern.

---

## DD-004: Panel Module Pattern (8 Files Per Panel)

**Date:** 2026-03-01
**Status:** Accepted
**Context:** Need a repeatable, consistent pattern for adding panels.

**Decision:** Every panel follows exactly 8 files:

| Layer | ReScript | Rust (if backend needed) |
|-------|----------|--------------------------|
| Types | `src/model/XModel.res` | `src-tauri/src/x/types.rs` |
| Engine | `src/core/XEngine.res` | — |
| Commands | `src/commands/XCmd.res` | `src-tauri/src/x/commands.rs` |
| Component | `src/components/X.res` | `src-tauri/src/x/mod.rs` |

Plus wiring into 5 global files: Msg.res, Model.res, Update.res, View.res, main.rs

**Consequences:**
- Panel Minter can generate this structure automatically
- Every panel is structurally identical — contributors know where everything is
- Engine files are pure functions (no side effects) — fully testable
- Cmd files handle Tauri IPC — all effects isolated

---

## DD-005: Three-Tier Panel Isolation (Native / Standard Pod / Hardened Pod)

**Date:** 2026-03-02
**Status:** Accepted
**Context:** Third-party panels could be malicious or poorly written. Core panels should run fast.

**Decision:** Three isolation tiers, selectable per panel via the Provisioner:

| Tier | Runtime | Security | Performance | Use Case |
|------|---------|----------|-------------|----------|
| **Native** | In-process (Tauri webview) | Full trust, hash-verified | Fastest | Core 14 panels |
| **Standard Pod** | Alpine + Podman container | Process isolation, network limited | Moderate overhead | Community panels, trusted |
| **Hardened Pod** | Stapeln + Chainguard image | Full Stapeln security stack, minimal attack surface | Higher overhead | Untrusted/experimental panels |

**Consequences:**
- Core panels default to Native (no container overhead)
- Community panels default to StandardPod
- Users can override in Provisioner Configurator tab
- Clean uninstall: delete the pod, everything goes
- Supply chain commitment: containers are not just security, they're reversibility

---

## DD-006: Qubes-Style Code Provenance Map

**Date:** 2026-03-02
**Status:** Accepted
**Context:** Need to show who wrote each line and how trustworthy it is.

**Decision:** Always-visible ambient trust surface (not a toggle). Parses git blame + Co-Authored-By headers. Fixed semantic colour meanings:

| Level | Colour | Meaning | Detection |
|-------|--------|---------|-----------|
| Verified | Green | Formally verified, proof-checked, no believe_me | Proof markers in commit |
| Human-Reviewed | Blue | Human author or human commit after AI | No co-author, or subsequent human commit |
| AI-Assisted | Amber | Co-authored, no subsequent human review | Co-Authored-By present, no later human commit |
| Unreviewed AI | Red | Pure AI, no human in chain | AI author, no human review |
| Unknown | Grey | Pre-git or no attribution | No blame data available |

**Key constraint:** Colours swap hues for accessibility palettes (4 palettes: Standard, Deuteranopia, Protanopia, High Contrast) but NEVER swap meanings. Green always means verified, regardless of the actual hue displayed.

**Hostile UX:** Unreviewed AI code gets pulsing red borders and increased visual friction. Users CAN suppress this, but the suppression action is itself visible ("pulled the smoke alarm battery").

---

## DD-007: Cognitive Governance Stack

**Date:** 2026-01-25
**Status:** Accepted
**Context:** Co-orbit increases cognitive load. Need automated monitoring.

**Decision:** Four interconnected governance systems:

1. **Anti-Crash Gate** — Circuit breaker between Panel-N output and Panel-W workspace. Every neural token validated against Panel-L constraints before reaching shared space.
2. **Vexometer** — Friction monitor tracking cancellations, corrections, dwell time. Index 0.0–1.0 triggers anti-inflammatory UI adjustments.
3. **Information Humidity** — UI density adapts to stress. High humidity (relaxed) = more detail. Low humidity (stressed) = essential info only.
4. **Orbital Drift Aura** — Ambient visual (background colour shift) indicating system stability. Visible without looking at any specific panel.

These feed each other: Feedback-O-Tron → Vexometer → Humidity → UI adaptation.

---

## DD-008: Accessibility as Core, Not Afterthought

**Date:** 2026-02-27
**Status:** Accepted
**Context:** Accessibility is usually bolted on after launch. PanLL should be different.

**Decision:** Accessibility is in the CORE infrastructure, not in individual panels:
- Panel Minter produces accessible panels by default (harder to make inaccessible than accessible)
- Every colour system ships with 4 accessibility palettes
- Every keyboard interaction works without a mouse
- Screen reader semantics (ARIA) in every component template
- Renamed broader concept to "information/cognitive ergonomics" (accessibility is a subset)

**The discipline covers:**
- Perceptual load management (how much information before overload)
- Cognitive friction reduction (Vexometer measures this)
- Task-flow preservation (panels don't interrupt flow)
- Multi-modal presentation (visual + auditory + haptic)
- Expertise scaffolding (novice → expert gradual complexity reveal)

---

## DD-009: Trust & Blame Separation

**Date:** 2026-02-27
**Status:** Accepted
**Context:** Third-party panels could be bad. PanLL shouldn't take the blame.

**Decision:** Two-tier trust model:

1. **PanLL Core is hash-locked** — TEA framework, Tea_Vdom, Tea_Html, panel switcher, HAR are content-hashed. If core hashes don't match: `CORE_HASH_MISMATCH`, instantly detectable. Idris2 ABI layer makes core provably correct.

2. **Panels are author-signed** — Each panel manifest: `author: <name>, signed: <key>`. PanLL doesn't approve third-party panels, just hosts them. Blame is cryptographically attributable.

**Result:** Complaint is never "PanLL is broken". Either "core hash is wrong" (tampered) or "this panel is rubbish" (author's signature proves it).

---

## DD-010: Panel Taxonomy (Cladistic Classification)

**Date:** 2026-03-02
**Status:** Accepted
**Context:** Growing panel catalogue needs organisation that invites contribution.

**Decision:** Linnaean/cladistic hierarchy with EMPTY BRANCHES visible:

| Level | Example |
|-------|---------|
| Kingdom | Development, Operations, Governance, Analysis |
| Phylum | Security, Languages, Databases, Infrastructure |
| Class | Static Analysis, Runtime Monitoring, Formal Verification |
| Order | Vulnerability Scanning, Compliance, Dependency Audit |
| Family | Web Security, Network Security, Supply Chain |
| Genus | Cloudflare Management, WordPress Hardening |
| Species | CloudGuard, Wharf |

Empty nodes include metadata (description, expected Panel-L/N/W mapping, suggested backend) — they're specification slots, not stubs. Contributors see gaps and naturally fill them.

---

## DD-011: Notepad++ Community as First Target

**Date:** 2026-03-02
**Status:** Accepted
**Context:** Need first adopter community that wants to extend, not replace.

**Decision:** Target the Notepad++ community first:
- Loyal, underserved users who know their tool is limited
- Not competing with VS Code's market
- Extension culture — they already think in plugins
- Metaphor: PanLL doesn't replace Notepad++ — it wraps around it. "The bionic Notepad++ user in a mech suit."

---

## DD-012: Feedback-O-Tron as Opinion Mining System

**Date:** 2026-03-02
**Status:** Proposed
**Context:** Simple feedback form is insufficient. Need structured sentiment analysis.

**Decision:** Expand Feedback-O-Tron into three-tier system:
1. **Panel Pulse** — Opinion mining that extracts structured sentiment from feedback
2. **Prioritisation engine** — Maps sentiment to panel development priority
3. **Reusable infrastructure** — Same system usable by any product, not just PanLL

Connects to cognitive governance: Feedback-O-Tron → Vexometer → Humidity → UI adaptation.

---

## DD-013: Triaxial Development Framework

**Date:** 2026-03-02
**Status:** Accepted
**Context:** Need a framework for prioritising development work across the ecosystem.

**Decision:** Three-axis scoring system:

**Axis 1 — Scope** (what is wanted):
- `must` (5) — Required for minimum viable
- `intend` (3) — Planned but deferrable
- `like` (1) — Nice to have

**Axis 2 — Maintenance** (type of work):
- `corrective` (5) — Fixing something broken
- `adaptive` (3) — Adapting to new requirements
- `perfective` (1) — Improving what works

**Axis 3 — Audit** (what gets checked):
- `systems` (5) — Core architecture review
- `compliance` (3) — Standards/policy check
- `effects` (1) — Impact assessment

Combined score guides priority: must+corrective+systems = 15 (do immediately), like+perfective+effects = 3 (backlog).

---

## DD-014: FOSS-First Funding Strategy

**Date:** 2026-03-02
**Status:** Accepted
**Context:** Need sustainable funding without compromising open source.

**Decision:** Everything is PMPL-1.0-or-later. Funding buys acceleration, not access. The pitch: "Is it really worth trying to compete with a crazy academic, or just give him the money?" The ecosystem is so far along it's cheaper to fund than to fork.

---

## DD-015: ReScript Technical Patterns

**Date:** 2026-03-02
**Status:** Accepted (standing reference)
**Context:** Lessons learned from building 107 ReScript files.

**Key patterns:**
- `Tea_Cmd.call(callbacks => { ... callbacks.enqueue(tagger(result)) ... })` for Tauri commands
- `@module("@tauri-apps/api/core") external invoke` for Tauri bindings
- `input(attrs, list{})` — Tea_Html input takes 2 args, not 1
- `Attrs.ariaHidden(true)` — takes bool, not string
- `Attrs.style("width", "50%")` — two args (key, value), not single string
- `List.fromArray` for array→list conversion
- No emoji literals in ReScript (use text like `[V]`, `[!]`)
- Type constraints in switch arms need parens: `(Installed: panelInstallStatus)`
- `exception` and `constraint` are reserved — use `domainExc` and `rule`

---

*Design decisions are numbered sequentially. Superseded decisions retain their number with status changed to "Superseded by DD-XXX".*
