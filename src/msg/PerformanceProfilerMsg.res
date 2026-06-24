// SPDX-License-Identifier: MPL-2.0

/// Performance Profiler messages -- frame budget, GC pressure, memory flamegraphs.

open Model

type performanceProfilerMsg =
  | SetPpTab(performanceTab)
  | PpStarted
  | PpCompleted(result<string, string>)
  | DismissPpError
  | StartProfiling
  | StopProfiling
