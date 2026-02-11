// SPDX-License-Identifier: PMPL-1.0-or-later

/// panic-attacker mode presentation helpers for Pane-W.

let toneClass = (mode: string): string =>
  switch mode {
  | "full" => "text-emerald-400"
  | "fallback" => "text-amber-400"
  | "unavailable" => "text-red-400"
  | _ => "text-gray-500"
  }

let label = (mode: string): string =>
  switch mode {
  | "full" => "panic-attacker mode: full panll export"
  | "fallback" => "panic-attacker mode: fallback conversion"
  | "unavailable" => "panic-attacker mode: unavailable"
  | _ => "panic-attacker mode: unknown (probe pending)"
  }

