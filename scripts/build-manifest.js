#!/usr/bin/env node
'use strict';

/**
 * build-manifest.js — Generate skills/manifest.json from:
 *   1. skills.json (auto-generated from SKILL.md frontmatter)
 *   2. dispatch-config.json (manual dispatch routing rules)
 *
 * Usage: node scripts/build-manifest.js
 */

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.join(__dirname, '..');
const SKILLS_JSON = path.join(REPO_ROOT, 'skills.json');
const DISPATCH_CONFIG = path.join(REPO_ROOT, 'dispatch-config.json');
const OUTPUT = path.join(REPO_ROOT, 'skills', 'manifest.json');

// Load sources
if (!fs.existsSync(SKILLS_JSON)) {
  console.error('ERROR: skills.json not found. Run build-index.sh first.');
  process.exit(1);
}

if (!fs.existsSync(DISPATCH_CONFIG)) {
  console.error('ERROR: dispatch-config.json not found.');
  process.exit(1);
}

const skillsIndex = JSON.parse(fs.readFileSync(SKILLS_JSON, 'utf8'));
const dispatchConfig = JSON.parse(fs.readFileSync(DISPATCH_CONFIG, 'utf8'));

const skills = skillsIndex.skills;
const overrides = dispatchConfig.skill_overrides || {};

// Build manifest skill entries by merging frontmatter + dispatch config
const manifestSkills = skills.map(skill => {
  const override = overrides[skill.name] || {};
  const caps = override.capabilities || {};

  return {
    name: skill.name,
    version: skill.version || '1.0.0',
    description: skill.description,
    path: `skills/${skill.name}`,
    tags: override.tags || [],
    status: override.status || 'active',
    tier: skill.tier,
    token_budget: override.token_budget || 6000,
    references: skill.references || [],
    capabilities: {
      inputs: caps.inputs || [],
      outputs: caps.outputs || [],
      dependencies: skill.dependencies || [],
      dispatch_triggers: caps.dispatch_triggers || [],
      compatible_subagent_types: caps.compatible_subagent_types || ['general-purpose'],
      chains_to: caps.chains_to || [],
      dispatch_keywords: caps.dispatch_keywords || { primary: [], secondary: [] }
    },
    constraints: override.constraints || {
      max_context_tokens: 60000,
      requires_session: false,
      requires_epic: false
    }
  };
});

// Build final manifest
const manifest = {
  $schema: 'https://cleo-dev.com/schemas/v1/skills-manifest.schema.json',
  _meta: {
    schemaVersion: '2.2.0',
    lastUpdated: new Date().toISOString().split('T')[0],
    totalSkills: manifestSkills.length,
    generatedFrom: 'scripts/build-manifest.js (frontmatter + dispatch-config.json)',
    architectureNote: "Universal Subagent Architecture: All spawns use single agent type 'cleo-subagent' with skill/protocol injection."
  },
  dispatch_matrix: dispatchConfig.dispatch_matrix,
  skills: manifestSkills
};

// Write output
fs.writeFileSync(OUTPUT, JSON.stringify(manifest, null, 2) + '\n');
console.log(`Generated ${path.relative(REPO_ROOT, OUTPUT)} (${manifestSkills.length} skills)`);
