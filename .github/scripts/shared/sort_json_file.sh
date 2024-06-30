#!/bin/bash

ky_sort_json_file() {
  local INPUT_ENTITY_FILE=$1

  # local region_dir; region_dir="$(dirname "$INPUT_ENTITY_FILE")"
  local json_template_file="$KY_TEMPLATE_ID.json"

  echo >&2
  echo "### Sort $INPUT_ENTITY_FILE with $json_template_file" >&2

  local sorted_file="sorted.json"
  cp -v "$json_template_file" "$sorted_file"
  local tmp; tmp=$(mktemp)

  while read -r key; do
    value="$(jq -r ".$key" "$INPUT_ENTITY_FILE")"
    echo "- $key: $value"
    if [ "$value" = null ] || [ -z "$value" ]; then
      jq --arg jq_key "$key" 'del(.[$jq_key])' "$sorted_file" > "$tmp"
    else
      jq --arg jq_key "$key" --arg jq_value "$value" '.[$jq_key] = $jq_value' "$sorted_file" > "$tmp"
    fi
    mv "$tmp" "$sorted_file"
  done < <(jq -r 'keys_unsorted[]' "$json_template_file")

  rm -v "$INPUT_ENTITY_FILE"
  mv -v "$sorted_file" "$INPUT_ENTITY_FILE"
}
