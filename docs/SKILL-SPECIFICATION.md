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

### CLEO Extension Fields (v2.0.0)

v2.0.0 introduces additional frontmatter fields for registry, dependency, and profile management:

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `version` | semver | Skill version, independent of package version | `2.0.0` |
| `tier` | number | Dispatch tier (0=orchestration, 1=planning, 2=execution, 3=specialized) | `2` |
| `core` | boolean | Required for basic CLEO operation | `true` |
| `category` | enum | Install profile grouping: `core`, `recommended`, `specialist`, `composition`, `meta` | `specialist` |
| `protocol` | string\|null | Protocol file binding from `protocols/` directory | `specification` |
| `dependencies` | string[] | Other skills required at runtime, resolved transitively by CAAMP | `["ct-docs-lookup"]` |
| `sharedResources` | string[] | `_shared/` files needed at spawn time | `["subagent-protocol-base"]` |
| `compatibility` | string[] | Supported AI agent platforms | `["claude-code", "cursor"]` |
| `license` | string | License identifier | `MIT` |

#### Complete Frontmatter Example

```yaml
---
name: ct-spec-writer
description: >-
  Technical specification writing using RFC 2119 language for clear,
  unambiguous requirements. Use when writing specifications, defining
  protocols, or creating API contracts.
version: 2.0.0
tier: 2
core: false
category: recommended
protocol: specification
dependencies: []
sharedResources:
  - subagent-protocol-base
  - task-system-integration
compatibility:
  - claude-code
  - cursor
  - windsurf
  - gemini-cli
license: MIT
---
```

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

### How Skills Use `_shared/`

Skills declare shared resource dependencies in frontmatter:

```yaml
---
name: ct-research-agent
sharedResources:
  - subagent-protocol-base      # Lifecycle rules, output format
  - task-system-integration     # Portable task commands
---
```

At spawn time, CLEO builds a protocol stack:

```
Injected into subagent (top to bottom):
┌──────────────────────────────────┐
│ SKILL.md body                    │ ← Skill-specific instructions
├──────────────────────────────────┤
│ protocols/research.md            │ ← Protocol rules (from `protocol` field)
├──────────────────────────────────┤
│ _shared/subagent-protocol-       │ ← Output rules, manifest format
│         base.md                  │
├──────────────────────────────────┤
│ _shared/task-system-             │ ← Portable task commands
│         integration.md           │
└──────────────────────────────────┘
```

This means: all 17 skills share the same lifecycle rules, output format, and task commands WITHOUT duplicating that content in each SKILL.md. A change to `_shared/subagent-protocol-base.md` automatically applies to all skills at their next spawn.

### Example: DRY Across Related Skills

The three documentation composition skills share the CLEO style guide:

| Skill | Specialized Logic | Shared via `_shared/` |
|-------|-------------------|----------------------|
| `ct-docs-lookup` | Context7 library documentation retrieval | `cleo-style-guide.md` |
| `ct-docs-write` | Markdown formatting and writing conventions | `cleo-style-guide.md` |
| `ct-docs-review` | Style compliance checking, PR review | `cleo-style-guide.md` |

Each skill's SKILL.md contains ONLY its specialized instructions. The writing style standards are defined once in `_shared/cleo-style-guide.md` and injected into all three, ensuring consistency without duplication.

See `docs/DEVELOPER-GUIDE.md` for a complete guide to creating and using shared resources.

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

### `skills.json` — CAAMP Discovery Index

Auto-generated by `scripts/build-index.sh`. CAAMP reads this for installation, discovery, and validation. **Never edit manually** — regenerate with `build-index.sh`.

#### Entry Schema

```json
{
  "name": "ct-spec-writer",
  "description": "Technical specification writing using RFC 2119 language...",
  "version": "2.0.0",
  "path": "skills/ct-spec-writer/SKILL.md",
  "references": [],
  "core": false,
  "category": "recommended",
  "tier": 2,
  "protocol": "specification",
  "dependencies": [],
  "sharedResources": ["subagent-protocol-base", "task-system-integration"],
  "compatibility": ["claude-code", "cursor", "windsurf", "gemini-cli"],
  "license": "MIT",
  "metadata": {}
}
```

#### Fields

| Field | Source | Description |
|-------|--------|-------------|
| `name` | frontmatter | Unique identifier, used by CAAMP for `install <name>` |
| `description` | frontmatter | Discovery text for search matching |
| `version` | frontmatter | Semver string for version resolution |
| `path` | derived | Relative path to SKILL.md |
| `references` | filesystem | Paths to files in `references/` |
| `core` | frontmatter | Whether CAAMP auto-installs this skill |
| `category` | frontmatter | Profile grouping (core/recommended/specialist/composition/meta) |
| `tier` | frontmatter | Dispatch priority (0-3) |
| `protocol` | frontmatter | Protocol binding, `null` if none |
| `dependencies` | frontmatter | Skills that must co-install (resolved transitively) |
| `sharedResources` | frontmatter | `_shared/` files needed at runtime |
| `compatibility` | frontmatter | Supported AI platforms |
| `license` | frontmatter | License identifier |
| `metadata` | reserved | Currently `{}` |

### `manifest.json` — CLEO Dispatch Registry

Auto-generated by `scripts/build-manifest.js` from frontmatter + `dispatch-config.json`. The CLEO orchestrator reads this for task-to-skill routing.

#### Entry Schema

```json
{
  "name": "ct-spec-writer",
  "version": "2.0.0",
  "description": "Technical specification writing...",
  "path": "skills/ct-spec-writer",
  "tags": ["specification", "documentation", "rfc"],
  "status": "active",
  "tier": 2,
  "token_budget": 8000,
  "references": ["skills/ct-spec-writer/SKILL.md"],
  "capabilities": {
    "inputs": ["TASK_ID", "SPEC_NAME", "DATE", "TOPIC_SLUG"],
    "outputs": ["specification-file", "manifest-entry"],
    "dependencies": [],
    "dispatch_triggers": ["write a spec", "create specification", "define protocol"],
    "compatible_subagent_types": ["general-purpose", "Code"],
    "chains_to": ["ct-task-executor", "ct-documentor"],
    "dispatch_keywords": {
      "primary": ["spec", "rfc", "protocol", "contract"],
      "secondary": ["specification", "requirements", "interface"]
    }
  },
  "constraints": {
    "max_context_tokens": 80000,
    "requires_session": false,
    "requires_epic": false
  }
}
```

#### Key Fields

| Field | Description |
|-------|-------------|
| `token_budget` | Maximum tokens allocated for this skill's context injection (SKILL.md + protocol + shared). Typical: 6000-8000. |
| `chains_to` | Skills this skill can invoke as follow-up. The orchestrator uses this for workflow planning. |
| `dispatch_triggers` | Exact phrases that route tasks to this skill. |
| `dispatch_keywords.primary` | High-priority matching keywords. |
| `dispatch_keywords.secondary` | Lower-priority matching keywords. |
| `max_context_tokens` | Hard limit on agent context window when running this skill. |

Both manifests derive `name` and `description` from SKILL.md frontmatter — the single source of truth for skill identity.

See `docs/DEVELOPER-GUIDE.md` for detailed manifest configuration examples and token budget guidance.

## Tier Definitions and Skill Examples

CLEO organizes skills into four hierarchical tiers. Each tier serves a distinct role in the orchestration pipeline, and skills at each tier follow different patterns.

### Tier 0: Orchestration

**Role**: Coordinates workflows. Never implements directly. Reads only manifest summaries.

**Characteristics**:
- Spawns other skills via the Task tool
- Enforces ORC-001 through ORC-008 constraints
- Manages context budget by delegating all detailed work
- Single skill: `ct-orchestrator`

```yaml
---
name: ct-orchestrator
tier: 0
core: true
category: core
protocol: agent-protocol
---
```

### Tier 1: Planning

**Role**: Analyzes, decomposes, and plans before execution begins. Outputs structure (task trees, dependency graphs) rather than implementation artifacts.

**Characteristics**:
- Creates tasks and epics, not deliverables
- Feeds the orchestrator with execution plans
- Operates in the RCSD pipeline before implementation
- Uses `cleo add` more than `cleo complete`

**Complete SKILL.md example for a Tier 1 planning skill:**

```yaml
---
name: ct-epic-architect
description: >-
  Epic planning and task decomposition for breaking down large initiatives
  into atomic, executable tasks. Provides dependency analysis, wave-based
  parallel execution planning, hierarchy management, and research linking.
  Use when creating epics, decomposing initiatives into task trees, planning
  parallel workflows, or analyzing task dependencies.
version: 3.0.0
tier: 1
core: false
category: recommended
protocol: decomposition
dependencies: []
sharedResources:
  - subagent-protocol-base
  - task-system-integration
compatibility:
  - claude-code
  - cursor
  - windsurf
  - gemini-cli
license: MIT
---
```

Body (after closing `---`):

```markdown
# Epic Architect Context Injection

**Protocol**: @protocols/decomposition.md
**Type**: Context Injection (cleo-subagent)

## Purpose

Context injection for epic planning and task decomposition. Breaks down
large initiatives into atomic, executable tasks with dependency analysis
and wave-based parallel execution planning.

## Execution Sequence

1. Read task: `{{TASK_SHOW_CMD}} {{TASK_ID}}`
2. Set focus: `{{TASK_FOCUS_CMD}} {{TASK_ID}}`
3. Analyze initiative scope
4. Create epic: `cleo add "Epic: <title>" --type epic`
5. Decompose into child tasks with dependencies
6. Establish execution waves
7. Complete: `{{TASK_COMPLETE_CMD}} {{TASK_ID}}`

## Decomposition Rules

- Each task MUST be completable by a single subagent in one session
- Maximum depth: 3 levels (epic → task → subtask)
- Maximum siblings: 7 per parent
- Each task MUST have acceptance criteria
- Group tasks into parallel execution waves

## Output

Write decomposition to: `{{OUTPUT_DIR}}/{{TASK_ID}}-decomposition.md`
```

**File placement**: `skills/ct-epic-architect/SKILL.md`

### Tier 2: Execution

**Role**: Implements, tests, validates — produces concrete deliverables. The workhorse tier.

**Characteristics**:
- Produces files, code, specifications, or reports
- Follows the subagent protocol (output file + manifest entry)
- Binds to specific protocols (implementation, research, specification, etc.)
- Receives token-resolved context from the orchestrator

```yaml
---
name: ct-task-executor
tier: 2
core: true
category: core
protocol: implementation
---
```

### Tier 3: Specialized

**Role**: Domain-specific tools, composition skills, meta skills. Often invoked by other skills rather than directly by the orchestrator.

**Characteristics**:
- May compose into larger workflows (ct-docs-lookup → ct-documentor)
- May have no protocol binding (`protocol: null`)
- Includes meta skills about the skill ecosystem itself

```yaml
---
name: ct-docs-lookup
tier: 3
core: false
category: composition
protocol: null
---
```

### Choosing the Right Tier for a New Skill

| If your skill... | Use tier |
|-------------------|---------|
| Coordinates other skills without implementing | 0 (orchestration) |
| Creates task trees, plans, or execution orders | 1 (planning) |
| Produces deliverables (code, specs, reports) | 2 (execution) |
| Is a specialized tool invoked by other skills | 3 (specialized) |

---

## Context Injection: How SKILL.md Becomes a Subagent Prompt

Skills are context injection templates, not standalone programs. The orchestrator reads a SKILL.md, resolves all tokens, assembles the protocol stack, and injects the result as the subagent's prompt.

### Token Resolution

SKILL.md files use `{{TOKEN}}` placeholders for all variable values. The orchestrator resolves these before injection:

| In SKILL.md (template) | After resolution (subagent receives) |
|------------------------|--------------------------------------|
| `{{TASK_ID}}` | `T2500` |
| `{{DATE}}` | `2026-02-12` |
| `{{TOPIC_SLUG}}` | `websocket-auth` |
| `{{OUTPUT_DIR}}` | `claudedocs/agent-outputs` |
| `{{TASK_FOCUS_CMD}} {{TASK_ID}}` | `cleo focus set T2500` |
| `{{TASK_COMPLETE_CMD}} {{TASK_ID}}` | `cleo complete T2500` |

**Critical rule**: Subagents CANNOT resolve `{{TOKEN}}` placeholders. The orchestrator MUST resolve ALL tokens before spawning.

### Protocol Stack Assembly

The orchestrator builds a layered context from multiple sources:

```
What the subagent receives (assembled top to bottom):
┌──────────────────────────────────────────────────┐
│ SKILL.md body (token-resolved)                    │  ← "How to do research"
├──────────────────────────────────────────────────┤
│ protocols/research.md (from `protocol` field)    │  ← "Research rules"
├──────────────────────────────────────────────────┤
│ _shared/subagent-protocol-base.md                │  ← "Output format"
├──────────────────────────────────────────────────┤
│ _shared/task-system-integration.md               │  ← "Task commands"
└──────────────────────────────────────────────────┘
```

The subagent sees this as a single context. It follows the skill-specific instructions at the top, with shared protocol rules available beneath.

### `@` Reference Resolution

`@` references in SKILL.md are resolved by the orchestrator at spawn time:

```markdown
## Subagent Protocol

@skills/_shared/subagent-protocol-base.md
```

This directive tells the orchestrator to read `_shared/subagent-protocol-base.md` and inline its content at this position. The subagent never sees the `@` reference — it sees the full protocol content.

### Writing Skills for Context Injection

**Use tokens for all variable values** — never hardcode task IDs, dates, or paths:

```markdown
## CORRECT — uses tokens
1. Read task: `{{TASK_SHOW_CMD}} {{TASK_ID}}`
2. Write output: `{{OUTPUT_DIR}}/{{DATE}}_{{TOPIC_SLUG}}.md`
3. Complete: `{{TASK_COMPLETE_CMD}} {{TASK_ID}}`

## WRONG — hardcoded values
1. Read task: `cleo show T1234`
2. Write output: `claudedocs/agent-outputs/2026-01-15_my-topic.md`
3. Complete: `cleo complete T1234`
```

**Document expected tokens** so the orchestrator knows what to provide:

```markdown
## Parameters (Orchestrator-Provided)

| Parameter | Description | Required |
|-----------|-------------|----------|
| `{{TASK_ID}}` | Current task identifier | Yes |
| `{{DATE}}` | Current date (YYYY-MM-DD) | Yes |
| `{{TOPIC_SLUG}}` | URL-safe topic name | Yes |
```

See `docs/DEVELOPER-GUIDE.md` for a complete before/after walkthrough of token resolution.

---

## Cross-Agent Compatibility

Skills in this repo target the broadest agent compatibility through agentskills.io compliance:

| Agent | Discovery Path | SKILL.md Support |
|-------|---------------|-----------------|
| Claude Code | `.claude/skills/` | Native |
| Codex | `.agents/skills/`, `.codex/skills/` | Native |
| Copilot | `.github/skills/` | Native |
| Others | Manual copy | Read as Markdown |

CLEO extension fields (`version`, `tier`, `core`, `category`, `protocol`, `dependencies`, `sharedResources`) are ignored by non-CLEO agents. The standard `name` and `description` fields ensure universal discoverability.
