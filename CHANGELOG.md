# Changelog

All notable changes to this project will be documented in this file.

## [2.1.0] - 2026-02-17

### Added
- New skill: `railway-platform` - Comprehensive Railway deployment platform support
  - Unified entry point for all Railway operations (replaces 12+ fragmented skills)
  - agentskills.io compliant with progressive disclosure (~538 lines SKILL.md)
  - 14 comprehensive references covering all Railway features:
    - 01-getting-started.md - Installation, auth, linking
    - 02-projects.md - Project management
    - 03-services.md - Service operations
    - 04-deployments.md - Deploy, logs, rollback
    - 05-databases.md - Postgres, Redis, MySQL, MongoDB
    - 06-environments.md - Variables, config, staging
    - 07-domains.md - Custom domains & SSL
    - 08-volumes.md - Persistent storage (NEW)
    - 09-networking.md - Private networking, TCP (NEW)
    - 10-cron.md - Scheduled jobs (NEW)
    - 11-functions.md - Railway Functions
    - 12-monorepo.md - Workspace patterns
    - 13-troubleshooting.md - Common errors & fixes
    - 14-railway-metal.md - Migration guide
  - Central `_shared/` architecture with reusable scripts
  - GraphQL API helper (railway-api.sh)
  - CLI utilities (railway-common.sh)
  - 78% token savings vs fragmented approach
  - Complete coverage: projects, services, databases, volumes, cron, networking

## [2.0.0] - 2026-02-13

### Other Changes
- Epic: Evolve ct-skills into Registry/Catalog API v2.0.0 (T001)
- Copy 12 protocol files from CLEO repo to protocols/ (T002)
- Evolve SKILL.md frontmatter for all 17 skills (T003)
- Update build-index.sh to extract new frontmatter fields (T004)
- Create install profiles (minimal, core, recommended, full) (T005)
- Evolve index.js into Registry/Catalog API (T006)
- Update index.d.ts with full type declarations (T007)
- Create CLI bin/ct-skills.js (T008)
- Update package.json to v2.0.0 with bin entry (T009)
- Create manifest generation script and dispatch-config.json (T010)
- Update .npmignore, run builds, verify (T011)

## [1.0.0] - 2026-02-12

### Other Changes
- Epic: Initial release @cleocode/ct-skills v1.0.0 (T012)
- Initialize cleo-skills repo with ct-gitbook skill (T013)
- Add starter template assets for ct-gitbook (T014)
- Add 15 skills across 4 tiers (orchestration, planning, execution, specialized) (T015)
- Create _shared/ protocol infrastructure (subagent-protocol-base, task-system-integration, style guide, placeholders) (T016)
- Document CLEO ecosystem architecture, _shared/, and dual manifests (T017)
- Extract ct-orchestrator content into progressive disclosure references (T018)
- Create build-index.sh to validate skills and generate skills.json (T019)
- Create manifest.json dispatch registry for CLEO orchestrator (T020)
- Create Node.js API (index.js) with listSkills, getSkill, getSkillPath, getDispatchMatrix, readSkillContent (T021)
- Create TypeScript declarations (index.d.ts) (T022)
- Publish as npm package @cleocode/ct-skills v1.0.0 (T023)
