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

### Creating New Shared Resources

If you need a new shared resource:

1. Create the file in `skills/_shared/` (e.g., `security-checklist.md`)
2. Add it to `sharedResources` in relevant SKILL.md frontmatter
3. The orchestrator will automatically include it in the protocol stack

```yaml
# skills/ct-security-auditor/SKILL.md
---
name: ct-security-auditor
sharedResources:
  - subagent-protocol-base
  - task-system-integration
  - security-checklist          # ← New shared resource
---
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
