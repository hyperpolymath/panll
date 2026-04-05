# K9 Kennel: Strategy Drift Panel Configuration
# SPDX-License-Identifier: PMPL-1.0-or-later
#
# N3: Panel showing top-prover-per-class over time, with drift events
# flagged. Data source: Verisim's /api/v1/proof_attempts/strategy and
# /certificates endpoints, plus hypatia's StrategyDrift ETS snapshots.
{
  pedigree = {
    name = "strategy-drift-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "StrategyDrift",
    short_name = "SD",
    description = "Top-prover-per-class over time + PROVEN/SANCTIFY certificates + drift events",
    has_backend = true,
    clade_id = "strategy-drift",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "strategyDrift",
    msg_namespace = "strategyDriftMsg",
    view_route = "PanelStrategyDrift",
    module_name = "StrategyDrift",
  },
  data_sources = {
    primary = {
      endpoint = "http://localhost:8080/api/v1/proof_attempts/strategy",
      method = "GET",
      query_params = ["class", "limit"],
    },
    certificates = {
      endpoint = "http://localhost:8080/api/v1/proof_attempts/certificates",
      method = "GET",
      query_params = ["class", "prover", "evidence_limit"],
    },
    coverage = {
      endpoint = "http://localhost:8080/api/v1/proof_attempts/coverage",
      method = "GET",
    },
    drift_snapshot = {
      source = "hypatia.Hypatia.Rules.StrategyDrift.snapshot/0",
      refresh_interval_seconds = 60,
    },
  },
  views = {
    timeline = {
      description = "Per-class top prover trajectory. X: time. Y: class. Colour: prover.",
      obligation_classes = [
        "safety", "linearity", "termination", "equiv", "correctness",
        "confluence", "totality", "invariant", "refinement", "model-check", "other"
      ],
    },
    certs_grid = {
      description = "11-class × N-prover grid. Cell = success_rate × total_attempts. Border = cert status (proven/pending/sanctified).",
    },
    drift_events = {
      description = "List of (timestamp, class, old_top, new_top, candidates_requeued) shifts.",
    },
    coverage_bars = {
      description = "Per-class: n_repos × n_provers × n_attempts horizontal bars.",
    },
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
