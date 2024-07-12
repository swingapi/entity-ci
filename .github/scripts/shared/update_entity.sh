#!/bin/bash

# MARK: Prepare Edit File
ky_prepare_edit_file_to_update_entity() {
  local ENTITY_FILE=$1

  # echo
  # echo "Update File: $INPUT_FILE - Delete all empty key-value pairs." >&2

  # tmp=$(mktemp)
  # jq 'del(.. | select(. == "" or . == null))' $INPUT_FILE > "$tmp" && mv "$tmp" $INPUT_FILE

  local temp_edit_file="~update_entity.json"

  echo >&2
  local TEMPLATE_FILE="$KY_TEMPLATE_ID.json"
  echo "### Create an edit file ($temp_edit_file) based on the template file ($TEMPLATE_FILE)." >&2
  cp -v "$TEMPLATE_FILE" "$temp_edit_file" >&2

  # Initialize the editing file using the info from the existing entity file.

  echo >&2
  echo "### Init the edit file ($temp_edit_file) using the info from the existing entity file ($ENTITY_FILE)." >&2

  local tmp; tmp=$(mktemp)

  jq -r 'keys_unsorted[]' "$ENTITY_FILE" | while read -r key; do
    value=$(jq -r ".${key}" "$ENTITY_FILE")
    echo "- $key: $value" >&2

    jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$temp_edit_file" > "$tmp"
    mv "$tmp" "$temp_edit_file"
  done

  # echo >&2
  # echo "### PREPARED edit file ($temp_edit_file) to update entity." >&2
  # cat "$temp_edit_file" >&2

  echo "$temp_edit_file"
}

# MARK: Update File
# Update the edit file with the modified data from the input file.
ky_update_file_with_modified_data() {
  local EDIT_FILE=$1
  local INPUT_FILE=$2

  echo >&2
  echo "### UPDATE FILE ($EDIT_FILE): Apply the modified data from the input file ($INPUT_FILE)." >&2

  local tmp; tmp=$(mktemp)
  local value

  while read -r key; do
    value=$(jq -r ".${key}" "$INPUT_FILE")
    if [ -z "$value" ] || [ "$value" = null ]; then
      continue
    fi

    echo "- [Modified] $key: $value" >&2
    if [ "$value" = "x" ]; then
      value=""
    elif [ "$key" = "styles" ]; then
      if [ "$value" = "SAME" ]; then
        continue
      elif [ "$value" = "ANY" ]; then
        value=""
      fi
    fi
    jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$EDIT_FILE" > "$tmp" && mv "$tmp" "$EDIT_FILE"

  done < <(jq -r 'keys_unsorted[]' "$KY_TEMPLATE_ID.json")
}

# MARK: - _LEGACY
__ky_update_file_with_modified_data() {
  local EDIT_FILE=$1
  local INPUT_FILE=$2

  # Get keys of modified fields.

  local modified_fields_value; modified_fields_value="$(jq -r '.modified_fields | join(",")' "$INPUT_FILE")"

  IFS=',' read -r -a modified_fields <<< "$modified_fields_value" || 'true'

  # echo "Modified Fields:" >&2
  local modified_keys=()
  for field in "${modified_fields[@]}"; do
    # shellcheck disable=SC2206
    local stringarray=($field)
    local key=${stringarray[0]}
    # echo "- $field - KEY: $key" >&2
    modified_keys+=("$key")
  done

  # Update the edit file with the modified data from the input file

  echo >&2
  echo "### UPDATE FILE ($EDIT_FILE): Apply the modified data from the input file ($INPUT_FILE)." >&2

  local tmp; tmp=$(mktemp)

  local value
  for key in "${modified_keys[@]}"; do
    value="$(jq -r ".${key}" "$INPUT_FILE")"
    echo "- [Modified] $key: $value" >&2

    jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$EDIT_FILE" > "$tmp"
    mv "$tmp" "$EDIT_FILE"
  done

  # echo >&2
  # echo "### UPDATED FILE ($EDIT_FILE) preview:" >&2
  # cat "$EDIT_FILE" >&2
}
