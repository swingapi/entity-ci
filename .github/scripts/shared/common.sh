#!/bin/bash

ky_update_file_to_convert_value_from_array_to_string() {
  local INPUT_FILE=$1
  local KEYS=$2

  echo >&2
  echo "### UPDATE FILE ($INPUT_FILE): Convert values from array to string." >&2
  local tmp; tmp=$(mktemp)

  local value
  for key in $KEYS; do
    value="$(jq -r --arg jq_key "$key" '.[$jq_key] | if type == "array" then join(",") else . end' "$INPUT_FILE")"
    echo "- $key: $value" >&2

    jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$INPUT_FILE" > "$tmp"
    mv "$tmp" "$INPUT_FILE"
  done
}

ky_update_file_to_delete_all_empty_key_value_pairs() {
  local INPUT_FILE=$1

  echo >&2
  echo "### UPDATE FILE ($INPUT_FILE): Delete all empty key-value pairs." >&2

  local tmp; tmp=$(mktemp)
  jq 'del(.. | select(. == "" or . == null))' "$INPUT_FILE" > "$tmp" && mv "$tmp" "$INPUT_FILE"
}
