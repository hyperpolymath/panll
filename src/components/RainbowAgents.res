// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// RainbowAgents — Colour-coded agent family for PanLL panels.
//
// Each agent colour represents a specialisation mapped to PanLL's
// three-panel model (L/N/W). Agents can be dispatched to panels,
// observed through Panel-N, and their results appear in Panel-W.
//
// The rainbow family provides a visual language for agent activity:
// which agent is doing what, where, and in what state — all visible
// as coloured indicators across the panel system.

/// Agent colour — each maps to a domain and a visual indicator.
type agentColour =
  | /// Red — Security & threat analysis. Maps to Panel-L constraints.
  Red
  | /// Orange — Infrastructure & deployment. Maps to Panel-W world state.
  Orange
  | /// Yellow — Quality & testing. Maps to Panel-N reasoning.
  Yellow
  | /// Green — Compliance & standards (RSR, SPDX, REUSE). Maps to Panel-L.
  Green
  | /// Blue — Documentation & communication. Maps to Panel-W output.
  Blue
  | /// Indigo — Formal verification & proofs (echidna). Maps to Panel-L + Panel-N.
  Indigo
  | /// Violet — Creative & design (UI, UX, aesthetics). Maps to Panel-W.
  Violet

/// Map a colour to its hex value for PixiJS rendering.
let colourHex = (colour: agentColour): int =>
  switch colour {
  | Red => 0xff4444
  | Orange => 0xff8844
  | Yellow => 0xffcc44
  | Green => 0x44ff88
  | Blue => 0x4488ff
  | Indigo => 0x6644ff
  | Violet => 0xaa44ff
  }

/// Display name for the agent colour.
let colourName = (colour: agentColour): string =>
  switch colour {
  | Red => "RED"
  | Orange => "ORANGE"
  | Yellow => "YELLOW"
  | Green => "GREEN"
  | Blue => "BLUE"
  | Indigo => "INDIGO"
  | Violet => "VIOLET"
  }

/// Domain description for the agent colour.
let colourDomain = (colour: agentColour): string =>
  switch colour {
  | Red => "Security & Threat Analysis"
  | Orange => "Infrastructure & Deployment"
  | Yellow => "Quality & Testing"
  | Green => "Compliance & Standards"
  | Blue => "Documentation & Communication"
  | Indigo => "Formal Verification & Proofs"
  | Violet => "Creative & Design"
  }

/// Which panel type this agent colour primarily reports to.
type panelAffinity =
  | /// Constraint-focused (Panel-L)
  SymbolicPanel
  | /// Reasoning-focused (Panel-N)
  NeuralPanel
  | /// Result-focused (Panel-W)
  WorldPanel

let colourPanelAffinity = (colour: agentColour): panelAffinity =>
  switch colour {
  | Red => SymbolicPanel
  | Orange => WorldPanel
  | Yellow => NeuralPanel
  | Green => SymbolicPanel
  | Blue => WorldPanel
  | Indigo => SymbolicPanel
  | Violet => WorldPanel
  }

/// Map gitbot-fleet bots to rainbow colours.
let botToColour = (botId: FleetModel.botId): agentColour =>
  switch botId {
  | Rhodibot => Green    // RSR compliance
  | Echidnabot => Indigo // Formal verification
  | Sustainabot => Orange // Dependency management
  | Glambot => Violet    // UI/aesthetics
  | Seambot => Yellow    // Integration testing
  | Finishbot => Blue    // Documentation/completion
  }

/// All colours in rainbow order.
let allColours: array<agentColour> = [Red, Orange, Yellow, Green, Blue, Indigo, Violet]

// ---------------------------------------------------------------------------
// Rainbow Agent State
// ---------------------------------------------------------------------------

/// A rainbow agent instance — one per colour, tracks activity.
type rainbowAgent = {
  colour: agentColour,
  mutable active: bool,
  mutable currentTask: option<string>,
  mutable completedTasks: int,
  mutable failedTasks: int,
  /// Which panel is currently displaying this agent's output.
  mutable displayPanel: option<panelAffinity>,
}

/// Create a dormant agent.
let makeAgent = (colour: agentColour): rainbowAgent => {
  colour,
  active: false,
  currentTask: None,
  completedTasks: 0,
  failedTasks: 0,
  displayPanel: None,
}

/// The full rainbow — all 7 agents.
type rainbow = {
  red: rainbowAgent,
  orange: rainbowAgent,
  yellow: rainbowAgent,
  green: rainbowAgent,
  blue: rainbowAgent,
  indigo: rainbowAgent,
  violet: rainbowAgent,
}

/// Create a fresh rainbow with all agents dormant.
let makeRainbow = (): rainbow => {
  red: makeAgent(Red),
  orange: makeAgent(Orange),
  yellow: makeAgent(Yellow),
  green: makeAgent(Green),
  blue: makeAgent(Blue),
  indigo: makeAgent(Indigo),
  violet: makeAgent(Violet),
}

/// Get an agent by colour.
let getAgent = (rainbow: rainbow, colour: agentColour): rainbowAgent =>
  switch colour {
  | Red => rainbow.red
  | Orange => rainbow.orange
  | Yellow => rainbow.yellow
  | Green => rainbow.green
  | Blue => rainbow.blue
  | Indigo => rainbow.indigo
  | Violet => rainbow.violet
  }

/// Activate an agent with a task description.
let activate = (agent: rainbowAgent, task: string): unit => {
  agent.active = true
  agent.currentTask = Some(task)
  agent.displayPanel = Some(colourPanelAffinity(agent.colour))
}

/// Mark an agent's current task as completed.
let complete = (agent: rainbowAgent): unit => {
  agent.active = false
  agent.completedTasks = agent.completedTasks + 1
  agent.currentTask = None
}

/// Mark an agent's current task as failed.
let fail = (agent: rainbowAgent): unit => {
  agent.active = false
  agent.failedTasks = agent.failedTasks + 1
  agent.currentTask = None
}

/// Count active agents in the rainbow.
let activeCount = (rainbow: rainbow): int =>
  allColours->Array.filter(c => (getAgent(rainbow, c)).active)->Array.length

/// Get all active agents with their colours.
let activeAgents = (rainbow: rainbow): array<(agentColour, string)> =>
  allColours->Array.filterMap(c => {
    let agent = getAgent(rainbow, c)
    if agent.active {
      switch agent.currentTask {
      | Some(task) => Some((c, task))
      | None => Some((c, "active"))
      }
    } else {
      None
    }
  })
