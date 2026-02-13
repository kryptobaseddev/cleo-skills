# CLEO Skills Developer Guide

Practical guide for developing, configuring, and integrating CLEO Skills. Covers skill creation, manifest configuration, registry integration, and shared infrastructure patterns with concrete, working examples.

---

## Creating a New Skill: End-to-End Example

This walkthrough creates a skill that automates technical specification generation for software components.

### Step 1: Create the Directory

```
skills/ct-spec-generator/
├── SKILL.md              # Required — skill definition
├── references/           # Optional — supplementary docs
│   └── spec-templates.md
└── assets/               # Optional — template files
    └── spec-template.md
```

### Step 2: Write the SKILL.md with Frontmatter

```yaml
---
name: ct-spec-generator
description: >-
  Automates generation of technical specifications for software components.
  Use when the user asks to "generate a spec", "create technical specification",
  "document component architecture", "write API spec", or needs automated
  specification output from code analysis. Triggers on specification generation
  tasks, component documentation needs, or architecture documentation requests.
version: 1.0.0
tier: 2
core: false
category: specialist
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

### Step 3: Write the SKILL.md Body (Agent Instructions)

The body after the closing `---` contains the actual instructions the AI agent follows. This is the implementation logic — it tells the agent *how* to generate specifications.

```markdown
# Specification Generator Context Injection

**Protocol**: @protocols/specification.md
**Type**: Context Injection (cleo-subagent)
**Version**: 1.0.0

---

## Purpose

Context injection for automated technical specification generation. Analyzes source
code, API surfaces, and architecture patterns to produce structured specification
documents following RFC 2119 language.

---

## Workflow

### Phase 1: Analysis

1. Read the target component source files
2. Identify public API surfaces (exports, endpoints, interfaces)
3. Map dependencies and integration points
4. Catalog configuration options and defaults

### Phase 2: Generation

1. Apply the specification template from `assets/spec-template.md`
2. Fill in component metadata (name, version, purpose)
3. Document each public API with:
   - Function signature or endpoint path
   - Parameter descriptions with types
   - Return value specification
   - Error conditions
   - Usage examples
4. Document configuration options with defaults and constraints
5. List dependencies with version requirements

### Phase 3: Validation

1. Verify all public APIs are documented
2. Check that RFC 2119 keywords (MUST, SHOULD, MAY) are used correctly
3. Validate all code examples compile/run
4. Ensure cross-references resolve

---

## Output Format

Write specification to: `{{OUTPUT_DIR}}/{{TASK_ID}}-{{TOPIC_SLUG}}.md`

### Specification Template

The output MUST follow this structure:

# [Component Name] Technical Specification

**Version**: [version]
**Date**: {{DATE}}
**Status**: Draft | Review | Approved
**Task**: {{TASK_ID}}

## 1. Overview

[2-3 sentence summary of the component's purpose and scope]

## 2. API Reference

### 2.1 [Function/Endpoint Name]

**Signature**: `functionName(param1: Type, param2: Type): ReturnType`

**Description**: [What this API does]

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| param1 | string | Yes | [description] |
| param2 | number | No | [description, default: 0] |

**Returns**: [Description of return value]

**Errors**:
| Code | Condition | Description |
|------|-----------|-------------|
| ERR_NOT_FOUND | Item missing | [description] |

**Example**:
```js
const result = functionName('input', 42);
```

## 3. Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| timeout | number | 30000 | Request timeout in ms |

## 4. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| lodash | ^4.17.0 | Utility functions |

---

## Task Integration

Before starting work:
```bash
{{TASK_FOCUS_CMD}} {{TASK_ID}}
```

After generating the specification:
```bash
# Append manifest entry
echo '{"id":"{{TASK_ID}}-spec","file":"{{OUTPUT_DIR}}/{{TASK_ID}}-{{TOPIC_SLUG}}.md","title":"[Component] Specification","date":"{{DATE}}","status":"complete","agent_type":"specification","topics":["specification","api-docs"],"key_findings":["Generated spec for [component]"],"actionable":true,"needs_followup":[],"linked_tasks":["{{EPIC_ID}}","{{TASK_ID}}"]}' >> {{MANIFEST_PATH}}

# Complete the task
{{TASK_COMPLETE_CMD}} {{TASK_ID}}
```
```

### Step 4: Register in manifest.json

After creating the skill, add it to `manifest.json` (or to `dispatch-config.json` if using auto-generation). See the [Manifest Configuration](#manifest-configuration) section below for the full entry format.

### Step 5: Run the Build

```bash
# Validate frontmatter and generate skills.json
bash scripts/build-index.sh

# Regenerate manifest.json from frontmatter + dispatch config
node scripts/build-manifest.js
```

Expected output:
```
OK: ct-spec-generator (v1.0.0 tier:2 core:false cat:specialist proto:specification 85 lines, 380 char desc, 1 refs)
```

---

## Frontmatter Field Reference

Every SKILL.md requires YAML frontmatter. Here is the complete field reference with v2.0.0 extensions:

| Field | Required | Type | Description | Example |
|-------|----------|------|-------------|---------|
| `name` | Yes | string | Unique identifier, must match directory name. Lowercase `a-z0-9-`, max 64 chars. | `ct-spec-generator` |
| `description` | Yes | string | What the skill does AND when to use it. Max 1024 chars. Include trigger keywords. | `Automates generation of technical specifications...` |
| `version` | Recommended | semver | Skill version independent of package version. | `1.0.0` |
| `tier` | Recommended | number | Dispatch tier: 0=orchestration, 1=planning, 2=execution, 3=specialized | `2` |
| `core` | Recommended | boolean | Whether this skill is required for basic CLEO operation. | `false` |
| `category` | Recommended | enum | One of: `core`, `recommended`, `specialist`, `composition`, `meta` | `specialist` |
| `protocol` | Optional | string\|null | Which protocol file this skill binds to (from `protocols/`). | `specification` |
| `dependencies` | Recommended | string[] | Other ct-* skills this skill requires to function. | `["ct-docs-lookup"]` |
| `sharedResources` | Optional | string[] | `_shared/` files this skill needs at spawn time. | `["subagent-protocol-base"]` |
| `compatibility` | Optional | string[] | Which AI agents support this skill. | `["claude-code", "cursor"]` |
| `license` | Optional | string | License identifier. | `MIT` |

### Category Definitions

| Category | Description | Core? | Examples |
|----------|-------------|-------|---------|
| `core` | Required for basic CLEO operation | `true` | ct-orchestrator, ct-task-executor |
| `recommended` | RCSD pipeline skills for standard workflows | `false` | ct-epic-architect, ct-research-agent, ct-spec-writer, ct-validator |
| `specialist` | Domain-specific execution skills | `false` | ct-dev-workflow, ct-test-writer-bats, ct-library-implementer-bash, ct-documentor |
| `composition` | Skills that compose into larger workflows | `false` | ct-docs-lookup, ct-docs-write, ct-docs-review |
| `meta` | Skills about skills and ecosystem tools | `false` | ct-skill-creator, ct-skill-lookup, ct-contribution, ct-gitbook |

---

## `skills.json` — CAAMP Discovery Index

`skills.json` is **auto-generated** by `scripts/build-index.sh` from SKILL.md frontmatter. CAAMP reads this file for skill discovery, installation, and validation. **Never edit manually.**

### Complete Entry Schema

Each skill entry in `skills.json` has this structure:

```json
{
  "name": "ct-spec-generator",
  "description": "Automates generation of technical specifications for software components. Use when the user asks to \"generate a spec\", \"create technical specification\", or needs automated specification output.",
  "version": "1.0.0",
  "path": "skills/ct-spec-generator/SKILL.md",
  "references": [
    "skills/ct-spec-generator/references/spec-templates.md"
  ],
  "core": false,
  "category": "specialist",
  "tier": 2,
  "protocol": "specification",
  "dependencies": [],
  "sharedResources": ["subagent-protocol-base", "task-system-integration"],
  "compatibility": ["claude-code", "cursor", "windsurf", "gemini-cli"],
  "license": "MIT",
  "metadata": {}
}
```

### Field Descriptions

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `name` | string | frontmatter `name` | Unique skill identifier. Used by CAAMP for `install <name>`. |
| `description` | string | frontmatter `description` | Discovery text. CAAMP uses this for search matching. |
| `version` | string | frontmatter `version` | Semver string. CAAMP uses for version resolution. Default: `"1.0.0"`. |
| `path` | string | derived | Relative path to SKILL.md from repo root. |
| `references` | string[] | filesystem scan | Relative paths to all files in `references/` directory. |
| `core` | boolean | frontmatter `core` | Whether CAAMP should auto-install this skill. Default: `false`. |
| `category` | string | frontmatter `category` | Install profile grouping. One of: `core`, `recommended`, `specialist`, `composition`, `meta`. |
| `tier` | number | frontmatter `tier` | Dispatch priority tier (0-3). Default: `2`. |
| `protocol` | string\|null | frontmatter `protocol` | Protocol binding for dispatch. `null` if no protocol binding. |
| `dependencies` | string[] | frontmatter `dependencies` | Skills that must be installed alongside this one. CAAMP resolves transitively. |
| `sharedResources` | string[] | frontmatter `sharedResources` | `_shared/` files needed at runtime. CAAMP ensures these are available. |
| `compatibility` | string[] | frontmatter `compatibility` | AI agent platforms that can use this skill. |
| `license` | string | frontmatter `license` | License identifier. Default: `"MIT"`. |
| `metadata` | object | reserved | Reserved for future use. Currently `{}`. |

### How CAAMP Uses skills.json

```
CAAMP install ct-spec-generator
  │
  ├── 1. Read skills.json from @cleocode/ct-skills package
  ├── 2. Find entry where name === "ct-spec-generator"
  ├── 3. Resolve dependencies transitively (dependencies field)
  ├── 4. Copy skill directory + _shared/ to ~/.agents/skills/
  └── 5. Validate frontmatter against schema
```

### Validation Rules Applied by build-index.sh

| Rule | Field | Enforcement |
|------|-------|-------------|
| Name pattern | `name` | Must match `/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/` |
| No consecutive hyphens | `name` | Must not contain `--` |
| Directory match | `name` | Parent directory must equal name |
| Description exists | `description` | Non-empty, max 1024 chars |
| Body length | SKILL.md | Under 500 lines |
| Category valid | `category` | Must be one of the 5 allowed values |
| Dependencies exist | `dependencies` | Each entry must reference a valid skill directory |

### Example: Core Skill Entry

```json
{
  "name": "ct-task-executor",
  "description": "General implementation task execution for completing assigned CLEO tasks by following instructions and producing concrete deliverables.",
  "version": "2.0.0",
  "path": "skills/ct-task-executor/SKILL.md",
  "references": [],
  "core": true,
  "category": "core",
  "tier": 2,
  "protocol": "implementation",
  "dependencies": [],
  "sharedResources": ["subagent-protocol-base", "task-system-integration"],
  "compatibility": ["claude-code", "cursor", "windsurf", "gemini-cli"],
  "license": "MIT",
  "metadata": {}
}
```

### Example: Skill with Dependencies

```json
{
  "name": "ct-documentor",
  "description": "Documentation creation, editing, and review with CLEO style guide compliance. Coordinates specialized skills for lookup, writing, and review.",
  "version": "3.0.0",
  "path": "skills/ct-documentor/SKILL.md",
  "references": [],
  "core": false,
  "category": "specialist",
  "tier": 3,
  "protocol": null,
  "dependencies": ["ct-docs-lookup", "ct-docs-write", "ct-docs-review"],
  "sharedResources": ["subagent-protocol-base", "task-system-integration"],
  "compatibility": ["claude-code", "cursor", "windsurf", "gemini-cli"],
  "license": "MIT",
  "metadata": {}
}
```

When CAAMP installs `ct-documentor`, it also installs `ct-docs-lookup`, `ct-docs-write`, and `ct-docs-review` because they are listed in `dependencies`.

### Programmatic Access via Node.js API

```js
const { skills, getSkill, getCoreSkills, getSkillsByCategory } = require('@cleocode/ct-skills');

// Get all skills
console.log(skills.length); // 17

// Find a specific skill
const spec = getSkill('ct-spec-writer');
console.log(spec.version);       // "2.0.0"
console.log(spec.protocol);      // "specification"
console.log(spec.dependencies);  // []

// Get core skills only
const core = getCoreSkills();
console.log(core.map(s => s.name)); // ["ct-orchestrator", "ct-task-executor"]

// Filter by category
const recommended = getSkillsByCategory('recommended');
// ["ct-epic-architect", "ct-research-agent", "ct-spec-writer", "ct-validator"]
```

---

## Manifest Configuration

`manifest.json` is the CLEO orchestrator's dispatch registry. It controls how the orchestrator routes tasks to skills, manages token budgets, and defines chaining constraints.

### Generation

As of v2.0.0, `manifest.json` is auto-generated from two sources:

1. **SKILL.md frontmatter** — provides `name`, `version`, `description`, `tier`, `dependencies`
2. **`dispatch-config.json`** — provides routing rules, token budgets, chaining, capabilities

Run `node scripts/build-manifest.js` to merge these into `skills/manifest.json`.

### Complete Skill Entry Schema

Each skill in `manifest.json` has this structure. Here is a fully annotated example:

```json
{
  "name": "ct-spec-generator",
  "version": "1.0.0",
  "description": "Automates generation of technical specifications...",
  "path": "skills/ct-spec-generator",
  "tags": ["specification", "documentation", "automation"],
  "status": "active",
  "tier": 2,
  "token_budget": 8000,
  "references": [
    "skills/ct-spec-generator/SKILL.md",
    "skills/ct-spec-generator/references/spec-templates.md"
  ],
  "capabilities": {
    "inputs": ["TASK_ID", "component_path", "output_format", "DATE", "TOPIC_SLUG"],
    "outputs": ["specification-file", "manifest-entry"],
    "dependencies": [],
    "dispatch_triggers": [
      "generate a spec",
      "create technical specification",
      "document component architecture",
      "write API spec",
      "automated specification"
    ],
    "compatible_subagent_types": ["general-purpose", "Code"],
    "chains_to": ["ct-documentor", "ct-validator"],
    "dispatch_keywords": {
      "primary": ["spec", "specification", "generate", "technical"],
      "secondary": ["api-docs", "architecture", "component", "automated"]
    }
  },
  "constraints": {
    "max_context_tokens": 80000,
    "requires_session": false,
    "requires_epic": false
  }
}
```

### Field Reference

#### Top-Level Fields

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `name` | string | frontmatter | Skill identifier, matches directory name |
| `version` | string | frontmatter | Semver skill version |
| `description` | string | frontmatter | Human-readable description |
| `path` | string | derived | Relative path to skill directory |
| `tags` | string[] | dispatch-config | Categorization tags for search and filtering |
| `status` | string | dispatch-config | `"active"`, `"deprecated"`, or `"experimental"` |
| `tier` | number | frontmatter | Dispatch tier (0-3) |
| `token_budget` | number | dispatch-config | **Maximum tokens the orchestrator allocates for this skill's context injection.** Includes SKILL.md body + protocol base + shared resources. Typical values: 6000 (simple), 8000 (standard), 12000 (complex). |
| `references` | string[] | filesystem | Paths to all skill files |

#### Capabilities Object

| Field | Type | Description |
|-------|------|-------------|
| `inputs` | string[] | Token placeholders this skill expects (from `placeholders.json`) |
| `outputs` | string[] | Types of artifacts this skill produces |
| `dependencies` | string[] | Other skills required at runtime |
| `dispatch_triggers` | string[] | Exact phrases that trigger this skill in the dispatch matrix |
| `compatible_subagent_types` | string[] | Agent types that can execute this skill |
| `chains_to` | string[] | **Skills this skill can invoke as follow-up steps.** The orchestrator uses this to plan multi-step workflows. For example, `ct-spec-generator` chains to `ct-validator` for post-generation validation. |
| `dispatch_keywords` | object | Primary and secondary keywords for fuzzy dispatch matching |

#### Constraints Object

| Field | Type | Description |
|-------|------|-------------|
| `max_context_tokens` | number | Hard limit on the agent's context window when running this skill |
| `requires_session` | boolean | Whether the skill needs an active CLEO session |
| `requires_epic` | boolean | Whether the skill needs a parent epic for context |

### Token Budget Configuration

The `token_budget` field controls how much context the orchestrator allocates when injecting a skill into a subagent spawn:

```
Token Budget Breakdown:
┌─────────────────────────────────────────────────┐
│ token_budget: 8000                              │
│                                                 │
│ ┌───────────────────────────┐ ~3000 tokens      │
│ │ SKILL.md body             │                   │
│ ├───────────────────────────┤ ~2000 tokens      │
│ │ subagent-protocol-base.md │ (from _shared/)   │
│ ├───────────────────────────┤ ~1500 tokens      │
│ │ task-system-integration   │ (from _shared/)   │
│ ├───────────────────────────┤ ~1000 tokens      │
│ │ Protocol file             │ (from protocols/) │
│ ├───────────────────────────┤ ~500 tokens       │
│ │ Token overhead + metadata │                   │
│ └───────────────────────────┘                   │
└─────────────────────────────────────────────────┘
```

**Recommended token_budget values:**

| Complexity | Budget | Use Case |
|------------|--------|----------|
| 6000 | Simple skills with short SKILL.md and no protocol binding | ct-docs-lookup, ct-skill-lookup |
| 8000 | Standard skills with full protocol stack | ct-task-executor, ct-research-agent |
| 10000 | Complex skills with extensive references | ct-orchestrator |
| 12000+ | Skills needing multiple reference files loaded | Rare, requires justification |

If a skill exceeds its token budget at spawn time, the orchestrator truncates reference files first, then the SKILL.md body, preserving the protocol base.

### Chaining Constraints

The `chains_to` field defines which skills can follow this one in a workflow:

```json
{
  "name": "ct-research-agent",
  "capabilities": {
    "chains_to": ["ct-spec-writer", "ct-epic-architect"]
  }
}
```

This means: after `ct-research-agent` completes, the orchestrator may spawn `ct-spec-writer` or `ct-epic-architect` as the next step.

**Chaining rules:**

1. **Empty array** (`[]`) means the skill is a terminal node — no automatic follow-up
2. **Listed skills** are suggestions, not requirements — the orchestrator decides based on task context
3. **Bidirectional chaining** is allowed (A chains to B and B chains to A) but should be used carefully
4. **The orchestrator reads `chains_to`** when planning wave-based parallel execution

### Dispatch Matrix

The dispatch matrix maps task types, keywords, and protocols to skills:

```json
{
  "dispatch_matrix": {
    "by_task_type": {
      "specification": "ct-spec-writer",
      "research": "ct-research-agent",
      "implementation": "ct-task-executor"
    },
    "by_keyword": {
      "spec|rfc|protocol|contract": "ct-spec-writer",
      "research|investigate|explore": "ct-research-agent"
    },
    "by_protocol": {
      "specification": "ct-spec-writer",
      "research": "ct-research-agent",
      "implementation": "ct-task-executor"
    }
  }
}
```

**Dispatch priority**: `by_protocol` > `by_task_type` > `by_keyword`

### Adding a New Skill to dispatch-config.json

To add `ct-spec-generator` to the dispatch routing:

```json
// In dispatch-config.json
{
  "dispatch_matrix": {
    "by_task_type": {
      "spec-generation": "ct-spec-generator"
    },
    "by_keyword": {
      "generate spec|auto-spec|component spec": "ct-spec-generator"
    },
    "by_protocol": {
      "specification": "ct-spec-generator"
    }
  },
  "skill_overrides": {
    "ct-spec-generator": {
      "tags": ["specification", "documentation", "automation"],
      "status": "active",
      "token_budget": 8000,
      "capabilities": {
        "inputs": ["TASK_ID", "component_path", "DATE", "TOPIC_SLUG"],
        "outputs": ["specification-file", "manifest-entry"],
        "dispatch_triggers": ["generate a spec", "create technical specification"],
        "compatible_subagent_types": ["general-purpose", "Code"],
        "chains_to": ["ct-validator"],
        "dispatch_keywords": {
          "primary": ["spec", "generate", "specification"],
          "secondary": ["api-docs", "component", "automated"]
        }
      },
      "constraints": {
        "max_context_tokens": 80000,
        "requires_session": false,
        "requires_epic": false
      }
    }
  }
}
```

Then regenerate: `node scripts/build-manifest.js`

---

## Leveraging `_shared/` for DRY Principles

The `skills/_shared/` directory contains protocol infrastructure that CLEO injects at spawn time beneath every skill. This eliminates duplication across the 17+ skills in the registry.

### Architecture

```
Every subagent spawn receives this protocol stack:

┌─────────────────────────────────────────────────┐
│ SKILL.md                                         │  ← Skill-specific
│ (ct-spec-writer, ct-research-agent, etc.)       │     instructions
├─────────────────────────────────────────────────┤
│ Protocol file (from protocols/)                  │  ← Protocol-specific
│ (specification.md, research.md, etc.)           │     rules
├─────────────────────────────────────────────────┤
│ subagent-protocol-base.md (from _shared/)       │  ← Universal lifecycle
│ - Output requirements (OUT-001 through OUT-004) │     rules for ALL
│ - Manifest entry format                          │     subagents
│ - Error handling protocol                        │
├─────────────────────────────────────────────────┤
│ task-system-integration.md (from _shared/)      │  ← Portable task
│ - {{TASK_SHOW_CMD}}, {{TASK_FOCUS_CMD}}, etc.   │     commands
├─────────────────────────────────────────────────┤
│ placeholders.json (from _shared/)               │  ← Token registry
│ - All {{TOKEN}} definitions                     │     (50+ tokens)
└─────────────────────────────────────────────────┘
```

### What `_shared/` Contains

| File | Purpose | Used By |
|------|---------|---------|
| `subagent-protocol-base.md` | RFC 2119 output rules, manifest format, lifecycle phases | All skills with `sharedResources: ["subagent-protocol-base"]` |
| `task-system-integration.md` | Portable task commands using `{{TOKEN}}` placeholders | All skills with `sharedResources: ["task-system-integration"]` |
| `manifest-operations.md` | MANIFEST.jsonl append format and conventions | Skills that produce manifest entries |
| `skill-chaining-patterns.md` | Patterns for multi-level skill invocation | Skills that chain to other skills |
| `testing-framework-config.md` | Testing framework setup across 16 frameworks | Skills that run tests |
| `cleo-style-guide.md` | Writing conventions for documentation | Documentation skills (ct-docs-write, ct-docs-review) |
| `placeholders.json` | Token placeholder registry (50+ tokens) | All skills — defines the `{{TOKEN}}` vocabulary |

### How DRY Works in Practice

**Without `_shared/`** (anti-pattern): every skill would duplicate lifecycle rules:

```markdown
# ct-research-agent/SKILL.md
... 50 lines of output rules ...
... 30 lines of manifest format ...
... 20 lines of task commands ...
... actual research instructions ...

# ct-spec-writer/SKILL.md
... same 50 lines of output rules ...    ← DUPLICATED
... same 30 lines of manifest format ... ← DUPLICATED
... same 20 lines of task commands ...   ← DUPLICATED
... actual spec-writing instructions ...
```

**With `_shared/`** (correct): shared content is defined once and injected:

```markdown
# ct-research-agent/SKILL.md
# (only contains research-specific instructions)
## Research Workflow
1. Gather sources
2. Synthesize findings
3. Write output file
# (lifecycle rules, manifest format, task commands are injected by CLEO from _shared/)

# ct-spec-writer/SKILL.md
# (only contains spec-writing instructions)
## Specification Workflow
1. Analyze component
2. Generate spec document
3. Validate completeness
# (same shared infrastructure injected automatically)
```

### Declaring Shared Resource Dependencies

Skills declare which `_shared/` files they need via the `sharedResources` frontmatter field:

```yaml
---
name: ct-research-agent
sharedResources:
  - subagent-protocol-base      # Lifecycle rules, output format
  - task-system-integration     # Task commands (focus, complete, etc.)
---
```

When the orchestrator spawns this skill, it reads `sharedResources` and loads those files from `_shared/` into the protocol stack beneath the SKILL.md content.

### Example: Three Related Documentation Skills

The documentation skills demonstrate DRY across related skills:

```
                    ┌─────────────────────┐
                    │   ct-documentor     │ ← Orchestrates all three
                    │ dependencies:       │
                    │   - ct-docs-lookup  │
                    │   - ct-docs-write   │
                    │   - ct-docs-review  │
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │ct-docs-lookup│ │ct-docs-write │ │ct-docs-review│
    │              │ │              │ │              │
    │ sharedRes:[] │ │ sharedRes:[] │ │ sharedRes:[] │
    │ (uses style  │ │ (uses style  │ │ (uses style  │
    │  guide via   │ │  guide via   │ │  guide via   │
    │  _shared/)   │ │  _shared/)   │ │  _shared/)   │
    └──────────────┘ └──────────────┘ └──────────────┘
```

Each skill contains ONLY its specialized logic:
- **ct-docs-lookup**: How to use Context7 for library documentation retrieval
- **ct-docs-write**: Writing conventions and markdown formatting rules
- **ct-docs-review**: Style guide compliance checking and PR review workflow

The shared CLEO style guide (`_shared/cleo-style-guide.md`) is injected into all three, ensuring consistent writing standards without any duplication.

### Using Placeholders for Portable Commands

Instead of hardcoding CLEO commands, skills use `{{TOKEN}}` placeholders defined in `_shared/placeholders.json`:

```markdown
# WRONG — hardcoded commands (breaks in non-CLEO agents)
Run `cleo focus set T1234` before starting work.
When done, run `cleo complete T1234`.

# CORRECT — portable tokens (works in any compatible agent)
Run `{{TASK_FOCUS_CMD}} {{TASK_ID}}` before starting work.
When done, run `{{TASK_COMPLETE_CMD}} {{TASK_ID}}`.
```

The orchestrator resolves all `{{TOKEN}}` placeholders before injecting the skill into a subagent. The subagent receives concrete values:

```markdown
# What the subagent actually sees after token resolution:
Run `cleo focus set T1234` before starting work.
When done, run `cleo complete T1234`.
```

### Creating New Shared Resources: Complete Walkthrough

This walkthrough creates a new shared resource from scratch and shows how multiple skills consume it to eliminate duplication.

**Scenario**: Three skills (`ct-task-executor`, `ct-library-implementer-bash`, `ct-test-writer-bats`) all need the same code quality checklist before completing work. Without a shared resource, each SKILL.md would duplicate the checklist.

#### Step 1: Identify the Duplicated Content

Here is the content that would be duplicated across three skills without `_shared/`:

```markdown
## Code Quality Checklist

Before completing work, verify all items pass:

### Required Checks
- [ ] All changed files have consistent formatting
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Error handling covers all failure paths
- [ ] Public functions have descriptive names and parameter types

### Conditional Checks
- [ ] If adding dependencies: justified and version-pinned
- [ ] If modifying APIs: backwards-compatible or migration documented
- [ ] If touching security-sensitive code: input validation present

### Completion Gate
All "Required Checks" MUST pass. Conditional checks apply only when relevant.
If any required check fails, set manifest `"status": "partial"` with details
in `needs_followup`.
```

This is ~20 lines of content. Duplicated across 3 skills = 60 lines. Duplicated across 10 execution skills = 200 lines. Changes require updating every copy.

#### Step 2: Create the Shared Resource File

Write the content to `skills/_shared/code-quality-checklist.md`:

```markdown
# Code Quality Checklist

**Injected by**: CLEO orchestrator at spawn time
**Consumed by**: Execution-tier skills via `sharedResources` frontmatter

---

Before completing work, verify all items pass:

## Required Checks

| Check | Description |
|-------|-------------|
| Formatting | All changed files have consistent formatting |
| No secrets | No hardcoded secrets, API keys, or credentials |
| Error handling | Error handling covers all failure paths |
| Naming | Public functions have descriptive names and parameter types |

## Conditional Checks

| Condition | Check |
|-----------|-------|
| Adding dependencies | Justified and version-pinned |
| Modifying APIs | Backwards-compatible or migration documented |
| Security-sensitive code | Input validation present |

## Completion Gate

All "Required Checks" MUST pass (RFC 2119). Conditional checks apply only
when the condition is met.

**If any required check fails:**
1. Set manifest `"status": "partial"`
2. Add failing checks to `needs_followup` array
3. Document what needs to be fixed
```

This file is the **single source of truth** for code quality standards. It's defined once, lives in `_shared/`, and gets injected into any skill that declares it.

#### Step 3: Declare the Dependency in SKILL.md Frontmatter

Each skill that needs the checklist adds it to `sharedResources`:

```yaml
# skills/ct-task-executor/SKILL.md
---
name: ct-task-executor
version: 2.0.0
tier: 2
core: true
category: core
protocol: implementation
sharedResources:
  - subagent-protocol-base
  - task-system-integration
  - code-quality-checklist      # ← NEW: shared quality gate
---
```

```yaml
# skills/ct-library-implementer-bash/SKILL.md
---
name: ct-library-implementer-bash
version: 2.0.0
tier: 2
sharedResources:
  - subagent-protocol-base
  - task-system-integration
  - code-quality-checklist      # ← Same shared resource, zero duplication
---
```

```yaml
# skills/ct-test-writer-bats/SKILL.md
---
name: ct-test-writer-bats
version: 2.0.0
tier: 2
sharedResources:
  - subagent-protocol-base
  - task-system-integration
  - code-quality-checklist      # ← Same shared resource
---
```

#### Step 4: How CLEO Injects the Shared Resource

When the orchestrator spawns `ct-task-executor`, it reads the `sharedResources` array and builds this protocol stack:

```
Injected into subagent context (top to bottom):
┌──────────────────────────────────────────────────┐
│ SKILL.md body                                     │  ← "How to execute tasks"
│ (ct-task-executor-specific instructions)          │
├──────────────────────────────────────────────────┤
│ protocols/implementation.md                       │  ← "Implementation rules"
│ (from `protocol: implementation`)                │
├──────────────────────────────────────────────────┤
│ _shared/subagent-protocol-base.md                │  ← "Output format, manifest"
│ (OUT-001 through OUT-004, lifecycle phases)       │
├──────────────────────────────────────────────────┤
│ _shared/task-system-integration.md               │  ← "Task commands"
│ ({{TASK_FOCUS_CMD}}, {{TASK_COMPLETE_CMD}})       │
├──────────────────────────────────────────────────┤
│ _shared/code-quality-checklist.md                │  ← "Quality gate"
│ (Required checks, conditional checks, gate)      │  ← YOUR NEW RESOURCE
└──────────────────────────────────────────────────┘
```

The skill's SKILL.md body never mentions the checklist content — it's injected beneath. The subagent sees the full stack as a single context.

#### Step 5: The DRY Result

| Metric | Without `_shared/` | With `_shared/` |
|--------|-------------------|-----------------|
| Checklist definitions | 3 copies (one per skill) | 1 copy (`_shared/code-quality-checklist.md`) |
| Lines of content | ~60 (20 × 3) | ~20 (single file) |
| Update effort | Edit 3 files | Edit 1 file |
| Consistency risk | High (copies can drift) | None (single source) |
| Token overhead | 3× per spawn | 1× per spawn |

When you later update the quality checklist (e.g., adding a new required check), you edit `_shared/code-quality-checklist.md` once. Every skill that declares it in `sharedResources` gets the updated version at their next spawn.

#### Guidelines for New Shared Resources

| Decision | Guidance |
|----------|----------|
| **When to create one** | Content is duplicated across 2+ skills and should stay synchronized |
| **Where to put it** | `skills/_shared/<descriptive-name>.md` |
| **How to name it** | Lowercase hyphenated, describes the content (e.g., `code-quality-checklist`, `api-design-standards`) |
| **Format** | Markdown with clear headings. Include a header noting it's an injected resource. |
| **Size** | Keep under 2000 tokens. Shared resources count against each skill's token budget. |
| **Testing** | Run `bash scripts/build-index.sh` to verify `sharedResources` references don't break validation |

---

## Context Injection: How SKILL.md Becomes a Subagent Spawn

This section walks through the complete lifecycle of a SKILL.md file — from raw template with `{{TOKEN}}` placeholders to fully resolved context injected into a running subagent.

### The Raw SKILL.md (What Developers Write)

Here is a simplified SKILL.md as it exists on disk. Notice the `{{TOKEN}}` placeholders — these are NOT literal values:

```yaml
---
name: ct-research-agent
version: 2.0.0
tier: 2
protocol: research
sharedResources:
  - subagent-protocol-base
  - task-system-integration
---
```

```markdown
# Research Context Injection

**Protocol**: @protocols/research.md

## Parameters (Orchestrator-Provided)

| Parameter | Description |
|-----------|-------------|
| `{{TOPIC}}` | Research subject |
| `{{RESEARCH_QUESTIONS}}` | Questions to answer |
| `{{TASK_ID}}` | Current task identifier |
| `{{DATE}}` | Current date (YYYY-MM-DD) |

## Execution Sequence

1. Read task: `{{TASK_SHOW_CMD}} {{TASK_ID}}`
2. Set focus: `{{TASK_FOCUS_CMD}} {{TASK_ID}}`
3. Conduct research on {{TOPIC}}
4. Write output: `{{OUTPUT_DIR}}/{{DATE}}_{{TOPIC_SLUG}}.md`
5. Complete: `{{TASK_COMPLETE_CMD}} {{TASK_ID}}`

## Output File

Write findings to `{{OUTPUT_DIR}}/{{DATE}}_{{TOPIC_SLUG}}.md`:

# {{RESEARCH_TITLE}}

## Summary
[2-3 sentence overview]

## Linked Tasks
- Epic: {{EPIC_ID}}
- Task: {{TASK_ID}}
```

### What the Orchestrator Does (Token Resolution)

When the orchestrator spawns this skill for task T2500 (researching "WebSocket authentication"), it resolves **every** `{{TOKEN}}` placeholder to a concrete value:

```
Token Resolution Map (for this specific spawn):
┌─────────────────────────┬─────────────────────────────────────────┐
│ Token                   │ Resolved Value                          │
├─────────────────────────┼─────────────────────────────────────────┤
│ {{TASK_ID}}             │ T2500                                   │
│ {{EPIC_ID}}             │ T2490                                   │
│ {{DATE}}                │ 2026-02-12                              │
│ {{TOPIC}}               │ WebSocket authentication patterns       │
│ {{TOPIC_SLUG}}          │ websocket-auth-patterns                 │
│ {{RESEARCH_TITLE}}      │ WebSocket Authentication Research       │
│ {{RESEARCH_QUESTIONS}}  │ 1. How to authenticate WS connections?  │
│                         │ 2. Token vs session-based auth?         │
│ {{OUTPUT_DIR}}          │ claudedocs/agent-outputs                │
│ {{MANIFEST_PATH}}       │ claudedocs/agent-outputs/MANIFEST.jsonl │
│ {{TASK_SHOW_CMD}}       │ cleo show                               │
│ {{TASK_FOCUS_CMD}}      │ cleo focus set                          │
│ {{TASK_COMPLETE_CMD}}   │ cleo complete                           │
│ {{TOPICS_JSON}}         │ ["websocket","authentication","security"]│
└─────────────────────────┴─────────────────────────────────────────┘
```

### What the Subagent Receives (Fully Resolved Context)

After token resolution, the orchestrator assembles the protocol stack and injects it as the subagent's context. Here is exactly what the subagent sees:

```markdown
# Research Context Injection

**Protocol**: [research protocol content injected inline]

## Parameters (Orchestrator-Provided)

| Parameter | Description |
|-----------|-------------|
| `WebSocket authentication patterns` | Research subject |
| `1. How to authenticate WS connections? 2. Token vs session-based auth?` | Questions to answer |
| `T2500` | Current task identifier |
| `2026-02-12` | Current date (YYYY-MM-DD) |

## Execution Sequence

1. Read task: `cleo show T2500`
2. Set focus: `cleo focus set T2500`
3. Conduct research on WebSocket authentication patterns
4. Write output: `claudedocs/agent-outputs/2026-02-12_websocket-auth-patterns.md`
5. Complete: `cleo complete T2500`

## Output File

Write findings to `claudedocs/agent-outputs/2026-02-12_websocket-auth-patterns.md`:

# WebSocket Authentication Research

## Summary
[2-3 sentence overview]

## Linked Tasks
- Epic: T2490
- Task: T2500

---
[subagent-protocol-base.md content injected here]
---
[task-system-integration.md content injected here]
```

### Key Takeaways

1. **Developers write templates** — SKILL.md files use `{{TOKEN}}` placeholders for all variable values
2. **The orchestrator resolves tokens** — Before spawning, every `{{TOKEN}}` is replaced with a concrete value for the current task context
3. **Subagents receive concrete values** — The subagent never sees `{{TOKEN}}` syntax. It gets a fully resolved prompt with real task IDs, dates, file paths, and commands
4. **`@` references are inlined** — References like `@protocols/research.md` and `@skills/_shared/subagent-protocol-base.md` are read and inlined by the orchestrator
5. **The protocol stack is invisible to the developer** — Shared resources from `_shared/` are appended beneath the SKILL.md body. Skills don't need to duplicate this content.

### Writing a SKILL.md That Uses Context Injection Effectively

Follow these patterns when creating skills that will be injected into subagent spawns:

**Use tokens for all variable values:**
```markdown
# GOOD — portable, works after token resolution
Write output to: `{{OUTPUT_DIR}}/{{DATE}}_{{TOPIC_SLUG}}.md`
Complete the task: `{{TASK_COMPLETE_CMD}} {{TASK_ID}}`

# BAD — hardcoded, breaks with different tasks/environments
Write output to: `claudedocs/agent-outputs/2026-01-15_my-topic.md`
Complete the task: `cleo complete T1234`
```

**Document expected tokens in a parameters table:**
```markdown
## Parameters (Orchestrator-Provided)

| Parameter | Description | Required |
|-----------|-------------|----------|
| `{{TASK_ID}}` | Current task identifier | Yes |
| `{{DATE}}` | Current date (YYYY-MM-DD) | Yes |
| `{{TOPIC_SLUG}}` | URL-safe topic name for file naming | Yes |
| `{{EPIC_ID}}` | Parent epic identifier | No |
```

**Reference shared protocols instead of duplicating them:**
```markdown
## Subagent Protocol

@skills/_shared/subagent-protocol-base.md

# ↑ This @reference tells CLEO to inject the shared protocol content here.
# The developer doesn't need to copy the 200+ lines of output rules.
```

---

## Defining Skills by Tier: Planning Tier Example

CLEO organizes skills into four tiers that reflect their role in the orchestration hierarchy:

| Tier | Role | When Used | Examples |
|------|------|-----------|---------|
| **0** | Orchestration | Coordinates other skills, never implements directly | ct-orchestrator |
| **1** | Planning | Analyzes, decomposes, and plans before execution begins | ct-epic-architect |
| **2** | Execution | Implements, tests, validates — produces concrete deliverables | ct-task-executor, ct-spec-writer, ct-research-agent |
| **3** | Specialized | Domain-specific tools, composition skills, meta skills | ct-documentor, ct-docs-lookup, ct-gitbook |

### What Makes a Planning Tier (Tier 1) Skill Different

Planning skills (tier 1) have distinct characteristics:

1. **Output is structure, not code** — They produce task trees, dependency graphs, and execution plans rather than implementation artifacts
2. **They feed the orchestrator** — Their output tells the orchestrator what to spawn next and in what order
3. **They operate before execution begins** — In the RCSD pipeline, planning (decomposition) precedes implementation
4. **They create tasks, not complete them** — They use `cleo add` more than `cleo complete`

### Complete Tier 1 Skill Example: `ct-epic-architect`

Here is the full `SKILL.md` for a planning-tier skill with annotations explaining each decision:

```yaml
---
name: ct-epic-architect
description: >-
  Epic planning and task decomposition for breaking down large initiatives
  into atomic, executable tasks. Provides dependency analysis, wave-based
  parallel execution planning, hierarchy management, and research linking.
  Use when creating epics, decomposing initiatives into task trees, planning
  parallel workflows, or analyzing task dependencies. Triggers on epic
  creation, task decomposition requests, or planning phase work.
version: 3.0.0
tier: 1                           # ← PLANNING tier, not execution
core: false
category: recommended             # ← Part of the standard RCSD pipeline
protocol: decomposition           # ← Binds to protocols/decomposition.md
dependencies: []                  # ← No runtime deps on other skills
sharedResources:
  - subagent-protocol-base        # ← Lifecycle rules
  - task-system-integration       # ← Task commands
compatibility:
  - claude-code
  - cursor
  - windsurf
  - gemini-cli
license: MIT
---
```

**Body content (after the closing `---`):**

```markdown
# Epic Architect Context Injection

**Protocol**: @protocols/decomposition.md
**Type**: Context Injection (cleo-subagent)
**Version**: 3.0.0

---

## Purpose

Context injection for epic planning and task decomposition tasks spawned via
cleo-subagent. Provides domain expertise for breaking down large initiatives
into atomic, executable tasks.

---

## Capabilities

1. **Epic Creation** - Parent epic with full metadata and file attachments
2. **Task Decomposition** - Atomic tasks with acceptance criteria
3. **Dependency Analysis** - Wave-based parallel execution planning
4. **Research Linking** - Connect research outputs to tasks
5. **HITL Clarification** - Ask when requirements are ambiguous

---

## Execution Sequence

1. Read task: `{{TASK_SHOW_CMD}} {{TASK_ID}}`
2. Set focus: `{{TASK_FOCUS_CMD}} {{TASK_ID}}`
3. Analyze the initiative scope
4. Create epic and decompose into child tasks
5. Establish dependency graph and execution waves
6. Complete task: `{{TASK_COMPLETE_CMD}} {{TASK_ID}}`

---

## Decomposition Rules

### Task Atomicity
Each task MUST be completable by a single subagent in a single session.
If a task requires multiple skills or sessions, decompose further.

### Dependency Waves
Group tasks into parallel execution waves:
- Wave 1: No dependencies (can start immediately)
- Wave 2: Depends only on Wave 1 tasks
- Wave 3: Depends on Wave 1 or Wave 2 tasks

### Hierarchy Limits
- Maximum depth: 3 levels (epic → task → subtask)
- Maximum siblings: 7 per parent
- Each task must have acceptance criteria

---

## Output Format

Write decomposition to: `{{OUTPUT_DIR}}/{{TASK_ID}}-decomposition.md`

The output must include:
1. Epic summary with scope definition
2. Task list with IDs, titles, and acceptance criteria
3. Dependency graph showing blocking relationships
4. Wave assignment for parallel execution
5. Estimated complexity per task (small/medium/large)
```

### How Tier Affects Dispatch

The `tier` field directly influences how the orchestrator routes work:

```
Orchestrator dispatch priority:
  1. Check by_protocol  → "decomposition" → ct-epic-architect (tier 1)
  2. Check by_task_type  → "planning"      → ct-epic-architect (tier 1)
  3. Check by_keyword    → "epic|plan"     → ct-epic-architect (tier 1)
```

Tier 1 skills are dispatched **before** tier 2 skills in the RCSD pipeline:

```
RCSD Pipeline:
  Research (tier 2) → Consensus (tier 2) → Specification (tier 2) → Decomposition (tier 1)
                                                                           │
                                                                           ▼
  Implementation (tier 2) → Contribution (tier 2) → Release (tier 2)
```

The decomposition step (tier 1) creates the task tree that tier 2 skills execute.

### Creating Your Own Planning Tier Skill

To create a new tier 1 skill, follow the ct-epic-architect pattern:

```yaml
---
name: ct-sprint-planner
description: >-
  Sprint planning and capacity allocation for mapping decomposed tasks
  to time-boxed iterations. Analyzes task complexity, team capacity, and
  dependencies to produce balanced sprint plans. Use when planning sprints,
  allocating work across iterations, or balancing team workload.
version: 1.0.0
tier: 1                           # ← Planning tier
core: false
category: specialist
protocol: decomposition           # ← Reuses decomposition protocol
dependencies:
  - ct-epic-architect             # ← Needs decomposed task tree as input
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

**Directory structure:**

```
skills/ct-sprint-planner/
├── SKILL.md                      # Required — frontmatter + instructions
├── references/                   # Optional
│   └── sprint-templates.md       # Sprint plan templates
└── assets/                       # Optional
    └── capacity-calculator.md    # Capacity estimation formulas
```

After creating the skill:

```bash
# Validate frontmatter
bash scripts/build-index.sh

# Add to dispatch config (dispatch-config.json)
# Then regenerate manifest
node scripts/build-manifest.js
```

Expected build output:
```
OK: ct-sprint-planner (v1.0.0 tier:1 core:false cat:specialist proto:decomposition 80 lines, 350 char desc, 1 refs)
```

---

## Install Profiles

Install profiles define named sets of skills for different use cases. Profiles are stored in `profiles/*.json`.

### Available Profiles

| Profile | Skills | Use Case |
|---------|--------|----------|
| `minimal` | 1 (ct-task-executor) | Bare minimum — just the default fallback |
| `core` | 2 (+ct-orchestrator) | Minimum viable CLEO |
| `recommended` | 6 (+RCSD pipeline skills) | Standard CLEO workflow |
| `full` | 17 (all skills) | Everything |

### Profile Schema

```json
{
  "name": "recommended",
  "description": "Core + RCSD pipeline skills",
  "extends": "core",
  "skills": ["ct-epic-architect", "ct-research-agent", "ct-spec-writer", "ct-validator"],
  "includeProtocols": ["research", "specification", "decomposition", "consensus", "validation"]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Profile identifier |
| `description` | string | Human-readable purpose |
| `extends` | string? | Parent profile to inherit skills from |
| `skills` | string[] | Skills added by this profile (on top of parent) |
| `includeShared` | boolean? | Whether to include `_shared/` (default: inherited) |
| `includeProtocols` | string[] | Protocol files to include |

### Resolving Profiles Programmatically

```js
const { resolveProfile, listProfiles } = require('@cleocode/ct-skills');

// List available profiles
console.log(listProfiles()); // ["core", "full", "minimal", "recommended"]

// Resolve a profile (follows extends chain, resolves dependencies)
const skills = resolveProfile('recommended');
console.log(skills);
// ["ct-epic-architect", "ct-research-agent", "ct-spec-writer", "ct-validator",
//  "ct-orchestrator", "ct-task-executor"]
// ^ includes core + minimal via extends chain
```

---

## CLI Reference

The `ct-skills` CLI provides standalone access to the registry without requiring CAAMP.

```bash
# List all skills
ct-skills list

# List only core skills
ct-skills list --core

# Filter by category
ct-skills list --category recommended

# Show detailed skill info
ct-skills info ct-spec-writer

# Validate all skill frontmatter
ct-skills validate

# Validate a specific skill
ct-skills validate ct-spec-writer

# List install profiles
ct-skills profiles

# List available protocols
ct-skills protocols

# Install skills (requires CAAMP)
ct-skills install --profile recommended
ct-skills install ct-documentor  # installs + dependencies
```

---

## Validation

### Frontmatter Validation (build-index.sh)

```bash
bash scripts/build-index.sh
```

Checks: name pattern, directory match, description length, body length, category validity, dependency references.

### Programmatic Validation (Node.js API)

```js
const { validateSkillFrontmatter, validateAll } = require('@cleocode/ct-skills');

// Validate one skill
const result = validateSkillFrontmatter('ct-spec-writer');
console.log(result);
// { valid: true, issues: [] }

// Validate all skills
const allResults = validateAll();
for (const [name, result] of allResults) {
  if (!result.valid) {
    console.log(`FAIL: ${name}`);
    for (const issue of result.issues) {
      console.log(`  ${issue.level}: [${issue.field}] ${issue.message}`);
    }
  }
}
```

### Validation Issue Levels

| Level | Meaning | Blocks publish? |
|-------|---------|-----------------|
| `error` | Invalid data — must fix | Yes |
| `warn` | Non-ideal but functional | No |

### Common Validation Issues

| Issue | Level | Fix |
|-------|-------|-----|
| `Invalid category 'custom'` | error | Use one of: core, recommended, specialist, composition, meta |
| `Unknown dependency: ct-nonexistent` | error | Ensure referenced skill exists in `skills/` |
| `Missing version` | warn | Add `version: 1.0.0` to frontmatter |
| `Protocol file not found: custom.md` | warn | Add protocol to `protocols/` or set `protocol: null` |
| `Description too long: 1100 chars` | error | Shorten to under 1024 characters |
