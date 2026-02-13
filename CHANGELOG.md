# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-02-12

### Added
- Registry/Catalog API — 20+ new exports for programmatic skill discovery, dependency resolution, and profile-based selection
- CLI (`ct-skills`) with `list`, `info`, `validate`, `profiles`, `protocols`, and `install` commands
- 12 protocol files (`protocols/`) — agent-protocol, consensus, contribution, decomposition, implementation, research, specification, testing, validation, release, artifact-publish, provenance
- 4 install profiles (`profiles/`) — minimal, core, recommended, full — with `extends` chain resolution
- `dispatch-config.json` for manual dispatch routing rules
- `scripts/build-manifest.js` — auto-generates `manifest.json` from SKILL.md frontmatter + dispatch config
- New SKILL.md frontmatter fields: `core`, `category`, `protocol`, `dependencies`, `sharedResources`, `compatibility`, `license`
- Dependency tree resolution (`resolveDependencyTree`) with transitive dependency support
- Frontmatter validation API (`validateSkillFrontmatter`, `validateAll`)
- Protocol and shared resource read APIs (`listProtocols`, `readProtocol`, `listSharedResources`, `readSharedResource`)
- TypeScript declarations for all new exports (`SkillEntry`, `ProfileDefinition`, `ValidationResult`)

### Changed
- `index.js` evolved from dump-everything loader to structured Registry/Catalog API (backward-compatible)
- `index.d.ts` expanded with full type declarations for new interfaces
- `scripts/build-index.sh` now extracts `version`, `tier`, `core`, `category`, `protocol`, `dependencies`, `sharedResources`, `compatibility`, `license` into `skills.json`
- `skills.json` schema version bumped to 2.0.0 with enriched skill entries
- `manifest.json` now auto-generated from frontmatter + dispatch config (was fully manual)
- `package.json` version 1.0.0 -> 2.0.0, added `bin` entry, expanded `files` list
- All 17 SKILL.md frontmatter blocks enriched with new registry fields

### Renamed
- `ct-contribution-protocol` -> `ct-contribution` (directory and frontmatter name aligned)

## [1.0.0] - 2026-02-12

Initial release as `@cleocode/ct-skills` — the official skills library for the CLEO multi-agent orchestration ecosystem.

### Added
- Published as npm package `@cleocode/ct-skills`
- Node.js API (`index.js`) with `listSkills`, `getSkill`, `getSkillPath`, `getSkillDir`, `getDispatchMatrix`, `readSkillContent` exports
- TypeScript declarations (`index.d.ts`)
- Build script (`scripts/build-index.sh`) — scans `skills/*/SKILL.md`, validates frontmatter and body constraints, generates `skills.json`
- Dual manifest system: `skills.json` (auto-generated, CAAMP consumption) + `manifest.json` (manual, CLEO dispatch)
- `skills/_shared/` protocol infrastructure — `subagent-protocol-base.md`, `task-system-integration.md`, `testing-framework-config.md`, `cleo-style-guide.md`, `placeholders.json`
- 15 skills across 4 tiers:
  - **Tier 0 (orchestration):** ct-orchestrator
  - **Tier 1 (planning):** ct-epic-architect
  - **Tier 2 (execution):** ct-task-executor, ct-research-agent, ct-spec-writer, ct-validator, ct-dev-workflow, ct-test-writer-bats, ct-library-implementer-bash
  - **Tier 3 (specialized):** ct-documentor, ct-docs-lookup, ct-docs-write, ct-docs-review, ct-skill-creator, ct-skill-lookup
- ct-gitbook skill with 8 reference files and starter template assets
- ct-orchestrator progressive disclosure with 9 reference files
- ct-epic-architect with 10 reference files (examples, patterns, commands)
- ct-skill-creator with reference files and helper scripts
- CLEO ecosystem architecture documentation (`CLAUDE.md`, `docs/SKILL-SPECIFICATION.md`)

### Architecture
- 2-tier universal subagent model: orchestrator (Tier 0) injects skill content into `cleo-subagent` spawns (Tier 1)
- Skills are agentskills.io-compliant `SKILL.md` markdown files — content, not code
- Consumed by CLEO via CAAMP package management: `CLEO -> CAAMP -> @cleocode/ct-skills`
