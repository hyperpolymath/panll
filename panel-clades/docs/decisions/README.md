<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- Copyright (c) {{CURRENT_YEAR}} {{AUTHOR}} ({{OWNER}}) <{{AUTHOR_EMAIL}}> -->

# Architecture Decision Records

We record significant architectural decisions using [Architecture Decision Records (ADRs)](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions), as described by Michael Nygard.

Each ADR captures the context, decision, and consequences of a choice that affects the project's structure, dependencies, or conventions.

## Creating a new ADR

```bash
just adr "Title of decision"
```

This creates a new numbered file in `docs/decisions/` from the template at `0000-template.md`.
