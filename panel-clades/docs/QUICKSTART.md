<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# Quickstart

Get up and running in 60 seconds.

## Prerequisites

- [Git](https://git-scm.com/) 2.40+
- [just](https://github.com/casey/just) (command runner)
- Your language toolchain (see `Justfile` for details)

## From Template (New Project)

```bash
git clone https://github.com/{{OWNER}}/rsr-template-repo my-project
cd my-project
rm -rf .git && git init -b main
just init       # interactive placeholder replacement
```

## Clone and Setup (Existing Project)

```bash
git clone https://github.com/{{OWNER}}/{{REPO}}.git
cd {{REPO}}
just deps
```

## Build and Test

```bash
just build
just test
```

## Verify Everything Works

```bash
just check
```

## Project Structure

```
src/         # Source code
tests/       # Test suite
benches/     # Benchmarks
docs/        # Documentation
.github/     # CI/CD workflows
```

## What Next?

- Browse the [docs/](.) for architecture and conventions
- Run `just --list` to see all available commands
- Read [CONTRIBUTING.md](../CONTRIBUTING.md) when you are ready to contribute

## Troubleshooting

If `just deps` fails, ensure your toolchain version matches the
project requirements listed in the `Justfile` or `.machine_readable/ECOSYSTEM.a2ml`.

Open a [Discussion](https://github.com/{{OWNER}}/{{REPO}}/discussions)
if you get stuck.
