<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# REQUIRES INITIALISATION

**This repository is not finished being set up.** 45 substitution token(s) across 33 file(s) still have no value.

## Why this is not already done

This repo was created from `hyperpolymath/rsr-template-repo`. The mint
(`just repo-init`) fills every token that has a single mechanical answer —
owner, repo, author, dates, licence, branch — and it has done so here.

The tokens below are the ones it *deliberately cannot* answer. They need a
decision or a fact that exists only in your head: what this project is for,
what command builds it, which port the service listens on, whether a PGP key
is held at all. The template's own token vocabulary says as much — you cannot
sensibly answer "required invariants" in a thirty-second bootstrap.

They were left **visibly unfilled on purpose**. The alternatives were both
worse: inventing plausible values would put confident falsehoods into a
security policy and an architecture document, and silently deleting the
sections would hide the fact that a decision is owed. A visible gap is
honest; a fabricated answer is not.

## Do not delete this file until every item below is resolved

This file is the only marker that the work is outstanding. Deleting it early
does not finish the setup, it just conceals it — and the next person or agent
to arrive will reasonably assume the repo is complete.

- **If you are a person:** delete this file yourself once the last item is done.
- **If you are an agent:** resolve what you legitimately can, leave the rest,
  and delete this file only when no token below remains anywhere in the tree.
  Do not delete it to make a gate go green.

Re-running the estate top-up tool will remove this file automatically once
nothing is outstanding, so the safest way to finish is to fix the tokens and
let the check confirm it.

## What is needed, and where it goes

### `{{ARGS}}`

Arguments for the justfile recipe this appears in.

Appears in:

- `Justfile`

### `{{AUTHOR_EMAIL_ALT}}`

Appears in:

- `panel-clades/.mailmap`
- `panel-clades/PLACEHOLDERS.md`

### `{{AUTHOR_ORG}}`

Author's organisation. NOTE: no filled instance of this exists anywhere in the estate — consider deleting the field instead.

Appears in:

- `.machine_readable/svc/k9/examples/project-metadata.k9.ncl`
- `panel-clades/PLACEHOLDERS.md`

### `{{CLADE_ID}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`
- `panel-clades/clades/_basics/README.adoc`

### `{{CLADE_NAME}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`
- `panel-clades/clades/_basics/README.adoc`

### `{{CONDUCT_TEAM}}`

Name of the conduct body. If there is no committee, rewrite the sentence rather than substituting a plural noun into 'a {{CONDUCT_TEAM}} member'.

Appears in:

- `CODE_OF_CONDUCT.md`
- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/CODE_OF_CONDUCT.md`
- `panel-clades/PLACEHOLDERS.md`

### `{{DILITHIUM5_PUBLIC_KEY}}`

Appears in:

- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{DOMAIN}}`

Appears in:

- `.machine_readable/contractiles/trust/Trustfille.a2ml`
- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{DS_RECORD}}`

Appears in:

- `.machine_readable/contractiles/trust/Trustfille.a2ml`

### `{{ED448_PUBLIC_KEY}}`

Appears in:

- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{EXPIRES_AT}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{FALLBACK_SIGNATURE}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{GENERATED_AT}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{ICON}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`
- `panel-clades/clades/_basics/README.adoc`

### `{{KEY_TAG}}`

Appears in:

- `.machine_readable/contractiles/trust/Trustfille.a2ml`

### `{{LICENSE}}`

SPDX identifier for this repo's licence.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/container/Containerfile`

### `{{MTA_STS_ID}}`

Appears in:

- `.machine_readable/contractiles/trust/Trustfille.a2ml`

### `{{ONE_LINE_DESCRIPTION}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`
- `panel-clades/clades/_basics/README.adoc`

### `{{ON_DISPOSE_HANDLER}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`

### `{{ON_INIT_HANDLER}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`

### `{{PASCAL_NAME}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`
- `panel-clades/clades/_basics/README.adoc`

### `{{PGP_KEY_URL}}`

Public URL the PGP key can be fetched from. Same caveat as PGP_FINGERPRINT.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `docs/reports/audit/pillar-audit-2026-04-15.md`
- `panel-clades/.well-known/security.txt`
- `panel-clades/PLACEHOLDERS.md`
- `panel-clades/SECURITY.md`

### `{{PLACEHOLDERS}}`

Appears in:

- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{PORT}}`

Port the container service listens on.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/container/Containerfile`
- `panel-clades/container/deploy.k9.ncl`
- `panel-clades/container/entrypoint.sh`

### `{{PRIMARY_SIGNATURE}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{PROJECT_DESCRIPTION}}`

One-line description, matching the forge description.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/container/Containerfile`
- `panel-clades/flake.nix`

### `{{PROJECT_DOMAIN}}`

Taxonomy value for the subject domain.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/anchors/ANCHOR.a2ml`

### `{{PROJECT_KIND}}`

Taxonomy value (library, service, tool, lab…).

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/anchors/ANCHOR.a2ml`

### `{{PROJECT_PURPOSE}}`

One line: what this exists to do.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/anchors/ANCHOR.a2ml`

### `{{PROJECT_UNIQUE_STRENGTH}}`

What this does that its alternatives do not.

Appears in:

- `.machine_readable/agent_instructions/methodology.a2ml`

### `{{PROTOCOL}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/README.adoc`

### `{{REGISTRY}}`

Container registry to publish to.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/container/ct-build.sh`
- `panel-clades/container/deploy.k9.ncl`

### `{{RESPONSE_TIME}}`

Initial-response SLA for a security or conduct report. Promise only what a solo maintainer can actually meet.

Appears in:

- `CODE_OF_CONDUCT.md`
- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/CODE_OF_CONDUCT.md`
- `panel-clades/PLACEHOLDERS.md`

### `{{SECURITY_EMAIL}}`

Address for private vulnerability reports. Two competing values exist in the estate (`6759885+hyperpolymath@users.noreply.github.com` and `security@hyperpolymath.org`) — pick one deliberately.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.well-known/security.txt`

### `{{SECURITY_TXT_EXPIRES}}`

Appears in:

- `.machine_readable/contractiles/trust/Trustfille.a2ml`

### `{{SERVICE_NAME}}`

Container service name.

Appears in:

- `panel-clades/container/Containerfile`
- `panel-clades/container/ct-build.sh`
- `panel-clades/container/deploy.k9.ncl`
- `panel-clades/container/entrypoint.sh`

### `{{SHA3_512}}`

Appears in:

- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{SHAKE256}}`

Appears in:

- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{SHORT}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/clades/_basics/GenericAi.a2ml`
- `panel-clades/clades/_basics/GenericBridge.a2ml`
- `panel-clades/clades/_basics/GenericBuilder.a2ml`
- `panel-clades/clades/_basics/GenericDatabase.a2ml`
- `panel-clades/clades/_basics/GenericDirective.a2ml`
- `panel-clades/clades/_basics/GenericInspector.a2ml`
- `panel-clades/clades/_basics/GenericLoader.a2ml`
- `panel-clades/clades/_basics/GenericMeta.a2ml`
- `panel-clades/clades/_basics/GenericNetwork.a2ml`
- `panel-clades/clades/_basics/GenericScanner.a2ml`
- `panel-clades/clades/_basics/GenericService.a2ml`
- `panel-clades/clades/_basics/GenericTerminal.a2ml`
- `panel-clades/clades/_basics/GenericViewer.a2ml`
- `panel-clades/clades/_basics/README.adoc`

### `{{SPHINCS_PLUS_PUBLIC_KEY}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{TRUSTFILE_PATH}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{TRUSTFILE_VERSION}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

### `{{VERSION}}`

Version/tag for the container image.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/container/deploy.k9.ncl`

### `{{WEBSITE}}`

Project homepage URL, or delete the field if there is none.

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `docs/reports/audit/pillar-audit-2026-04-15.md`
- `panel-clades/.well-known/security.txt`
- `panel-clades/PLACEHOLDERS.md`

### `{{ZONEMD}}`

Appears in:

- `docs/architecture/P2-COPROCESSOR-CLADE-DESIGN.adoc`
- `panel-clades/.machine_readable/contractiles/trust/Trustfile.a2ml`

---

Generated by the estate top-up pass. Rationale and the governing rulings are
in `hyperpolymath/standards`; the token vocabulary is
`.machine_readable/ai/PLACEHOLDERS.adoc` in `rsr-template-repo`.
