#!/bin/bash

ky_get_entity_essential_data() {
  local ENTITY_TYPE=$1
  local INPUT_FILE=$2
  local LOCAL_DEBUG=$3

  local year="?"
  local code="?"
  local entity_id="?"
  local entity_file="?"
  local error_msg=""

  if [ ! -e "$INPUT_FILE" ]; then
    error_msg="Input File Not Found: $INPUT_FILE."

    # array=("$code" "$entity_id" "$entity_file" "$error_msg")
    # array_string=$(ky_join_strings "${array[@]}")
    local array_string; array_string=$(ky_join_strings "$year" "$code" "$entity_id" "$entity_file" "$error_msg")
    echo "$array_string"
    exit 0
  fi

  # shellcheck source=/dev/null
  source "$(dirname "$0")/shared/constants.sh"

  # Year.
  if [ "$ENTITY_TYPE" = "event" ]; then 
    year="$(jq -r '.year' "$INPUT_FILE")"
    if [ "$year" = null ] || [ -z "$year" ]; then
      local date_starts; date_starts="$(jq -r '.date_starts' "$INPUT_FILE")"
      IFS="-" read -r -a date_components <<< "$date_starts" || 'true'
      year="${date_components[0]}"
    fi
  fi
  
  # Code.
  local region; region="$(jq -r '.region' "$INPUT_FILE")"
  # shellcheck disable=SC2206
  local region_components=($region)
  code=${region_components[0]}

  # Entity ID.
  local entity_id
  entity_id="$(jq -r '.id' "$INPUT_FILE")"
  # - Generate Entity ID for new one.
  if [ -z "$entity_id" ] || [ "$entity_id" = null ]; then
    local name; name="$(jq -r '.name' "$INPUT_FILE")"
    entity_id="$(__get_entity_id "$ENTITY_TYPE" "$name" "$year")"
    if [ -z "$entity_id" ]; then
      error_msg="Invalid Entity ID Generated from Name."
      local array_string; array_string=$(ky_join_strings "$year" "$code" "$entity_id" "$entity_file" "$error_msg")
      echo "$array_string"
      exit 0
    fi
    local tmp; tmp=$(mktemp)
    jq --arg jq_value "$entity_id" '.id = $jq_value' "$INPUT_FILE" > "$tmp" && mv "$tmp" "$INPUT_FILE"
  fi

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

  # Returns
  # echo "$year"
  # echo "$code"
  # echo "$entity_id"
  # echo "$entity_file"
  # echo "$error_msg"
  local array_string
  array_string="$(ky_join_strings "$year" "$code" "$entity_id" "$entity_file" "$error_msg")"
  echo "$array_string"
}

ky_join_strings() {
  # shellcheck source=/dev/null
  source "$(dirname "$0")/shared/constants.sh"
  local array_string; array_string="$(printf "${KY_STRING_DELIMITER}%s" "$@")"
  array_string="${array_string:${#separator}}"
  echo "$array_string"
}

# MARK: _Get Entity ID from Name
__get_entity_id() {
  local INPUT_ENTITY_TYPE=$1
  local INPUT_NAME=$2
  local INPUT_YEAR=$3 # Only required when INPUT_ENTITY_TYPE="event".

  if [ -z "$INPUT_NAME" ]; then
    echo ""
    return
  fi

  local entity_id
  entity_id="$(echo "$INPUT_NAME" | awk '{$1=$1};1')" # Rm leading & trailing whitespaces.
  entity_id="${entity_id//\'/}" # Rm "'".
  entity_id="${entity_id// & /-n-}" # Replace " & " with "-n-".
  entity_id="${entity_id//&/-n-}" # Replace "&" with "-n-".
  entity_id="${entity_id//[^a-zA-Z0-9-]/ }" # Keep "-", alpha & digit only chars, replace others with whitespace.
  entity_id="$(echo "$entity_id" | tr -s " ")" # Replace multiple whitespaces with one.
  entity_id="$(echo "${entity_id// /-}" | tr "[:upper:]" "[:lower:]")" # Replace whitespace to "-", and convert to lower case.
  entity_id="$(echo "$entity_id" | tr -s "-")" # Replace multiple "-" with one.

  if [ "$INPUT_ENTITY_TYPE" = "event" ]; then
    entity_id="${entity_id}-${INPUT_YEAR}"
  fi
  echo "$entity_id"
}

__test_get_entity_id() {
  local name result
  echo "  - > ${FUNCNAME[0]}"

  # Org
  name="abc"; result="$(__get_entity_id "org" "abc")"
  [ "$result" != "$name" ] && echo -e "- $name\nx $result" && exit 1

  name="ab-c"; result="$(__get_entity_id "org" "Ab C")"
  [ "$result" != "$name" ] && echo -e "- $name\nx $result" && exit 1

  name="b-c"; result="$(__get_entity_id "org" " b. !C ")"
  [ "$result" != "$name" ] && echo -e "- $name\nx $result" && exit 1

  name="b-c"; result="$(__get_entity_id "org" " b. !C " "2024")"
  [ "$result" != "$name" ] && echo -e "- $name\nx $result" && exit 1

  # Event
  name="bs-c-2024"; result="$(__get_entity_id "event" " b's. !C " "2024")"
  [ "$result" != "$name" ] && echo -e "- $name\nx $result" && exit 1

  name="aa-n-bb-n-cc-dd-ee-ff-2024"; result="$(__get_entity_id "event" " AA&BB & CC-DD - ee -- ff" "2024")"
  [ "$result" != "$name" ] && echo -e "- $name\nx $result" && exit 1

  echo "  - v ${FUNCNAME[0]}"
}


# MARK: - Tests
test_get_entity_essential_data_sh() {
  echo "# Start ${FUNCNAME[0]} ..."
  __test_get_entity_id
}
