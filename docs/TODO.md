<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->

# PanLL TODO

**Last updated: 2026-03-02**
**Tracking method: Triaxial scoring (Scope x Maintenance x Audit)**

## Scoring Key

Each item scored on three axes (1-5 each, max combined = 15):

- **Scope**: must (5) | intend (3) | like (1)
- **Maintenance**: corrective (5) | adaptive (3) | perfective (1)
- **Audit**: systems (5) | compliance (3) | effects (1)

## Done (Completed 2026-03-02)

- [x] Phase 0: Panel Switcher + PanelRegistry (unified navigation) — `f5e158f`
- [x] Phase 1: Git-Private-Farm panel (UI) — `f5e158f`
- [x] Phase 2: Gitbot-Fleet panel (UI) — `f1ac214`
- [x] Phase 3: Hypatia panel (UI) — `f1ac214`
- [x] Panel Minter (UI + Rust backend) — `f1ac214`
- [x] Reposystem panel (UI) — `f1ac214`
- [x] Aerie panel (UI) — `f1ac214`
- [x] Interfaces panel (UI) — `f1ac214`
- [x] Playgrounds panel (UI) — `f1ac214`
- [x] Palimpsest Plaza panel (UI) — `f5e158f`
- [x] CloudGuard panel (Phases 1-6) — `5ca225e`, `ae59aa1`, `c2dd783`
- [x] VAB panel (111 components, KSP aesthetic) — session 2026-03-01
- [x] Watcher infrastructure (Rust notify backend + ReScript commands) — `f1ac214`
- [x] Code Provenance Map (trust surface, 4 palettes, hostile UX) — `f1ac214`
- [x] Provisioner (portfolios, configurator, isolation tiers, custom builder) — `e15433f`
- [x] Tea_Vdom/Tea_Html extensions (ARIA, attributes, accessibility) — `c2dd783`

## Sprint 1 — "Make It Breathe" (Polish + First Run)

- [ ] **Dark Start first-run polish** — Score: 5+3+1 = 9
  - Auto-detect installed backends on launch
  - Show connection status indicators per panel in panel switcher
  - Polish entry animation (current is functional, needs visual refinement)
  - First-run wizard: detect installed tools (Hypatia, gitbot-fleet, VeriSimDB, etc.)

- [ ] **Tauri event wiring** — Score: 5+3+5 = 13
  - Connect Watcher filesystem events → panel refresh (Farm sees new repos, Plaza sees LICENSE changes)
  - Connect panel switcher → backend lifecycle (opening a panel starts its backend check)
  - Wire Tauri `listen()` for `watcher://event` events into TEA subscription
  - Emit `PanelOpened`/`PanelClosed` events for backend lifecycle

- [ ] **Accessibility audit and fix** — Score: 5+3+3 = 11
  - Test all 14 panels with keyboard-only navigation
  - Test with screen reader (NVDA/Orca)
  - Verify all 4 colour palettes (Standard, Deuteranopia, Protanopia, High Contrast)
  - Ensure all interactive elements have ARIA labels
  - Tab order follows logical panel flow
  - Focus management when panel overlay opens/closes

## Sprint 2 — "Make It Real" (Backend Connections)

- [ ] **Rust backend: Farm** — Score: 5+3+5 = 13
  - Read `~/.git-private-farm/farm-manifest.json`
  - Parse repo inventory, health scores, Dependabot queue
  - Tauri commands: `farm_load`, `farm_refresh`, `farm_get_repo`
  - No HTTP needed — local JSON file

- [ ] **Rust backend: Fleet** — Score: 5+3+5 = 13
  - reqwest to gitbot-fleet Axum dashboard (:8080)
  - Endpoints: `/api/health`, `/api/status`, `/api/findings`, `/api/bots`
  - Tauri commands: `fleet_connect`, `fleet_status`, `fleet_findings`, `fleet_dispatch`
  - Handle connection failure gracefully (show disconnected state)

- [ ] **Provenance Map git-blame integration** — Score: 5+3+5 = 13
  - Parse `git blame --porcelain` output for active file
  - Extract author, email, timestamp, Co-Authored-By trailer
  - Map to trust levels via ProvenanceEngine.deriveTrustLevel
  - Scan for unsound markers (believe_me, Admitted, sorry, unsafeCoerce)
  - Update provenance on file save (Watcher event triggers re-blame)

- [ ] **Cross-panel bus (PanelBus)** — Score: 3+3+5 = 11
  - Define cross-panel event types in `src/core/PanelBus.res`
  - Events: HypatiaFindingRouted, RepoHealthUpdated, ProvenanceChanged, FeedbackSignal
  - Route through TEA update loop (not direct panel-to-panel)
  - Each panel declares which bus events it subscribes to

- [ ] **Feedback-O-Tron opinion mining** — Score: 3+3+3 = 9
  - Extract structured sentiment from feedback text (positive/negative/neutral + topic)
  - Panel Pulse: per-panel satisfaction score
  - Priority signals: map "people hate X" → bump X in dev priority
  - Feed aggregated friction signals into Vexometer
  - Store feedback history for trend analysis

- [ ] **Code MRI Layer 0: VoiceTag** — Score: 5+3+5 = 13
  - Core tag model: numbered annotations on code regions (file, startLine, endLine, tagType, author attribution)
  - Tag types: TODO, FIXME, REFACTOR, NOTE, QUESTION, WARN, REVIEW
  - Attribution per tag: who created it (human-voice, human-keyboard, ai-agent), which AI, timestamp
  - Voice input via Web Speech API (browser-native, no external service)
  - Simple grammar: "line 24 to 34 tag todo", "edit tag 3", "delete tag 7", "who wrote line 50"
  - Keyboard/mouse fallback: select text → right-click → tag
  - Authorship chain on tagged code: "written by human → refactored by Claude → tagged FIXME by human voice"
  - Tag persistence (save/load alongside file, .voicetag.json sidecar or VeriSimDB)
  - Numbered tags per file for voice reference: "show tag 3", "resolve tag 7"
  - Integration: Provenance Map reads tags, Vexometer counts unresolved FIXMEs as friction

## Sprint 3 — "Make It Complete" (Remaining Backends)

- [ ] **Rust backend: Hypatia** — Score: 5+3+5 = 13
  - reqwest to Hypatia Elixir API (`/api/v1/`)
  - Endpoints: scans, neural networks, pipeline, quarantine, confidence
  - Map 5 neural network confidence values to Panel-N gauges
  - Safety triangle routing: Eliminate/Substitute/Control
  - Most important panel — 298 repos x 5 networks

- [ ] **Rust backend: Aerie** — Score: 3+3+3 = 9
  - reqwest to V-lang API gateway (REST:4000, GraphQL:4000)
  - Health dashboard: latency, jitter, packet loss
  - Speed test results display
  - BGP route analysis and proof envelopes

- [ ] **NQC console in Playgrounds** — Score: 3+3+3 = 9
  - Wire existing CORS proxy at :4000 (forwards to VeriSimDB:8080, QuandleDB:8081, LithoGlyph:8082)
  - Reuse NQC web UI query format
  - Keyword ribbon from database profiles
  - Multi-database switch (VQL/KQL/GQL tabs)

- [ ] **Rust backend: Reposystem + Plaza** — Score: 3+3+3 = 9
  - Filesystem scanning for RSR compliance
  - Check for: `.machine_readable/`, `0-AI-MANIFEST.a2ml`, `.editorconfig`, `Justfile`, `TOPOLOGY.md`
  - Plaza: scan LICENSE files, detect PMPL adoption, compliance audit
  - Reposystem: score per-repo, aggregate across ~265 repos

- [ ] **Provisioner install flow** — Score: 3+3+5 = 11
  - Wire portfolio "Install" button to actual panel setup
  - Config persistence (save/load panel configs to disk)
  - Stapeln pod creation for StandardPod/HardenedPod tiers
  - Panel download/update mechanism (future — placeholder for now)

## Sprint 4 — "Make It Extensible" (Community Features)

- [ ] **Odds & Sods package manager panel** — Score: 3+3+3 = 9
  - Scan for: Cargo.toml, gleam.toml, mix.exs, package.json, build.zig, *.ipkg, *.cabal, etc.
  - Unified package inventory across all managers
  - Cross-ecosystem dependency analysis (cargo + mix pulling same C lib)
  - "Flotsam tracker" for manually installed tools
  - Panel-L: package policy (banned packages, version pins, license requirements)
  - Panel-N: vulnerability correlation across ecosystems
  - Panel-W: inventory table, update queue, cache cleanup

- [ ] **Stapeln pod integration** — Score: 3+3+5 = 11
  - Three defaults: no pod, Alpine+Podman, Stapeln+Chainguard
  - Panel lifecycle: start pod → mount panel → route events → stop pod
  - Clean uninstall: delete pod, everything goes
  - Experimental: offer with big warnings, collect usage data

- [ ] **Wharf (WordPress) panel** — Score: 3+3+3 = 9
  - WP Wharf integration (Mooring Protocol, Yacht state)
  - php-aegis integration (SQL AST blocking, eBPF firewall)
  - Panel-L: Nickel config schemas
  - Panel-N: integrity verification, security scoring
  - Panel-W: live WordPress state, metrics

- [ ] **TypLL language panel** — Score: 1+1+1 = 3
  - Core language development environment
  - Support for Eclexia, AffineScript, Anvomidav, Ephapax, WokeLang, BetLang
  - Syntax-aware editing with formal verification hooks
  - Dependent type checking integration
  - Long-term — requires language runtimes to stabilise

## Sprint 5 — "Code MRI" (Mutual Recognition & Integrity)

- [ ] **Code MRI Layer 1: Blake3 Provenance Chain** — Score: 5+3+5 = 13
  - Blake3 hash per code region: content + author + timestamp + parent hash
  - Import provenance: code from external sources carries its attribution chain
  - Export provenance: PanLL markings travel with exported code
  - Tamper detection: strip attribution → hash mismatch → instantly visible
  - Integration: extends Provenance Map trust levels with cryptographic verification

- [ ] **Code MRI Layer 2: VeriSimDB Development Timeline** — Score: 5+3+5 = 13
  - Development-as-time-series database (dogfood VeriSimDB as analytics backend)
  - Stored metrics per snapshot: LOC, dangling TODOs/FIXMEs, open VoiceTags, library count,
    failed type checks, panic-attack findings, AI attribution %, Vexometer readings
  - Timeline scrubber UI: slide through project history, see state at any point
  - Active rollback to any snapshot state within the database
  - "End credits" documentary view: accelerated replay of development process

- [ ] **Code MRI Layer 3: Pattern Diagnostics & Gamification** — Score: 3+3+3 = 9
  - Derive development patterns from timeline data
  - "Bullshit detector": AI session with high tag density / low resolution rate flagged
  - Efficiency patterns: "human writes boilerplate manually — slower, zero FIXMEs"
  - Victory conditions: all TODOs resolved, zero panic-attack findings, Vexometer < 0.3
  - Badges/streaks (diagnostic, not patronising): "longest FIXME-free run", "most tags resolved"
  - Admin enforcement mode: universities require attribution tracking on all submissions
  - Team training: review development patterns to improve workflow and spot inefficiencies

- [ ] **Code MRI Layer 4: Attribution-to-Licensing Link** — Score: 3+3+3 = 9
  - Auto-generate PMPL/MPL attribution sections from Blake3 provenance chains
  - Per-line attribution: "Lines 1-50: J.D.A. Jewell. Lines 51-80: Claude Opus (AI-assisted, human-reviewed)"
  - Import attribution: "Lines 81-120: from proven-servers (PMPL-1.0-or-later)"
  - Makes source-available license requirements trivially machine-verifiable
  - Links to Palimpsest Plaza for ecosystem-wide license compliance dashboard

- [ ] **Code MRI Metrics & Learning Panel** — Score: 3+3+5 = 11
  - ML-driven pattern identification from Code MRI timeline data
  - Uses Hypatia's neural networks for higher-order pattern detection across projects
  - Identify struggling developers and offer direct support (not punishment — WokeLang philosophy)
  - Match people to tasks they're good at or enjoy more (reassignment suggestions)
  - "30 tags in, AI was bullshitting" diagnostic → recommend human review
  - "This developer excels at algorithmic work but hates boilerplate" → suggest AI pairing for setup
  - Team-level patterns: "Team velocity spikes when X pairs with Y on Z-type tasks"
  - Admin mode for education: instructors see student development patterns, offer targeted help
  - Gamification dashboard: personal development trajectory, improvement trends, skill heat map
  - Privacy-first: individual data visible only to the developer (admin sees aggregates only)

## Sprint 6 — "Dogfood Mode" (Self-Hosting & Internal Tool Tracking)

- [ ] **Dogfood Manager infrastructure** — Score: 3+3+5 = 11
  - Dogfood folder on Desktop (or configurable path): drop tools/libraries to make available
  - PanLL detects available dogfood candidates and suggests them when reaching for externals
  - Dashboard: which of your own tools are being used in PanLL, which are gathering dust
  - Tracks: "using rustls directly — proven-servers has a TLS component, dogfood?"
  - CRG-driven policy: grade D+ = suggest, grade E = warn, grade X/F = ban (unless override)
  - Insist mode: "Stapeln MUST be used for container isolation" (enforced, not just suggested)
  - Ban mode: "Eclexia runtime is CRG X — not ready for production panels" (blocks with reason)
  - Override with explicit acknowledgment: "I know this is grade E, proceeding anyway" (logged)
  - Feeds Code MRI timeline: "switched from SQLite to VeriSimDB on March 5 — track impact"
  - Connects to Provisioner: dogfood policies per panel, per isolation tier

## Deferred (Noted, Not Scheduled)

- [ ] **Valence Shell integration** — CLI tool switchable with bash
- [ ] **Micropatching system** — Reversible patches for config/code changes
- [ ] **eNSAID specification v1.0** — Separate repo, own governance
- [ ] **IDApTIK game panel** — Level architect, VM inspector, DLC management
- [ ] **Statistease panel** — Analytics dashboard
- [ ] **Minecraft modding panel** — Community contributed
- [ ] **VSCode/VSCodium extension** — Export core as extension
- [ ] **Tripartite contributor approach** — Documented on hyperpolymath wiki
- [ ] **RISC-V + Minix first-class targets** — Educational computing focus
- [ ] **Comprehensive module audit** — Walk all 265 repos, map to PanLL panels

## Infrastructure Debt

- [ ] Update TOPOLOGY.md to reflect current 14-panel architecture
- [ ] Update STATE.scm to reflect current state (still says 95% on old milestones)
- [ ] Update ECOSYSTEM.scm (still says "future" for projects that now have panels)
- [ ] Float.toFixedWithPrecision deprecation warnings → switch to Float.toFixed
- [ ] View.res unused match case warning (line 155) — clean up placeholder
- [ ] Provenance/Unknown constructor shadowing warnings — namespace cleanup

---

*Check items off as they're completed. Add new items as they arise. Re-score periodically as priorities shift.*
