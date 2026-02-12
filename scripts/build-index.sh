#!/usr/bin/env bash
# build-index.sh — Scan skills/*/SKILL.md, validate, and generate skills.json
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
OUTPUT="$REPO_ROOT/skills.json"
ERRORS=0

# Name validation pattern
NAME_PATTERN='^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'

# Extract a YAML frontmatter field value (simple single-line extraction)
extract_field() {
  local file="$1" field="$2"
  sed -n '/^---$/,/^---$/p' "$file" \
    | grep -E "^${field}:" \
    | head -1 \
    | sed "s/^${field}:[[:space:]]*//" \
    | sed 's/^["'"'"']//' \
    | sed 's/["'"'"']$//' \
    | sed 's/^>-[[:space:]]*//'
}

# Extract multi-line description (handles >- folded scalar)
extract_description() {
  local file="$1"
  local in_frontmatter=false
  local in_description=false
  local desc=""

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if $in_frontmatter; then
        break
      fi
      in_frontmatter=true
      continue
    fi

    if ! $in_frontmatter; then
      continue
    fi

    if [[ "$line" =~ ^description: ]]; then
      in_description=true
      # Check for inline value
      local value
      value="$(echo "$line" | sed 's/^description:[[:space:]]*//')"
      if [[ "$value" != ">-" && "$value" != ">" && "$value" != "|" && -n "$value" ]]; then
        desc="$value"
        in_description=false
      fi
      continue
    fi

    if $in_description; then
      # Continuation lines are indented
      if [[ "$line" =~ ^[[:space:]] ]]; then
        local trimmed
        trimmed="$(echo "$line" | sed 's/^[[:space:]]*//')"
        if [[ -n "$desc" ]]; then
          desc="$desc $trimmed"
        else
          desc="$trimmed"
        fi
      else
        in_description=false
      fi
    fi
  done < "$file"

  echo "$desc"
}

# Escape string for JSON
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

echo "Building skills index..."
echo ""

skills_json='['
first_skill=true

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue

  skill_file="$skill_dir/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    echo "WARN: $skill_dir has no SKILL.md, skipping"
    continue
  fi

  dir_name="$(basename "$skill_dir")"

  # Extract frontmatter fields
  name="$(extract_field "$skill_file" "name")"
  description="$(extract_description "$skill_file")"

  # Validate name exists
  if [ -z "$name" ]; then
    echo "ERROR: $skill_file missing 'name' field"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Validate name pattern
  if ! echo "$name" | grep -qE "$NAME_PATTERN"; then
    echo "ERROR: $skill_file name '$name' does not match pattern $NAME_PATTERN"
    ERRORS=$((ERRORS + 1))
  fi

  # Validate no consecutive hyphens
  if echo "$name" | grep -qF -- '--'; then
    echo "ERROR: $skill_file name '$name' contains consecutive hyphens"
    ERRORS=$((ERRORS + 1))
  fi

  # Validate directory name matches
  if [ "$dir_name" != "$name" ]; then
    echo "ERROR: Directory '$dir_name' does not match name '$name'"
    ERRORS=$((ERRORS + 1))
  fi

  # Validate description exists
  if [ -z "$description" ]; then
    echo "ERROR: $skill_file missing 'description' field"
    ERRORS=$((ERRORS + 1))
  fi

  # Validate description length
  desc_len="${#description}"
  if [ "$desc_len" -gt 1024 ]; then
    echo "ERROR: $skill_file description is $desc_len chars (max 1024)"
    ERRORS=$((ERRORS + 1))
  fi

  # Validate body length (lines after second ---)
  body_lines="$(sed -n '/^---$/,/^---$/d; p' "$skill_file" | wc -l)"
  if [ "$body_lines" -gt 500 ]; then
    echo "ERROR: $skill_file body is $body_lines lines (max 500)"
    ERRORS=$((ERRORS + 1))
  fi

  # Collect reference files
  refs_json='['
  first_ref=true
  if [ -d "$skill_dir/references" ]; then
    for ref_file in "$skill_dir/references"/*; do
      [ -f "$ref_file" ] || continue
      ref_path="skills/$dir_name/references/$(basename "$ref_file")"
      if $first_ref; then
        first_ref=false
      else
        refs_json+=','
      fi
      refs_json+="\"$(json_escape "$ref_path")\""
    done
  fi
  refs_json+=']'

  # Extract metadata (simple key-value pairs under metadata:)
  metadata_json='{}'

  # Build skill entry
  escaped_name="$(json_escape "$name")"
  escaped_desc="$(json_escape "$description")"
  skill_path="skills/$dir_name/SKILL.md"

  entry="{\"name\":\"$escaped_name\",\"description\":\"$escaped_desc\",\"path\":\"$skill_path\",\"references\":$refs_json,\"metadata\":$metadata_json}"

  if $first_skill; then
    first_skill=false
  else
    skills_json+=','
  fi
  skills_json+="$entry"

  ref_count=0
  if [ -d "$skill_dir/references" ]; then
    ref_count=$(find "$skill_dir/references" -maxdepth 1 -type f | wc -l)
  fi
  echo "OK: $name ($body_lines lines, $desc_len char description, $ref_count references)"
done

skills_json+=']'

# Write skills.json regardless of validation errors
generated="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cat > "$OUTPUT" << ENDJSON
{
  "version": "1.0.0",
  "generated": "$generated",
  "skills": $skills_json
}
ENDJSON

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Generated $OUTPUT (with $ERRORS validation warning(s))"
  echo "FAILED: $ERRORS validation error(s)"
  exit 1
fi

echo ""
echo "Generated $OUTPUT"
