// SPDX-License-Identifier: PMPL-1.0-or-later

/// Performance Profiler messages -- frame budget, GC pressure, memory flamegraphs.

open Model

type performanceProfilerMsg =
  | SetPpTab(performanceTab)
  | PpStarted
  | PpCompleted(result<string, string>)
  | DismissPpError
  | StartProfiling
  | StopProfiling
