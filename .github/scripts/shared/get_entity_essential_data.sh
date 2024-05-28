#!/bin/bash

ky_get_entity_essential_data() {
  local ENTITY_TYPE=$1
  local INPUT_FILE=$2
  local LOCAL_DEBUG=$3

  local year="?"
  local code="?"
  local entity_id="?"
  local entity_file="?"
  local template_file="?"
  local error_msg=""

  if [ ! -e "$INPUT_FILE" ]; then
    error_msg="Input File Not Found: $INPUT_FILE."

    # array=("$code" "$entity_id" "$entity_file" "$template_file" "$error_msg")
    # array_string=$(ky_join_strings "${array[@]}")
    local array_string; array_string=$(ky_join_strings "$year" "$code" "$entity_id" "$entity_file" "$template_file" "$error_msg")
    echo "$array_string"
    exit 0
  fi

  # shellcheck source=/dev/null
  source "$(dirname "$0")/shared/constants.sh"

  # Year.
  if [ "$ENTITY_TYPE" = "event" ]; then 
    year="$(jq -r '.year' "$INPUT_FILE")"
    if [ -z "$year" ]; then
      local date_starts; date_starts="$(jq -r '.date_starts' "$INPUT_FILE")"
      IFS="-" read -r -a date_components <<< "$date_starts"
      year="${date_components[0]}"
    fi
  fi
  
  # Code.
  local region; region="$(jq -r '.region' "$INPUT_FILE")"
  # shellcheck disable=SC2206
  local region_components=($region)
  code=${region_components[0]}

  # Entity ID.
  entity_id="$(jq -r '.id' "$INPUT_FILE")"

  echo "year: $year, region: $region, code: $code, entity_id: $entity_id" >&2

  # Region dir.
  if [ "$ENTITY_TYPE" = "org" ]; then
    region_dir="$code"
  elif [ "$ENTITY_TYPE" = "event" ]; then
    region_dir="$year/$code"
  else
    region_dir="$code"
  fi

  # Entity File Path.
  entity_file="$region_dir/$entity_id.json"

  # Check if region folder exists.
  if [ ! -d "$region_dir" ]; then
    echo >&2
    echo "### Folder not found: $region_dir, create it." >&2
    mkdir -p "$region_dir"
  fi

  # Check if template file exists.
  template_file="$region_dir/$KY_TEMPLATE_ID.json"
  if [ ! -e "$template_file" ]; then
    echo >&2
    echo "### Template File Not Found: $template_file, create it." >&2
    cp -v "$KY_TEMPLATE_ID.json" "$template_file" >&2
  fi

  # Returns
  # echo "$year"
  # echo "$code"
  # echo "$entity_id"
  # echo "$entity_file"
  # echo "$template_file"
  # echo "$error_msg"
  local array_string
  array_string="$(ky_join_strings "$year" "$code" "$entity_id" "$entity_file" "$template_file" "$error_msg")"
  echo "$array_string"
}

ky_join_strings() {
  # shellcheck source=/dev/null
  source "$(dirname "$0")/shared/constants.sh"
  local array_string; array_string="$(printf "${KY_STRING_DELIMITER}%s" "$@")"
  array_string="${array_string:${#separator}}"
  echo "$array_string"
}
