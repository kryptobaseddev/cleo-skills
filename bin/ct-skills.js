#!/usr/bin/env node
'use strict';

const lib = require('../index');

const args = process.argv.slice(2);
const command = args[0];

function getFlag(name) {
  const idx = args.indexOf(`--${name}`);
  if (idx === -1) return undefined;
  return args[idx + 1];
}

function hasFlag(name) {
  return args.includes(`--${name}`);
}

function requireCaamp() {
  try {
    return require('@cleocode/caamp');
  } catch {
    console.error('Error: @cleocode/caamp is required for install operations.');
    console.error('Install it with: npm install -g @cleocode/caamp');
    process.exit(1);
  }
}

function printHelp() {
  console.log(`ct-skills v${lib.version} — CLEO Skills Registry CLI

Usage:
  ct-skills install [--profile <name>] [skill-name]   Install skills (requires CAAMP)
  ct-skills list [--core] [--category <cat>] [--profile <name>]   List skills
  ct-skills info <skill-name>                          Show skill details
  ct-skills validate [skill-name]                      Validate frontmatter
  ct-skills profiles                                   List install profiles
  ct-skills protocols                                  List available protocols
  ct-skills help                                       Show this help
`);
}

function cmdList() {
  let filtered = lib.skills;

  if (hasFlag('core')) {
    filtered = filtered.filter(s => s.core === true);
  }

  const category = getFlag('category');
  if (category) {
    filtered = filtered.filter(s => s.category === category);
  }

  const profile = getFlag('profile');
  if (profile) {
    const profileSkills = lib.resolveProfile(profile);
    filtered = filtered.filter(s => profileSkills.includes(s.name));
  }

  if (filtered.length === 0) {
    console.log('No skills match the given filters.');
    return;
  }

  const maxName = Math.max(...filtered.map(s => s.name.length));

  for (const s of filtered) {
    const core = s.core ? ' [core]' : '';
    const proto = s.protocol ? ` proto:${s.protocol}` : '';
    console.log(
      `  ${s.name.padEnd(maxName)}  v${s.version}  tier:${s.tier}  ${s.category}${core}${proto}`
    );
  }

  console.log(`\n${filtered.length} skill(s)`);
}

function cmdInfo() {
  const name = args[1];
  if (!name) {
    console.error('Usage: ct-skills info <skill-name>');
    process.exit(1);
  }

  const skill = lib.getSkill(name);
  if (!skill) {
    console.error(`Skill '${name}' not found.`);
    console.error(`Available: ${lib.listSkills().join(', ')}`);
    process.exit(1);
  }

  console.log(`Name:           ${skill.name}`);
  console.log(`Version:        ${skill.version}`);
  console.log(`Description:    ${skill.description.slice(0, 120)}${skill.description.length > 120 ? '...' : ''}`);
  console.log(`Category:       ${skill.category}`);
  console.log(`Tier:           ${skill.tier}`);
  console.log(`Core:           ${skill.core}`);
  console.log(`Protocol:       ${skill.protocol || 'none'}`);
  console.log(`License:        ${skill.license}`);
  console.log(`Dependencies:   ${skill.dependencies.length > 0 ? skill.dependencies.join(', ') : 'none'}`);
  console.log(`Shared:         ${skill.sharedResources.length > 0 ? skill.sharedResources.join(', ') : 'none'}`);
  console.log(`Compatibility:  ${skill.compatibility.join(', ')}`);
  console.log(`References:     ${skill.references.length}`);
  console.log(`Path:           ${skill.path}`);
}

function cmdValidate() {
  const name = args[1];

  if (name) {
    const result = lib.validateSkillFrontmatter(name);
    printValidation(name, result);
    if (!result.valid) process.exit(1);
  } else {
    const results = lib.validateAll();
    let hasErrors = false;

    for (const [skillName, result] of results) {
      if (result.issues.length > 0) {
        printValidation(skillName, result);
        if (!result.valid) hasErrors = true;
      }
    }

    const total = results.size;
    const valid = Array.from(results.values()).filter(r => r.valid).length;
    console.log(`\n${valid}/${total} skills valid`);

    if (hasErrors) process.exit(1);
  }
}

function printValidation(name, result) {
  const status = result.valid ? 'PASS' : 'FAIL';
  console.log(`${status}: ${name}`);
  for (const issue of result.issues) {
    const prefix = issue.level === 'error' ? '  ERROR' : '  WARN ';
    console.log(`${prefix} [${issue.field}] ${issue.message}`);
  }
}

function cmdProfiles() {
  const profiles = lib.listProfiles();
  if (profiles.length === 0) {
    console.log('No profiles found.');
    return;
  }

  for (const name of profiles) {
    const profile = lib.getProfile(name);
    if (!profile) continue;
    const resolved = lib.resolveProfile(name);
    const ext = profile.extends ? ` (extends: ${profile.extends})` : '';
    console.log(`  ${name.padEnd(15)} ${resolved.length} skills${ext}`);
    console.log(`    ${profile.description}`);
  }
}

function cmdProtocols() {
  const protocols = lib.listProtocols();
  if (protocols.length === 0) {
    console.log('No protocols found.');
    return;
  }

  for (const name of protocols) {
    console.log(`  ${name}`);
  }
  console.log(`\n${protocols.length} protocol(s)`);
}

function cmdInstall() {
  const caamp = requireCaamp();
  const profile = getFlag('profile') || 'full';
  const skillName = args[1] && !args[1].startsWith('--') ? args[1] : null;

  let skillsToInstall;
  if (skillName) {
    skillsToInstall = lib.resolveDependencyTree([skillName]);
    console.log(`Installing ${skillName} + ${skillsToInstall.length - 1} dependencies...`);
  } else {
    skillsToInstall = lib.resolveProfile(profile);
    console.log(`Installing profile '${profile}' (${skillsToInstall.length} skills)...`);
  }

  for (const name of skillsToInstall) {
    const skill = lib.getSkill(name);
    if (!skill) {
      console.warn(`  SKIP: ${name} (not found in registry)`);
      continue;
    }
    console.log(`  ${name} v${skill.version}`);
  }

  console.log('\nInstall via CAAMP:');
  console.log(`  caamp install ${skillsToInstall.join(' ')}`);
}

// Route commands
switch (command) {
  case 'list':
    cmdList();
    break;
  case 'info':
    cmdInfo();
    break;
  case 'validate':
    cmdValidate();
    break;
  case 'profiles':
    cmdProfiles();
    break;
  case 'protocols':
    cmdProtocols();
    break;
  case 'install':
    cmdInstall();
    break;
  case 'help':
  case '--help':
  case '-h':
  case undefined:
    printHelp();
    break;
  default:
    console.error(`Unknown command: ${command}`);
    printHelp();
    process.exit(1);
}
