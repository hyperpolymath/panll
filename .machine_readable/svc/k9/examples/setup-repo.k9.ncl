K9!
# SPDX-License-Identifier: MPL-2.0
# Example Hunt-level K9 component: Repository setup automation
# Security Level: Hunt (full execution with Just recipes)
# ⚠️ SIGNATURE REQUIRED - DO NOT RUN WITHOUT VERIFICATION

{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "repository-setup",
    security = {
      leash = 'Hunt,
      trust_level = "full-system-access",
      allow_network = true,
      allow_filesystem_write = true,
      allow_subprocess = true,
      signature_required = true,
      # §8.3/§8.4 — the grant. Each flag above is a REQUEST for a capability,
      # and a request the grant does not cover is a contradiction inside the
      # pedigree, not a preference (K9-S007). Without this list the component
      # asked for the network, the filesystem and subprocesses while granting
      # itself nothing, so "default-deny" denied nothing. Keep it in step with
      # the recipes below.
      capabilities = [
        "net.fetch",      # add-license fetches the licence text over HTTPS
        "fs.write",       # create-structure and create-checkpoint-files write
        "process.spawn",  # git, just, nickel, curl and mkdir are child processes
      ],
    },
    metadata = {
      name = "setup-repo",
      version = "1.0.0",
      description = "Automated repository setup with RSR standards",
      author = "{{AUTHOR}} <{{AUTHOR_EMAIL}}>",
    },
    warnings = [
      "This component has full system access",
      "Only run from trusted sources with verified signatures",
      "Review Just recipes before execution",
      "Use dry-run mode first: ./must --dry-run run setup-repo.k9.ncl",
    ],
    # §6.5/K9-S010 — mandatory at 'Hunt and may not be a placeholder: §9
    # requires a dry_run precondition, i.e. a plan that was produced AND
    # reviewed, and a reviewer cannot review a plan for a component that
    # requests network, filesystem and subprocess access while describing none
    # of it. Each entry names the recipe that causes it.
    side_effects = [
      "creates src/, docs/, tests/, scripts/, .github/workflows/ and .machine_readable/contractiles/k9/ under the current directory (create-structure)",
      "writes STATE.a2ml, ECOSYSTEM.a2ml and META.a2ml in the repository root, overwriting any existing copies (create-checkpoint-files)",
      "writes README.adoc in the repository root when add-readme is selected (add-readme)",
      "downloads the licence text from https://raw.githubusercontent.com/hyperpolymath/pmpl/main/LICENSE to ./LICENSE when add-license is selected (add-license)",
      "runs git init and sets repository-local user.name and user.email (init-git)",
      "spawns git, just, nickel, curl, mkdir and the shell builtins as child processes (every recipe)",
      "deletes STATE.a2ml, ECOSYSTEM.a2ml and META.a2ml from the current directory, after a 5-second pause, when clean is selected (clean)",
    ],
    # §10.1/K9-S009 — a 'Hunt component MUST carry a signature block. This one
    # is what an example can honestly carry: a CLAIM that a signature exists,
    # not a verified signature. With no external verifier the verdict is
    # 'Present_Unverified (§10.2), and 'Present_Unverified is not the Hunt
    # `signature` precondition (§10.4) — so this file is conforming, and it is
    # still NOT authorised to run. Replace the block before use:
    #   ./must sign setup-repo.k9.ncl
    signature = {
      algorithm = "Ed25519",
      key_id = "setup-repo-example",
      payload_hash = "sha256:0000000000000000000000000000000000000000000000000000000000000000",
      signature = "EXAMPLE-NOT-A-REAL-SIGNATURE",
    },
  },

  # Configuration with contracts
  config = {
    repo_name
      | String
      | std.string.NonEmpty
      = "my-new-repo",

    repo_type
      | [| 'Library, 'Application, 'Tool, 'Specification |]
      = 'Application,

    primary_language
      | String
      | std.string.NonEmpty
      = "rust",

    # RSR compliance features to enable
    features = {
      checkpoint_files | Bool = true,  # STATE.a2ml, ECOSYSTEM.a2ml, META.a2ml
      security_workflows | Bool = true,  # CodeQL, Scorecard, etc.
      quality_checks | Bool = true,  # Linting, formatting
      mirroring | Bool = false,  # GitLab/Bitbucket mirrors
    },

    # Git configuration
    git = {
      default_branch = "main",
      initial_commit | Bool = true,
      remote_url | String = "",
    },
  },

  # Just recipes for execution
  # These run when: ./must run setup-repo.k9.ncl
  recipes = {
    # Main entry point
    default = {
      recipe = "setup",
      description = "Set up RSR-compliant repository",
    },

    # Individual setup tasks
    setup = {
      dependencies = ["check-env", "create-structure", "init-git", "setup-workflows"],
      commands = [
        "echo '✅ Repository setup complete!'",
        "echo 'Run: git status to see changes'",
      ],
    },

    "check-env" = {
      description = "Verify required tools are installed",
      commands = [
        "command -v git || (echo 'ERROR: git not found' && exit 1)",
        "command -v just || (echo 'ERROR: just not found' && exit 1)",
        "command -v nickel || (echo 'ERROR: nickel not found' && exit 1)",
        "echo '✓ All required tools present'",
      ],
    },

    "create-structure" = {
      description = "Create RSR directory structure",
      commands = [
        "mkdir -p src/ docs/ tests/ scripts/",
        "mkdir -p .github/workflows/",
        "mkdir -p .machine_readable/contractiles/k9/",
        "echo '✓ Directory structure created'",
      ],
    },

    "init-git" = {
      description = "Initialize Git repository",
      commands = [
        "git init -b %{config.git.default_branch}",
        "git config user.name '{{AUTHOR}}'",
        "git config user.email '{{AUTHOR_EMAIL}}'",
        "echo '✓ Git initialized'",
      ],
    },

    "setup-workflows" = {
      description = "Add RSR-compliant workflows",
      commands = [
        # This would copy workflow templates
        # In a real implementation, would fetch from rsr-template-repo
        "echo '✓ Workflows configured'",
      ],
    },

    "create-checkpoint-files" = {
      description = "Create STATE.a2ml, ECOSYSTEM.a2ml, META.a2ml",
      commands = [
        "echo '(state (version \"1.0.0\") (project \"%{config.repo_name}\"))' > STATE.a2ml",
        "echo '(ecosystem (version \"1.0.0\") (name \"%{config.repo_name}\"))' > ECOSYSTEM.a2ml",
        "echo '(meta (version \"1.0.0\") (project \"%{config.repo_name}\"))' > META.a2ml",
        "echo '✓ Checkpoint files created'",
      ],
    },

    "add-license" = {
      description = "Add PMPL-1.0 license",
      commands = [
        "curl -sL https://raw.githubusercontent.com/hyperpolymath/pmpl/main/LICENSE -o LICENSE",
        "echo '✓ License added'",
      ],
    },

    "add-readme" = {
      description = "Create README.adoc from template",
      commands = [
        "echo '= %{config.repo_name}' > README.adoc",
        "echo '' >> README.adoc",
        "echo 'Part of the Hyperpolymath ecosystem.' >> README.adoc",
        "echo '✓ README created'",
      ],
    },

    clean = {
      description = "Remove generated files (careful!)",
      commands = [
        "echo '⚠️  This will delete all generated files'",
        "echo 'Press Ctrl+C to cancel, or wait 5 seconds...'",
        "sleep 5",
        "rm -f STATE.a2ml ECOSYSTEM.a2ml META.a2ml",
        "echo '✓ Cleaned'",
      ],
    },
  },

  # Validation (Yard-level checks before Hunt execution)
  validation = {
    check_repo_name = std.string.length config.repo_name > 0,
    check_language = std.string.length config.primary_language > 0,
  },
}
