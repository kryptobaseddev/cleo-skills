# Skill Specification

Strict guidelines for all skills in this repository, adhering to the [Agent Skills Standard](https://agentskills.io/specification).

## Frontmatter Rules

Every `SKILL.md` must begin with a YAML frontmatter block delimited by `---`.

### Required Fields (agentskills.io standard)

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | Max 64 chars. Lowercase `a-z`, `0-9`, `-` only. No leading, trailing, or consecutive hyphens. Must match parent directory name. |
| `description` | Yes | Max 1024 chars. Non-empty. Must describe what the skill does AND when to use it. Include trigger keywords for agent discovery. |

### Optional Fields (agentskills.io standard)

| Field | Constraints |
|-------|-------------|
| `license` | License name or reference to bundled file. |
| `compatibility` | Max 500 chars. Environment requirements if any. |
| `metadata` | Arbitrary key-value map (string to string). |
| `allowed-tools` | Space-delimited tool list (experimental, agent-specific). |

### CLEO Extension Fields

CLEO skills may include additional frontmatter fields beyond the agentskills.io standard. These are consumed by the CLEO orchestrator and ignored by other agents.

| Field | Purpose |
|-------|---------|
| `version` | Skill version (also tracked in `manifest.json`) |
| `tier` | Dispatch tier (0=orchestration, 1=planning, 2=execution, 3=specialized) |

These fields do not affect agentskills.io compliance. The `name` and `description` fields remain the canonical identity consumed by all agents.

### Name Validation

Pattern: `/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/`

- Minimum 1 character, maximum 64 characters
- Only lowercase letters, digits, and single hyphens
- Cannot start or end with a hyphen
- No consecutive hyphens (`--`)
- Directory name must exactly match the `name` field

### Description Guidelines

The description serves as the primary discovery mechanism across agents. It must:

1. State what the skill does (capability keywords)
2. State when to use it (trigger phrases)
3. Include specific tool/platform names for matching
4. Stay under 1024 characters

## Directory Structure

```
skill-name/
├── SKILL.md              # Required
├── references/           # Optional, deep-dive documentation
│   ├── topic-a.md
│   └── topic-b.md
├── scripts/              # Optional, executable helpers
└── assets/               # Optional, templates or data files
```

### Rules

- `SKILL.md` is required at the skill root
- File references from SKILL.md must be one level deep (no nested chains like `references/sub/file.md`)
- Reference files should be Markdown
- No executable code in `SKILL.md` body beyond illustrative examples

## `_shared/` — Protocol Infrastructure

The `_shared/` directory is **not a skill**. It contains CLEO protocol infrastructure loaded by the CLEO system at spawn time. Skills do not reference `_shared/` directly — CLEO injects these files as part of the protocol stack beneath the selected skill.

```
_shared/
├── subagent-protocol-base.md      # Base lifecycle for all subagent spawns
├── manifest-operations.md         # Manifest file operations
├── task-system-integration.md     # Task system integration patterns
├── skill-chaining-patterns.md     # Patterns for skill-to-skill chaining
├── testing-framework-config.md    # Testing framework configuration
├── cleo-style-guide.md            # CLEO writing style guide
└── placeholders.json              # Token placeholder definitions
```

### Why `_shared/` Exists

CLEO's 2-tier architecture injects a protocol stack into every subagent spawn:

```
┌─────────────────────────────────┐
│ SKILL.md (task-specific)        │  ← from skills/ct-*/
├─────────────────────────────────┤
│ Protocol base + shared context  │  ← from _shared/
└─────────────────────────────────┘
```

This enforces DRY: shared constraints, lifecycle rules, and style guidance are defined once in `_shared/` and injected into every spawn, rather than duplicated across 17 SKILL.md files.

### Rules for `_shared/`

- Files are consumed by CLEO, not by skills or agents directly
- No `SKILL.md` — this directory is excluded from `build-index.sh` and `skills.json`
- Changes to `_shared/` affect all skills at spawn time
- `placeholders.json` defines the `{{TOKEN}}` vocabulary available to all skills

## Progressive Disclosure

Skills load in three tiers to manage context budgets:

| Tier | Content | Token Budget | When Loaded |
|------|---------|-------------|-------------|
| Metadata | `name` + `description` | ~100 tokens | Startup (all skills) |
| Instructions | Full SKILL.md body | <5000 tokens | On activation |
| Resources | `references/`, `scripts/`, `assets/` | On-demand | When referenced |

### Body Size Limits

- SKILL.md body: under 500 lines (hard limit for this repo)
- Recommended: under 5000 tokens
- Move detailed content to `references/` for progressive disclosure

## Validation Requirements

All skills must pass these checks:

1. **Name pattern**: Matches `/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/`
2. **No consecutive hyphens**: Name contains no `--`
3. **Directory match**: Parent directory name equals frontmatter `name`
4. **Description present**: Non-empty, under 1024 characters
5. **Body length**: Under 500 lines
6. **References depth**: All referenced files are one level deep from SKILL.md

Run validation:

```bash
bash scripts/build-index.sh
```

## Dual Manifest System

This repo maintains two manifests for different consumers:

### `skills.json` — agentskills.io Index

Auto-generated by `scripts/build-index.sh`. CAAMP reads this for installation, discovery, and validation.

Contains: `name`, `description`, `path`, `references` list.

**Never edit manually** — regenerate with `build-index.sh`.

### `manifest.json` — CLEO Dispatch Registry

Manually maintained. The CLEO orchestrator reads this for task-to-skill routing.

Contains: dispatch triggers, keyword mappings, token budgets, tier levels, chaining rules, capability declarations.

Both manifests derive `name` and `description` from SKILL.md frontmatter — the single source of truth for skill identity.

## Cross-Agent Compatibility

Skills in this repo target the broadest agent compatibility through agentskills.io compliance:

| Agent | Discovery Path | SKILL.md Support |
|-------|---------------|-----------------|
| Claude Code | `.claude/skills/` | Native |
| Codex | `.agents/skills/`, `.codex/skills/` | Native |
| Copilot | `.github/skills/` | Native |
| Others | Manual copy | Read as Markdown |

CLEO extension fields (`version`, `tier`) are ignored by non-CLEO agents. The standard `name` and `description` fields ensure universal discoverability.
