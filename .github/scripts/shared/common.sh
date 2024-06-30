#!/bin/bash

ky_update_file_to_convert_value_from_array_to_string() {
  local INPUT_FILE=$1
  shift 1
  local INPUT_KEYS=("$@")

  echo >&2
  echo "### UPDATE FILE ($INPUT_FILE): Convert values from array to string." >&2
  local tmp; tmp=$(mktemp)

  local value
  for key in "${INPUT_KEYS[@]}"; do
    value="$(jq -r --arg jq_key "$key" '.[$jq_key] | if type == "array" then join(",") else . end' "$INPUT_FILE")"
    echo "- $key: $value" >&2

    jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$INPUT_FILE" > "$tmp"
    mv "$tmp" "$INPUT_FILE"
  done
}

ky_update_file_to_update_contributors() {
  local INPUT_JSON_FILE=$1
  local INPUT_CONTRIBUTOR=$2

  local key="contributors"
  local array_delimiter="${KY_CONTRIBUTORS_ARRAY_DELIMITER:?}"
  local a_contributor_wrap="${array_delimiter}${INPUT_CONTRIBUTOR}${array_delimiter}"

  local contributors
  contributors="$(jq -r ".$key" "$INPUT_JSON_FILE")"
  if [ -z "$contributors" ] || [ "$contributors" = null ]; then
    contributors="$a_contributor_wrap"
  elif [[ "$contributors" != *"$a_contributor_wrap"* ]]; then
    contributors="${contributors}${INPUT_CONTRIBUTOR}${array_delimiter}"
  fi

  if [ -n "$contributors" ]; then
    local tmp; tmp=$(mktemp)
    jq --arg jq_key "$key" --arg jq_value "$contributors" '.[$jq_key] = $jq_value' "$INPUT_JSON_FILE" > "$tmp"
    mv "$tmp" "$INPUT_JSON_FILE"
  fi
}

ky_update_file_to_delete_all_empty_key_value_pairs() {
  local INPUT_FILE=$1

  echo >&2
  echo "### UPDATE FILE ($INPUT_FILE): Delete all empty key-value pairs." >&2

  local tmp; tmp=$(mktemp)
  jq 'del(.. | select(. == "" or . == null))' "$INPUT_FILE" > "$tmp" && mv "$tmp" "$INPUT_FILE"
}
