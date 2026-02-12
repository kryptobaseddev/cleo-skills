# cleo-skills

Official skills library for the [CLEO](https://github.com/kryptobaseddev/cleo) ecosystem. A standalone package containing all CLEO-maintained skills, following the [Agent Skills Standard](https://agentskills.io/specification).

This repo is designed as a package dependency consumed by CLEO (orchestration) via CAAMP (package management). Skills are agentskills.io-compliant `SKILL.md` files that CLEO injects as context into subagent spawns.

## Architecture

```
CLEO (orchestrator) ──► CAAMP (install/manage) ──► cleo-skills (this repo)
                                                      ├── skills/         skill content
                                                      ├── _shared/        protocol infrastructure
                                                      ├── manifest.json   CLEO dispatch registry
                                                      └── skills.json     agentskills.io index
```

| Artifact | Consumer | Purpose |
|----------|----------|---------|
| `skills.json` | CAAMP | Install, discover, validate skills |
| `manifest.json` | CLEO orchestrator | Dispatch routing, token budgets, chaining |
| `_shared/` | CLEO protocol stack | DRY infrastructure injected at spawn time |
| `skills/*/SKILL.md` | Subagents | Context injection content |

## Available Skills

### Tier 0 — Orchestration

| Skill | Description |
|-------|-------------|
| [ct-orchestrator](skills/ct-orchestrator/) | Multi-agent workflow coordination with ORC constraints |

### Tier 1 — Planning

| Skill | Description |
|-------|-------------|
| [ct-epic-architect](skills/ct-epic-architect/) | Epic decomposition, task breakdown, wave planning |

### Tier 2 — Execution

| Skill | Description |
|-------|-------------|
| [ct-task-executor](skills/ct-task-executor/) | General implementation task execution |
| [ct-research-agent](skills/ct-research-agent/) | Multi-source research and investigation |
| [ct-spec-writer](skills/ct-spec-writer/) | RFC 2119 technical specification writing |
| [ct-test-writer-bats](skills/ct-test-writer-bats/) | BATS integration test creation |
| [ct-library-implementer-bash](skills/ct-library-implementer-bash/) | Bash library development |
| [ct-validator](skills/ct-validator/) | Compliance validation and auditing |
| [ct-dev-workflow](skills/ct-dev-workflow/) | Task-driven development workflow and releases |
| [ct-contribution-protocol](skills/ct-contribution-protocol/) | Contribution workflow and protocol enforcement |

### Tier 3 — Specialized

| Skill | Description |
|-------|-------------|
| [ct-documentor](skills/ct-documentor/) | Documentation orchestration (lookup → write → review) |
| [ct-docs-lookup](skills/ct-docs-lookup/) | Library documentation lookup via Context7 |
| [ct-docs-write](skills/ct-docs-write/) | Documentation writing with style guide compliance |
| [ct-docs-review](skills/ct-docs-review/) | Documentation review and style checking |
| [ct-skill-creator](skills/ct-skill-creator/) | Guide for creating new skills |
| [ct-skill-lookup](skills/ct-skill-lookup/) | Skill discovery and marketplace search |

### Standalone — Universal

| Skill | Description |
|-------|-------------|
| [ct-gitbook](skills/ct-gitbook/) | GitBook platform guide (no CLEO dependencies) |

## Installation

### Via CAAMP (recommended)

```bash
# Install a specific skill
caamp skills install /path/to/cleo-skills/skills/ct-gitbook

# CAAMP handles versioning, validation, and symlink creation
```

### Manual

Copy or symlink a skill directory into your agent's skills location:

```bash
# Claude Code
cp -r skills/ct-gitbook ~/.claude/skills/ct-gitbook

# Codex
cp -r skills/ct-gitbook .agents/skills/ct-gitbook

# Copilot (VS Code)
cp -r skills/ct-gitbook .github/skills/ct-gitbook
```

## Project Structure

```
cleo-skills/
├── skills.json                  # agentskills.io index (auto-generated)
├── manifest.json                # CLEO dispatch registry (manual)
├── scripts/
│   └── build-index.sh           # Validates skills + generates skills.json
├── docs/
│   └── SKILL-SPECIFICATION.md   # Skill authoring guidelines
├── skills/
│   ├── _shared/                 # CLEO protocol infrastructure (not a skill)
│   │   ├── subagent-protocol-base.md
│   │   ├── manifest-operations.md
│   │   ├── task-system-integration.md
│   │   ├── skill-chaining-patterns.md
│   │   ├── testing-framework-config.md
│   │   ├── cleo-style-guide.md
│   │   └── placeholders.json
│   ├── ct-gitbook/              # Skill with references/ and assets/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   └── assets/
│   ├── ct-orchestrator/         # Skill with references/
│   │   ├── SKILL.md
│   │   └── references/
│   └── ct-*/                    # Other skills (SKILL.md only)
└── LICENSE
```

## Adding a New Skill

1. Create a directory under `skills/` matching your skill name
2. Add a `SKILL.md` with valid YAML frontmatter (`name`, `description` required)
3. Add `references/`, `scripts/`, or `assets/` as needed for progressive disclosure
4. Add an entry to `manifest.json` if the skill needs CLEO dispatch routing
5. Run the index builder to validate and update `skills.json`:

```bash
bash scripts/build-index.sh
```

See [docs/SKILL-SPECIFICATION.md](docs/SKILL-SPECIFICATION.md) for the full specification.

## Dual Manifest Design

This repo maintains two manifests that serve different consumers:

**`skills.json`** (auto-generated) — agentskills.io standard index. CAAMP reads this for installation, discovery, and validation. Contains: name, description, path, references list. Generated by `scripts/build-index.sh` from SKILL.md frontmatter.

**`manifest.json`** (manual) — CLEO dispatch registry. The orchestrator reads this to route tasks to skills. Contains: dispatch triggers, keyword mappings, token budgets, tier levels, chaining rules, capability declarations. This is operational metadata that doesn't belong in the agentskills.io standard.

The shared fields (`name`, `description`) both derive from SKILL.md frontmatter — the single source of truth for skill identity.

## License

MIT
