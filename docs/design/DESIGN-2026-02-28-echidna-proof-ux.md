# DESIGN: ECHIDNA Proof UX — Switchable Syntax, Visual Proof Builder, and SLM Advisory

**Date:** 2026-02-28
**Repo:** panll
**Author:** Jonathan D.A. Jewell
**Status:** Design exploration (pre-implementation)

## Context

With the mock ECHIDNA server in place (port 9000, `deno task mock:echidna`), PanLL's
ECHIDNA panel can now be tested end-to-end: sessions, tactics, suggestions, trust
display. The next question is: **how should the proof interaction feel?**

The current flow is text-in, text-out — the user types a goal string, picks a prover,
and clicks through tactic suggestions. This works for experts but creates a cliff for
everyone else. The following design explores three complementary approaches to make
ECHIDNA's proof engine accessible at multiple skill levels.

---

## Design Questions (from session dialogue)

These questions arose during the design session and are preserved verbatim because
they capture real user concerns that others will share:

> **Q1:** "We need a switchable syntax linter, and a specific interface for the
> solver, as well as the ability either to switch modes or use a generalised syntax
> language to handle these proofs."

> **Q2:** "Would adding an SLM to support this on top of that be helpful or harmful
> (or at least too risky) so that the full power of ECHIDNA can be leveraged?"

> **Q3:** "Maybe a bit like a mix of the CI/CD look for things to pass through and
> you can assemble proof chains and it will notice what is missing on the journey and
> off the back and forward propagation, constraint propagation, and how/why queries?"

> **Q4:** "Perhaps that page can be switchable too with a logical notation page that
> does a similar thing with the wider suite of logical notations for support here."

> **Q5:** "So they can enter into that box with linter support and suggested
> corrections, but if they are getting more sophisticated, switch to the logic and
> proofs subsystem of panes."

> **Q6:** "Something like Blockly but for solvers would be fantastic."

> **Q7:** "Can we take things we learn here to the ReScript Evangeliser, and vice
> versa? That's much more prioritised for pedagogy/heutagogy, but I think the lessons
> might be valuable."

> **Q8:** "As I ask questions can you use these as prompts to create the documentary
> elements of the repo and the tool. Not the only stuff but questions I have might be
> important too for others."

---

## Three-Layer Proof Interface

### Layer 1: Visual Proof Builder ("Proof Pipeline")

**Inspiration:** CI/CD pipeline visualisations + Blockly

A drag-and-drop canvas where proof obligations flow left-to-right through stages,
like a CI pipeline. Each stage is a proof step; connectors show dependencies.

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Goal        │────▶│  Tactic 1    │────▶│  Subgoal A   │──┐
│  ∀n, n+0=n  │     │  induction n │     │  0+0=0       │  │  ┌──────────┐
└─────────────┘     └──────────────┘     └──────────────┘  ├─▶│  QED ✓   │
                                          ┌──────────────┐  │  └──────────┘
                                          │  Subgoal B   │──┘
                                          │  S n+0=S n   │
                                          └──────────────┘
```

**What the pipeline shows:**
- **Green stages:** Obligations discharged (goals solved)
- **Amber stages:** In progress (goal exists, no tactic applied yet)
- **Red stages:** Failed/stuck (tactic didn't close the goal)
- **Dashed connectors:** Missing steps the system detected via constraint propagation
- **Hovering a stage:** Shows the proof context (hypotheses, goal, available lemmas)

**Constraint propagation / gap detection:**
- Forward propagation: "If you solve subgoal A, these lemmas become available"
- Backward propagation: "To close this goal, you need one of: [tactic list]"
- **How queries:** "How did this goal arise?" → traces back through the pipeline
- **Why queries:** "Why is this step needed?" → shows what depends on it downstream

**Block types (Blockly-inspired palette):**

| Block Category | Examples | Colour |
|----------------|----------|--------|
| Introduction   | `intro`, `intros`, `assume` | Blue |
| Elimination    | `destruct`, `inversion`, `case` | Orange |
| Rewriting      | `rewrite`, `simpl`, `unfold` | Green |
| Induction      | `induction`, `fix`, `cofix` | Purple |
| Automation     | `auto`, `omega`, `ring`, `decide` | Teal |
| SMT            | `check-sat`, `assert`, `simplify` | Grey |
| Custom         | User-defined tactics/lemmas | Yellow |

Users can drag blocks from the palette onto pipeline stages, or click suggestion
chips that ECHIDNA's ML advisor generates.

### Layer 2: Syntax-Aware Text Editor (Switchable Linter)

For users who outgrow the visual builder, a text editor with switchable syntax
modes. The linter adapts to the active prover's language:

**Supported syntax modes:**

| Mode | Language | Use Case |
|------|----------|----------|
| Coq/Gallina | `Theorem`, `Proof`, `Qed` | Interactive theorem proving |
| Lean 4 | `theorem`, `by`, `simp` | Modern ITP |
| Isabelle/Isar | `lemma`, `proof`, `qed` | Structured proofs |
| SMT-LIB 2 | `(assert ...)`, `(check-sat)` | SAT/SMT solving |
| Agda | Unicode, mixfix | Dependently typed |
| PanLL-Universal | See below | Cross-prover notation |

**PanLL-Universal syntax** is a generalised notation that translates to any backend:

```
-- PanLL-Universal
goal: ∀ n : Nat, n + 0 = n
proof:
  by induction on n
  case zero:
    simplify → done
  case succ(n'):
    simplify → done
```

The linter provides:
- **Real-time error highlighting** with prover-specific diagnostics
- **Suggested corrections** (red squiggle → click to fix)
- **Auto-completion** for tactic names, lemma names, identifiers
- **Hover documentation** showing tactic signatures and examples
- **Switch mode button** in toolbar — changes syntax highlighting + linter rules

### Layer 3: Logical Notation Page (Switchable)

A dedicated page (switchable from the proof builder) for working with formal logical
notation directly — propositional logic, first-order logic, higher-order logic,
linear logic, modal logic, etc.

**Notation palettes:**

| Logic | Connectives | Quantifiers |
|-------|-------------|-------------|
| Propositional | ∧ ∨ ¬ → ↔ ⊤ ⊥ | — |
| First-Order | ∧ ∨ ¬ → ↔ | ∀ ∃ |
| Higher-Order | + type constructors | ∀ ∃ λ Π Σ |
| Linear | ⊗ ⅋ ! ? ⊕ & | ∀ ∃ |
| Modal | □ ◇ | — |
| Temporal | ○ □ ◇ U W | — |

Users can **click symbols** from the palette to insert them, or use ASCII fallbacks
(`/\` for ∧, `\/` for ∨, `forall` for ∀, etc.). The page can render the same proof
in multiple notation styles simultaneously for learning.

---

## Progressive Sophistication Model

The key insight (shared with the ReScript Evangeliser) is **progressive disclosure**:

```
┌─────────────────────────────────────────────────────┐
│  Level 1: Visual Proof Builder (Blockly-style)      │
│  → Drag blocks, see pipeline, click suggestions     │
│  → No syntax knowledge required                     │
├─────────────────────────────────────────────────────┤
│  Level 2: Syntax Editor (with linter + corrections) │
│  → Type proof scripts with full IDE support         │
│  → Switchable syntax mode per prover                │
├─────────────────────────────────────────────────────┤
│  Level 3: Logical Notation (formal logic symbols)   │
│  → Work directly with logical connectives           │
│  → Multi-logic palette (propositional → linear)     │
├─────────────────────────────────────────────────────┤
│  Level 4: Raw Prover REPL (expert mode)             │
│  → Direct access to Coq/Lean/Z3 via ECHIDNA        │
│  → Full tactic language, no guardrails              │
└─────────────────────────────────────────────────────┘
```

Users can switch freely between levels. The system remembers which level each user
prefers and nudges them upward when they demonstrate readiness (e.g., "You've used
`induction` 5 times via blocks — want to try typing it directly?").

---

## SLM Analysis: Helpful, Harmful, or Too Risky?

### What an SLM Would Do

A Small Language Model (1-3B parameters, e.g., Phi-3-mini, TinyLlama, or a
fine-tuned CodeGemma) would sit between the user and ECHIDNA to:

1. **Translate natural language to tactic scripts:** "prove this by splitting on n" → `induction n`
2. **Explain proof states in plain English:** "You have two remaining goals..."
3. **Suggest next steps based on partial proofs:** Context-aware tactic ranking
4. **Fix syntax errors before sending to the prover:** Pre-flight correction

### Verdict: HELPFUL — but with strict guardrails

**Benefits:**
- Dramatically lowers the entry barrier (natural language → formal proof)
- Handles the "PanLL-Universal → Coq/Lean" translation reliably
- Can power the linter's suggested corrections
- Explains proof failures in accessible language
- Small enough to run locally (no cloud dependency, offline-first)

**Risks and mitigations:**

| Risk | Severity | Mitigation |
|------|----------|------------|
| SLM hallucinates a tactic | Medium | ECHIDNA validates every tactic server-side; hallucinations just fail gracefully |
| SLM suggests unsound proof steps | Low | The prover is the ground truth, not the SLM; suggestions are checked |
| SLM gives false confidence | Medium | Trust display shows ECHIDNA's verification, not SLM's confidence |
| Model size / latency | Low | 1-3B models run in <100ms on modern hardware |
| Maintenance burden | Medium | Use an off-the-shelf model with LoRA fine-tuning, not a custom architecture |

**The key insight:** The SLM is an *input translator* and *output explainer*, never
an *oracle*. ECHIDNA's provers remain the source of truth. The SLM's output is always
validated against the formal backend before being shown to the user. This is
fundamentally different from using an LLM for code generation where hallucinations
compile and run — here, hallucinations are caught by the type checker / proof engine.

**Architecture:**
```
User input (natural language / visual blocks / syntax)
    │
    ▼
┌─────────┐     ┌──────────┐     ┌──────────────┐
│  SLM    │────▶│ ECHIDNA  │────▶│ Prover       │
│ (local) │     │ (API)    │     │ (Coq/Lean/Z3)│
└─────────┘     └──────────┘     └──────────────┘
    │                                    │
    │◀───────────────────────────────────┘
    │  (proof state / errors / success)
    ▼
User-facing explanation + trust display
```

---

## Cross-Pollination with ReScript Evangeliser

The ReScript Evangeliser and PanLL's ECHIDNA proof UX share deep structural parallels:

| Concept | ReScript Evangeliser | ECHIDNA Proof UX |
|---------|---------------------|------------------|
| Progressive disclosure | RAW → FOLDED → GLYPHED → WYSIWYG | Visual → Syntax → Logic → REPL |
| Celebrate-don't-shame | "Your JS is already doing X well!" | "Your proof attempt is on track — 2 of 4 goals solved" |
| Visual symbols (Glyphs) | Makaton-inspired: 🛡️ 🔄 🧩 | Proof pipeline blocks: induction, rewrite, auto |
| Linter with corrections | JS → ReScript suggested rewrites | Prover-syntax errors → suggested fixes |
| Confidence scoring | Pattern match confidence (0-1) | Tactic suggestion confidence (0-1) |
| Gamification | Achievement badges, learning progress | Proof completion badges, trust levels |
| SLM potential | "What does this JS pattern do?" | "What tactic should I try next?" |
| Narrative system | celebrate/minimize/better/safety | goal/context/suggestion/explanation |

**Transferable lessons:**

1. **From Evangeliser → ECHIDNA:** The narrative template system (celebrate/minimize/
   show-better) maps directly to proof feedback. Instead of "Your JavaScript already
   handles null checks — ReScript's Option makes them automatic", write "Your proof
   attempt already handles the base case — induction will handle the rest automatically."

2. **From ECHIDNA → Evangeliser:** The CI/CD pipeline view could teach JavaScript →
   ReScript transformation as a pipeline: "Your code flows through these stages of
   improvement." The Blockly-style block palette could let beginners drag ReScript
   patterns onto their JS code rather than typing.

3. **Shared infrastructure:** Both need a switchable syntax linter, confidence-scored
   suggestions, progressive difficulty, and potentially an SLM layer. Building this
   as a shared library (in ReScript, naturally) would benefit both.

---

## Implementation Phases

### Phase A: Mock server + demo data (THIS SESSION — DONE)
- [x] Mock ECHIDNA on port 9000
- [x] Demo neural tokens in Pane-N
- [x] All tests passing (19 Rust, 121 Deno, ReScript clean)

### Phase B: Visual Proof Builder (pipeline view)
- [ ] Pipeline canvas component in ReScript/JSX
- [ ] Block palette with drag-drop
- [ ] Proof state → pipeline graph conversion
- [ ] Gap detection (constraint propagation)
- [ ] How/why query hover popups

### Phase C: Switchable Syntax Linter
- [ ] Syntax mode selector in toolbar
- [ ] PanLL-Universal notation spec
- [ ] Per-prover syntax highlighting rules
- [ ] Error → suggested correction engine
- [ ] Coq, Lean, SMT-LIB, Agda mode definitions

### Phase D: Logical Notation Page
- [ ] Symbol palette component
- [ ] Multi-logic rendering (propositional, FOL, HOL, linear, modal)
- [ ] ASCII fallback input
- [ ] Notation-switching toggle

### Phase E: SLM Integration (optional, deferred)
- [ ] Model selection + local hosting (Deno/WASM or sidecar)
- [ ] NL → tactic translation pipeline
- [ ] Proof state → plain English explainer
- [ ] Guardrails: SLM output always validated against ECHIDNA

---

## Open Questions

1. **Should PanLL-Universal be a new micro-language or a subset of an existing one?**
   Candidates: Lean 4 syntax (already clean), a structured markdown, or a custom DSL.

2. **Where does the block palette live in PanLL's three-pane model?** It could be a
   Pane-L feature (symbolic/structural) or a new sub-pane within the ECHIDNA panel.

3. **Should the SLM be a Tauri sidecar (Rust-hosted GGUF) or a WASM module?** Sidecar
   is simpler but adds binary size; WASM runs in the webview but has memory limits.

4. **How much of the switchable linter infrastructure can be shared with the ReScript
   Evangeliser?** Both need mode-switching, confidence scoring, and suggested corrections.

---

## References

- ReScript Evangeliser: `developer-ecosystem/rescript-ecosystem/packages/tooling/evangeliser/`
- ECHIDNA mock server: `panll/scripts/mock-echidna.ts`
- PanLL Model types: `panll/src/Model.res` (lines 263-373)
- ECHIDNA update handlers: `panll/src/Update.res` (lines 700-1150)
