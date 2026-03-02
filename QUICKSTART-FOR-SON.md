# PanLL Quickstart Guide

## What is PanLL?

PanLL is a developer environment with three main panels side-by-side:

- **Panel L (left, indigo)** -- Symbolic/logic constraints. Think of it like rules the system must follow.
- **Panel N (middle, green)** -- Neural stream. This is where AI inference happens, tokens flow through, and the OODA loop runs.
- **Panel W (right)** -- World state. Security tools, event chains, database queries.

On top of these, there are **overlay panels** you can open from the panel bar (vertical icons on the right edge).

## How to Run

```bash
cd ~/Documents/hyperpolymath-repos/panll

# Terminal 1: Start the ReScript compiler (watches for changes)
npx rescript-legacy -w

# Terminal 2: Bundle the JS and serve
just bundle && just serve:dev

# Terminal 3: Build Tailwind CSS
just css:build

# Terminal 4: Start the Tauri backend
cd src-tauri && cargo run
```

Or for the full dev experience:
```bash
# In the panll directory:
just dev
```

The app opens at `http://localhost:8000/public/` (Tauri wraps this).

## First Thing You See

A dark screen with two circles (SYMBOLIC and NEURAL) connected by a dotted line. **Click anywhere** to enter the environment.

## Panel Bar (right edge)

The vertical strip of icons on the right edge is the **panel bar**. Click any icon to open that panel as a full-screen overlay. Click again (or press Escape) to close.

**Interesting panels to try:**

| Icon | Panel | What it does |
|------|-------|-------------|
| VAB | Verified Assembly Building | Like KSP's Vehicle Assembly Building but for servers. Pick components, see what capabilities you get. Really fun to play with! |
| Sec | Security | Secrets detection, vault, 2FA, shoulder-safe mode (blurs secrets). Toggle "Shoulder-Safe" for a laugh. |
| Cap | Capture | Screenshot any panel, record sessions, create demos for teaching. |
| WS | Workspace | Change the workspace mode (Rhodium/Everything/Code/Bespoke), set protection levels, manage layouts. |
| AI | AI | Multi-provider AI chat (needs API keys configured). |

## VAB (Verified Assembly Building) -- The Fun One

This is inspired by Kerbal Space Program's VAB. You're building a server by picking components:

1. Open VAB from the panel bar
2. Browse categories: Core, Network, DNS, Web, IoT, Email, Security, Data, Application, Infrastructure, Connectors
3. Click components to add them to your server
4. Watch the **warnings** and **capabilities** update in real-time
5. It tells you what your server CAN and CANNOT do based on what components you've added
6. Missing dependencies show as warnings (like "Missing TLS component!")

There are **111 proven-servers components** in the catalog. Try building different server configs!

## Security Panel -- Working Together Mode

The Security panel has features designed for group work:

- **Shoulder-Safe Mode**: Blurs detected secrets. Toggle it on and API keys get masked in real-time.
- **Redaction Patterns**: 10 built-in patterns detect API keys (Anthropic, OpenAI, AWS, GitHub, etc.).
- **2FA**: TOTP-based authentication for sensitive operations.
- **Trustfile**: Per-repo security policies loaded from `Trustfile.a2ml`.

## Workspace Modes

Press **Ctrl+Shift+M** to cycle through modes:

- **Rhodium**: Everything visible, full compliance view
- **Everything**: All panels, all tools
- **Code**: Pure coding -- hides governance panels
- **Bespoke**: Custom per-repo setup

## Session Protection

These control what you can do:

- **Open**: Normal, do whatever
- **Read-Only**: Look but don't touch
- **Sandboxed**: Do whatever, but it all resets when you leave
- **Language-Locked**: Specific file types can't be edited (e.g., lock all `.idr` files)
- **Transpilation-Guarded**: Must prove your change produces equivalent output before saving
- **Production-Gated**: Changes need sign-off before they take effect

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+Z | Undo |
| Ctrl+Shift+Z | Redo |
| Ctrl+S | Save state |
| Ctrl+P | Print active panel |
| Ctrl+Shift+L | Toggle Panel L |
| Ctrl+Shift+N | Toggle Panel N |
| Ctrl+Shift+B/W | Toggle Panel W |
| Ctrl+Shift+C | Open Capture panel |
| Ctrl+Shift+K | Open Workspace panel |
| Ctrl+Shift+S | Open Security panel |
| Ctrl+Shift+M | Cycle workspace mode |
| Ctrl+Shift+D | Toggle dry-run mode |
| Escape | Close current panel |

All shortcuts are **remappable** via the Workspace panel's Keybindings section.

## Capture Bar (side icons on panels)

Each panel has a small vertical strip of icons on its right edge:

- **C** = Screenshot this panel
- **R** = Record this panel
- **D** = Clone this panel (independent copy)
- **=** = Compare this panel with another

## Status Bar (bottom)

Shows: active panel, workspace mode, execution mode, repo name, AI status, CPU/memory usage, uptime.

## The Cool Concepts

- **Contractiles**: Elastic state contracts that govern the system. If vexation gets too high, the system intervenes.
- **Vexometer**: Tracks how frustrated the operator is. Visible as a small bar.
- **Orbital Drift Aura**: The background colour changes based on system stability.
- **Anti-Crash**: A circuit breaker that validates all neural tokens against symbolic constraints.
- **Dry Run mode**: Preview changes without applying them.
- **Forked sessions**: Create independent copies of your workspace.

## Tech Stack

- **Frontend**: ReScript (compiles to JavaScript) with custom TEA (The Elm Architecture)
- **Backend**: Rust via Tauri 2.0
- **Styling**: Tailwind CSS
- **Runtime**: Deno (not Node)
- **Tests**: 97 passing
