#!/usr/bin/env bash
# build-index.sh — Scan skills/*/SKILL.md, validate, and generate skills.json
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
OUTPUT="$REPO_ROOT/skills.json"
ERRORS=0

# Name validation pattern
NAME_PATTERN='^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'

# Valid category values
VALID_CATEGORIES="core recommended specialist composition meta"

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

# Extract a YAML array field as JSON array (handles both inline [a, b] and multi-line - a\n- b)
extract_yaml_array() {
  local file="$1" field="$2"
  local in_frontmatter=false
  local in_field=false
  local items=()

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

    if [[ "$line" =~ ^${field}: ]]; then
      in_field=true
      # Check for inline array value like: field: [a, b, c]
      local value
      value="$(echo "$line" | sed "s/^${field}:[[:space:]]*//")"
      if [[ "$value" =~ ^\[.*\]$ ]]; then
        # Inline array — parse comma-separated values
        value="${value#[}"
        value="${value%]}"
        IFS=',' read -ra parts <<< "$value"
        for part in "${parts[@]}"; do
          part="$(echo "$part" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^["'"'"']//;s/["'"'"']$//')"
          if [[ -n "$part" ]]; then
            items+=("$part")
          fi
        done
        in_field=false
      elif [[ -z "$value" || "$value" == "[]" ]]; then
        # Empty array or multi-line start
        if [[ "$value" == "[]" ]]; then
          in_field=false
        fi
      fi
      continue
    fi

    if $in_field; then
      if [[ "$line" =~ ^[[:space:]]+- ]]; then
        local item
        item="$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//')"
        if [[ -n "$item" ]]; then
          items+=("$item")
        fi
      else
        # Non-indented, non-list line means field ended
        in_field=false
      fi
    fi
  done < "$file"

  # Build JSON array
  local json='['
  local first=true
  for item in "${items[@]}"; do
    if $first; then
      first=false
    else
      json+=','
    fi
    json+="\"$(json_escape "$item")\""
  done
  json+=']'
  echo "$json"
}

# Extract a boolean field (true/false), default to provided value
extract_bool() {
  local file="$1" field="$2" default="${3:-false}"
  local value
  value="$(extract_field "$file" "$field")"
  case "$value" in
    true|True|TRUE|yes|Yes|YES) echo "true" ;;
    false|False|FALSE|no|No|NO) echo "false" ;;
    "") echo "$default" ;;
    *) echo "$default" ;;
  esac
}

# Extract a numeric field, default to provided value
extract_number() {
  local file="$1" field="$2" default="${3:-0}"
  local value
  value="$(extract_field "$file" "$field")"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "$value"
  else
    echo "$default"
  fi
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

# Collect all skill names for dependency validation
all_skill_names=()
for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  dir_name="$(basename "$skill_dir")"
  [[ "$dir_name" == "_shared" ]] && continue
  all_skill_names+=("$dir_name")
done

skills_json='['
first_skill=true

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue

  dir_name="$(basename "$skill_dir")"

  # Skip _shared directory
  [[ "$dir_name" == "_shared" ]] && continue

  skill_file="$skill_dir/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    echo "WARN: $skill_dir has no SKILL.md, skipping"
    continue
  fi

  # Extract frontmatter fields
  name="$(extract_field "$skill_file" "name")"
  description="$(extract_description "$skill_file")"
  version="$(extract_field "$skill_file" "version")"
  tier="$(extract_number "$skill_file" "tier" "2")"
  core="$(extract_bool "$skill_file" "core" "false")"
  category="$(extract_field "$skill_file" "category")"
  protocol="$(extract_field "$skill_file" "protocol")"
  license="$(extract_field "$skill_file" "license")"
  dependencies="$(extract_yaml_array "$skill_file" "dependencies")"
  shared_resources="$(extract_yaml_array "$skill_file" "sharedResources")"
  compatibility="$(extract_yaml_array "$skill_file" "compatibility")"

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

  # Validate category if provided
  if [ -n "$category" ]; then
    if ! echo "$VALID_CATEGORIES" | grep -qw "$category"; then
      echo "ERROR: $skill_file category '$category' not in ($VALID_CATEGORIES)"
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # Validate dependencies reference valid skill names
  if [ "$dependencies" != "[]" ]; then
    # Parse dependency names from JSON array
    dep_names="$(echo "$dependencies" | sed 's/\[//;s/\]//;s/"//g;s/,/ /g')"
    for dep in $dep_names; do
      found=false
      for valid_name in "${all_skill_names[@]}"; do
        if [ "$dep" = "$valid_name" ]; then
          found=true
          break
        fi
      done
      if ! $found; then
        echo "ERROR: $skill_file dependency '$dep' is not a valid skill name"
        ERRORS=$((ERRORS + 1))
      fi
    done
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

  # Build protocol JSON value
  if [ -z "$protocol" ] || [ "$protocol" = "null" ]; then
    protocol_json="null"
  else
    protocol_json="\"$(json_escape "$protocol")\""
  fi

  # Build skill entry
  escaped_name="$(json_escape "$name")"
  escaped_desc="$(json_escape "$description")"
  escaped_version="$(json_escape "${version:-1.0.0}")"
  escaped_license="$(json_escape "${license:-MIT}")"
  skill_path="skills/$dir_name/SKILL.md"

  entry="{\"name\":\"$escaped_name\",\"description\":\"$escaped_desc\",\"version\":\"$escaped_version\",\"path\":\"$skill_path\",\"references\":$refs_json,\"core\":$core,\"category\":\"${category:-specialist}\",\"tier\":$tier,\"protocol\":$protocol_json,\"dependencies\":$dependencies,\"sharedResources\":$shared_resources,\"compatibility\":$compatibility,\"license\":\"$escaped_license\",\"metadata\":{}}"

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
  echo "OK: $name (v${version:-?} tier:$tier core:$core cat:${category:-?} proto:${protocol:-none} $body_lines lines, $desc_len char desc, $ref_count refs)"
done

skills_json+=']'

# Write skills.json regardless of validation errors
generated="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cat > "$OUTPUT" << ENDJSON
{
  "version": "2.0.0",
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
echo "Generated $OUTPUT ($(echo "$skills_json" | grep -o '"name"' | wc -l) skills)"
