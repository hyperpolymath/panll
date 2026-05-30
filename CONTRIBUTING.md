<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->

# Contributing to PanLL

## Why These Tools?

Before you dive in, it helps to understand _why_ PanLL uses the stack it does.
These aren't arbitrary preferences — they're lessons learned from building a
14-panel stateful application.

**AffineScript instead of TypeScript** — PanLL has 26,000+ lines of state management
across 14 panels. TypeScript's structural type system means `any` leaks are
always one cast away, and discriminated unions require manual type guards that
are easy to forget. ReScript's sound type system means if it compiles, the types
are correct — no escape hatches, no `as unknown as`, no runtime type errors.
Exhaustive pattern matching on variant types caught dozens of "missing case" bugs
during the panel expansion. See [rescript-lang.org](https://rescript-lang.org).

**Rust + Gossamer instead of Electron** — PanLL's release binary is ~5 MB. An
equivalent Electron app would be 100+ MB (shipping an entire Chromium). The Rust
backend runs through Gossamer (Zig + WebKitGTK), a lightweight container-friendly
webview shell. Filesystem watching, git blame parsing, and HTTP clients run with
no garbage collector pauses — important when 106 panels are subscribed to live
events. PanLL originally used Tauri 2.0 but migrated to Gossamer for better
container support and tighter integration with the hyperpolymath stack.

**Deno instead of npm/Node** — No `node_modules` directory (1,200+ transitive
deps for a typical Node project). Built-in test runner. Secure-by-default
permissions. ReScript and Tailwind run via `npm:` specifiers in `deno.json`;
there is no `package.json` and no npm CLI is invoked.

**Elixir/BEAM for middleware** — BEAM's supervision trees mean a crashing backend
connection restarts itself without taking down the whole panel surface. Pattern
matching on messages is the same philosophy as ReScript's TEA on the frontend.

**Julia for data processing** — When batch analysis needs actual numeric
performance. Python's GIL means "import numpy and pray"; Julia's multiple
dispatch compiles to LLVM native code for every combination of argument types.

If you're coming from TypeScript/React, the biggest mental shift is TEA (The Elm
Architecture): state changes are pure functions, side effects are commands, and
the compiler enforces exhaustiveness everywhere. It's more explicit than hooks,
but after the first day you'll wonder why you ever tolerated `useEffect`.

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/hyperpolymath/panll.git
cd panll

# Using Nix (recommended for reproducibility)
nix develop

# Or using toolbox/distrobox
toolbox create panll-dev
toolbox enter panll-dev
# Install dependencies manually

# Verify setup
just check   # or: cargo check / mix compile / etc.
just test    # Run test suite
```

### Repository Structure
```
panll/
├── src/                 # Source code (Perimeter 1-2)
├── lib/                 # Library code (Perimeter 1-2)
├── extensions/          # Extensions (Perimeter 2)
├── plugins/             # Plugins (Perimeter 2)
├── tools/               # Tooling (Perimeter 2)
├── docs/                # Documentation (Perimeter 3)
│   ├── architecture/    # ADRs, specs (Perimeter 2)
│   └── proposals/       # RFCs (Perimeter 3)
├── examples/            # Examples (Perimeter 3)
├── spec/                # Spec tests (Perimeter 3)
├── tests/               # Test suite (Perimeter 2-3)
├── .well-known/         # Protocol files (Perimeter 1-3)
├── .github/             # GitHub config (Perimeter 1)
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md      # This file
├── GOVERNANCE.md
├── LICENSE
├── MAINTAINERS.md
├── README.adoc
├── SECURITY.md
├── flake.nix            # Nix flake (Perimeter 1)
└── Justfile             # Task runner (Perimeter 1)
```

---

## How to Contribute

### Reporting Bugs

**Before reporting**:
1. Search existing issues
2. Check if it's already fixed in `main`
3. Determine which perimeter the bug affects

**When reporting**:

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Clear, descriptive title
- Environment details (OS, versions, toolchain)
- Steps to reproduce
- Expected vs actual behaviour
- Logs, screenshots, or minimal reproduction

### Suggesting Features

**Before suggesting**:
1. Check the [roadmap](ROADMAP.md) if available
2. Search existing issues and discussions
3. Consider which perimeter the feature belongs to

**When suggesting**:

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:

- Problem statement (what pain point does this solve?)
- Proposed solution
- Alternatives considered
- Which perimeter this affects

### Your First Contribution

Look for issues labelled:

- [`good first issue`](https://github.com/hyperpolymath/panll/labels/good%20first%20issue) — Simple Perimeter 3 tasks
- [`help wanted`](https://github.com/hyperpolymath/panll/labels/help%20wanted) — Community help needed
- [`documentation`](https://github.com/hyperpolymath/panll/labels/documentation) — Docs improvements
- [`perimeter-3`](https://github.com/hyperpolymath/panll/labels/perimeter-3) — Community sandbox scope

---

## Development Workflow

### Branch Naming
```
docs/short-description       # Documentation (P3)
test/what-added              # Test additions (P3)
feat/short-description       # New features (P2)
fix/issue-number-description # Bug fixes (P2)
refactor/what-changed        # Code improvements (P2)
security/what-fixed          # Security fixes (P1-2)
```

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):
```
<type>(<scope>): <description>

[optional body]

[optional footer]
