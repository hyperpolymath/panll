# K9 Kennel: Performance Profiler Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "performance-profiler-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Performance Profiler",
    short_name = "Perf",
    description = "Frame budget, GC pressure, memory flamegraphs, bottleneck detection",
    has_backend = true,
    clade_id = "performance-profiler",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "performanceProfiler",
    msg_namespace = "performanceProfilerMsg",
    view_route = "PanelPerformance Profiler",
    module_name = "Performance Profiler",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
