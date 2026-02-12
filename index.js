'use strict';

const path = require('path');
const fs = require('fs');

const SKILLS_ROOT = path.join(__dirname, 'skills');

/** Parsed skills.json index */
const skillsIndex = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'skills.json'), 'utf8')
);

/** Parsed manifest.json dispatch registry */
const manifest = JSON.parse(
  fs.readFileSync(path.join(SKILLS_ROOT, 'manifest.json'), 'utf8')
);

/** Parsed _shared/placeholders.json */
const shared = JSON.parse(
  fs.readFileSync(path.join(SKILLS_ROOT, '_shared', 'placeholders.json'), 'utf8')
);

/** All skill entries from skills.json */
const skills = skillsIndex.skills;

/**
 * List all skill names.
 * @returns {string[]}
 */
function listSkills() {
  return skills.map(s => s.name);
}

/**
 * Get skill metadata from skills.json by name.
 * @param {string} name - Skill name (e.g. "ct-research-agent")
 * @returns {object|undefined}
 */
function getSkill(name) {
  return skills.find(s => s.name === name);
}

/**
 * Resolve absolute path to a skill's SKILL.md file.
 * @param {string} name - Skill name
 * @returns {string}
 */
function getSkillPath(name) {
  return path.join(SKILLS_ROOT, name, 'SKILL.md');
}

/**
 * Resolve absolute path to a skill's directory.
 * @param {string} name - Skill name
 * @returns {string}
 */
function getSkillDir(name) {
  return path.join(SKILLS_ROOT, name);
}

/**
 * Get the dispatch matrix from manifest.json.
 * @returns {object}
 */
function getDispatchMatrix() {
  return manifest.dispatch_matrix;
}

/**
 * Read a skill's SKILL.md content as a string.
 * @param {string} name - Skill name
 * @returns {string}
 */
function readSkillContent(name) {
  return fs.readFileSync(getSkillPath(name), 'utf8');
}

module.exports = {
  skills,
  manifest,
  shared,
  listSkills,
  getSkill,
  getSkillPath,
  getSkillDir,
  getDispatchMatrix,
  readSkillContent,
};
