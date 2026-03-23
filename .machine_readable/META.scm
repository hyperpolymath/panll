; SPDX-License-Identifier: PMPL-1.0-or-later
; META.scm — Project meta-information for PanLL
; Last updated: 2026-03-23

(meta
  (metadata
    (version "1.1.0")
    (last-updated "2026-03-23")
    (project "panll")
    (author "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>")
    (license "PMPL-1.0-or-later")
    (standard "RSR 2026")
    (format-spec "hyperpolymath/rsr-template-repo/spec/META-FORMAT-SPEC.adoc"))

  (architecture-decisions
    (adr-001
      (title "Binary Star Human-Machine Architecture")
      (status "accepted")
      (date "2026-01-15")
      (decision "Model Human and Machine as Binary Star system orbiting shared Barycentre.
                 Three panels: Panel-L (Symbolic/Human), Panel-N (Neural/Machine), Panel-W (World/Barycentre)."))

    (adr-002
      (title "The Elm Architecture (TEA) for State Management")
      (status "accepted")
      (date "2026-01-20")
      (decision "Custom TEA implementation in src/tea/ (18 modules). Permanent —
                 rescript-tea@0.16.0 evaluated and rejected (2026-03-08)."))

    (adr-003
      (title "ReScript for Type-Safe Frontend")
      (status "accepted")
      (date "2026-01-18")
      (decision "ReScript 11.1+ compiling to JavaScript. Sound type system, exhaustive matching."))

    (adr-004
      (title "Gossamer for Desktop App Framework")
      (status "accepted")
      (date "2026-01-22")
      (decision "Originally Tauri 2.0; migrated to Gossamer (Zig + WebKitGTK) in March 2026
                 for better container support and tighter hyperpolymath stack integration."))

    (adr-005
      (title "Anti-Crash Library as Circuit Breaker")
      (status "accepted")
      (date "2026-01-25")
      (decision "Circuit breaker between Panel-N and Panel-W. Every neural token must pass
                 symbolic validation before reaching the Barycentre."))

    (adr-006
      (title "Vexometer for Cognitive Load Monitoring")
      (status "accepted")
      (date "2026-01-28")
      (decision "Vexometer tracks cancellations, corrections, dwell time. Vexation Index (0.0-1.0)
                 triggers anti-inflammatory UI adjustments."))

    (adr-007
      (title "Deno + npm Hybrid Build System")
      (status "accepted")
      (date "2026-02-02")
      (decision "Deno tasks for Tailwind CSS and Gossamer orchestration.
                 npm scripts only for ReScript compilation.")))

  (development-practices
    (testing-strategy "Deno.test for JS unit tests; cargo test for Rust. Integration tests for Gossamer backend.")
    (versioning-scheme "Semantic versioning. v0.x.y = pre-1.0 (breaking changes allowed).")
    (license-policy "All original code PMPL-1.0-or-later. Third-party dependencies respect original licenses."))

  (design-rationale
    (three-pane-layout "Parallel layout (L/N/W side-by-side) emphasises simultaneity.")
    (binary-star-metaphor "Two stars orbiting shared centre of mass. Human = symbolic, Machine = neural.")
    (information-humidity "UI detail density adapts to operator stress level via Vexometer.")
    (dark-start-mode "Binary Star topology diagram on startup. Operator-initiated activation."))

  (cross-cutting-concerns
    (security "Gossamer enforces CSP. Validate all backend command inputs. SafeDOM 4-layer defence-in-depth.")
    (performance "ReScript compiles to optimised JS. Rust backend for CPU-intensive tasks. VDOM diffing.")
    (accessibility "Comprehensive ARIA attributes. Keyboard navigation (Ctrl+Shift+L/N/B/W). 4 colour palettes.")
    (internationalisation "English-only for v0.x. i18n framework planned for v1.0.")))
