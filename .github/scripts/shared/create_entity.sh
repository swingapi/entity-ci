#!/bin/bash

ky_prepare_edit_file_to_create_entity() {
  local INPUT_FILE=$1
  local LOCAL_DEBUG=$2

  echo >&2
  echo "### Prepare an edit file to create entity." >&2
  if [ -n "$LOCAL_DEBUG" ]; then
    local temp_edit_file="$INPUT_FILE~"
    cp -v "$INPUT_FILE" "$temp_edit_file" >&2
  else
    local temp_edit_file="$INPUT_FILE"
  fi

  echo "$temp_edit_file"
}

# MARK: Adjust Values

ky_adjust_values_for_new_entity_file() {
  local INPUT_FILE=$1

  local key value
  local tmp; tmp=$(mktemp)

  # Province
  key="province"
  value="$(jq -r ".${key}" "$INPUT_FILE")"
  if [ -z "$value" ] || [ "$value" = null ]; then
    value="$(jq -r ".city" "$INPUT_FILE")"
    jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$INPUT_FILE" > "$tmp" && mv "$tmp" "$INPUT_FILE"
  fi
  
  # Styles
  key="styles"
  value="$(jq -r ".${key}" "$INPUT_FILE")"
  if [ "$value" = "SAME" ]; then
    return
  elif [ "$value" = "ANY" ]; then
    value=""
  fi
  jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$INPUT_FILE" > "$tmp" && mv "$tmp" "$INPUT_FILE"
}
