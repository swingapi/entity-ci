#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../common.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../sd_issue_url.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../sd_entity_md_file_composition.sh"

KY_TEMPLATE_ORG_COMMON_KEYS=(
    "name"
    "name_local"
    "since"
)
KY_TEMPLATE_ORG_MULTILINE_SECTION_KEYS=(
    "venue"
    "notes"
)

# MARK: LANG/YEAR/REGION/ENTITY.md

sd_compose_entity_md_file() {
  local lang=$1
  local region_code=$2
  local entity_file=$3
  local entity_json_file=$4

  ky_func_log_verbose "${FUNCNAME[0]}" "$entity_file"

  # Metadata
  __map_entity_page_metadata "$entity_json_file" "$entity_file"
  # Common Values
  sd_entity_file_composition_map_entity_common_values "$entity_json_file" "$entity_file" "${KY_TEMPLATE_ORG_COMMON_KEYS[@]}"
  # City Value
  sd_entity_file_composition_map_entity_city_value "$entity_json_file" "$entity_file" "$lang" "$region_code"
  # Styles Value
  sd_entity_file_composition_map_entity_styles_value "$entity_json_file" "$entity_file"
  # Party
  __map_entity_page_party "$entity_json_file" "$entity_file" "$lang"
  # Page URLs
  __map_entity_page_urls "$entity_json_file" "$entity_file" "$region_code"
  # Contact Section
  sd_entity_file_composition_map_entity_contact_section "$entity_json_file" "$entity_file"
  # Multi-line Sections
  sd_entity_file_composition_map_entity_multiline_sections "$entity_json_file" "$entity_file" "${KY_TEMPLATE_ORG_MULTILINE_SECTION_KEYS[@]}"

  [ -f "$tmp_entity_file" ] && echo "111 - 3"

  # Clean up.
  # sed -i '' -e "/<!---/d" "$entity_file"
  ky_sed_delete "$entity_file" "<!---"
}

# MARK: _Mapping - Metadata
__map_entity_page_metadata() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local template_value_key
  local tmp; tmp=$(mktemp)

  # Title
  template_value_key="{KY_VALUE_title}"
  local name; name="$(jq -r ".name" "$entity_json_file")"
  awk -v s="$template_value_key" -v r="${name//&/\\\\&}" '{sub(s,r)}1' "$tmp_entity_file" > "$tmp"
  mv "$tmp" "$tmp_entity_file"

  # Subtitle
  template_value_key="{KY_VALUE_subtitle}"
  local name_local; name_local="$(jq -r ".name_local" "$entity_json_file")"
  if [ -z "$name_local" ] || [ "$name_local" = null ]; then
    # sed -i '' -e "/$template_value_key/d" "$tmp_entity_file"
    ky_sed_delete "$tmp_entity_file" "$template_value_key"
  else
    local subtitle="$name_local"
    # sed -i '' -e "s/$template_value_key/$subtitle/g" "$tmp_entity_file"
    ky_sed_replace "$tmp_entity_file" "$template_value_key" "$subtitle"
  fi

  # Description
  template_value_key="{KY_VALUE_description.name}"
  awk -v s="$template_value_key" -v r="${name//&/\\\\&}" '{sub(s,r)}1' "$tmp_entity_file" > "$tmp"
  mv "$tmp" "$tmp_entity_file"
}

# MARK: _Mapping - Party
__map_entity_page_party() {
  local INPUT_ENTITY_JSON_FILE=$1
  local INPUT_ENTITY_FILE=$2
  local INPUT_LANG=$3
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local section_key="party"
  local template_section_start="KY_SECTION_$section_key"
  local template_section_end="$template_section_start END"

  local raw_value; raw_value="$(jq -r ".${section_key}" "$INPUT_ENTITY_JSON_FILE")"

  local multiline_content=""
  if [ -n "$raw_value" ] && [ "$raw_value" != null ]; then
    local day_and_times localized_day day time
    IFS=',' read -r -a day_and_times <<< "$raw_value"
    for day_and_time in "${day_and_times[@]}"; do
      day="${day_and_time%-*}"
      localized_day="$(__localized_party_week_day "$INPUT_LANG" "$day")"
      if [ -z "$localized_day" ]; then
        continue
      fi
      time="${day_and_time#*-}"
      multiline_content="${multiline_content}    ${localized_day} ${time//~/ ~ }  \n"
    done
  fi

  if [ -z "$multiline_content" ]; then
    ky_sed_delete "$INPUT_ENTITY_FILE" "$template_section_start/,/$template_section_end"
  else
    ky_sed_delete "$INPUT_ENTITY_FILE" "$template_section_start"
    ky_sed_delete "$INPUT_ENTITY_FILE" "$template_section_end"

    multiline_content="$(echo -e "$multiline_content")"

    local template_value_key="{KY_VALUE_$section_key}"
    local tmp; tmp=$(mktemp)
    awk '
    BEGIN { s=ARGV[1]; r=ARGV[2]; delete ARGV[1]; delete ARGV[2]; }
    { sub(s,r) }1
    END {}' "$template_value_key" "$multiline_content" "$INPUT_ENTITY_FILE" > "$tmp"
    mv "$tmp" "$INPUT_ENTITY_FILE"
  fi
}

# MARK: _Mapping - Party - Week Day
__localized_party_week_day() {
  local INPUT_LANG=$1
  local INPUT_DAY=$2

  local localized_day
  if [ "$INPUT_LANG" = "zh-Hans" ]; then
    if   [ "$INPUT_DAY" = "5" ]; then localized_day="每周五"
    elif [ "$INPUT_DAY" = "6" ]; then localized_day="每周六"
    elif [ "$INPUT_DAY" = "0" ]; then localized_day="每周日"
    elif [ "$INPUT_DAY" = "1" ]; then localized_day="每周一"
    elif [ "$INPUT_DAY" = "2" ]; then localized_day="每周二"
    elif [ "$INPUT_DAY" = "3" ]; then localized_day="每周三"
    elif [ "$INPUT_DAY" = "4" ]; then localized_day="每周四"
    fi
  else
    if   [ "$INPUT_DAY" = "5" ]; then localized_day="Every Friday"
    elif [ "$INPUT_DAY" = "6" ]; then localized_day="Every Saturday"
    elif [ "$INPUT_DAY" = "0" ]; then localized_day="Every Sunday"
    elif [ "$INPUT_DAY" = "1" ]; then localized_day="Every Monday"
    elif [ "$INPUT_DAY" = "2" ]; then localized_day="Every Tuesday"
    elif [ "$INPUT_DAY" = "3" ]; then localized_day="Every Wednesday"
    elif [ "$INPUT_DAY" = "4" ]; then localized_day="Every Thursday"
    fi
  fi
  echo "$localized_day"
}

# MARK: _Mapping - Page URLs
__map_entity_page_urls() {
  local INPUT_ENTITY_JSON_FILE=$1
  local INPUT_ENTITY_FILE=$2
  local INPUT_REGION=$3
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local template_value_key page_url
  local tmp; tmp=$(mktemp)

  # Shared
  local org_id; org_id="$(jq -r ".id" "$INPUT_ENTITY_JSON_FILE")"

  # Edit Info
  template_value_key="{KY_VALUE_edit_info}"
  local name; name="$(jq -r ".name" "$INPUT_ENTITY_JSON_FILE")"
  page_url="$(sd_issue_url_to_update_org "$INPUT_REGION" "$org_id" "$name")"
  awk -v s="$template_value_key" -v r="${page_url//&/\\\\&}" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"

  # View Edit History
  template_value_key="{KY_VALUE_view_edit_history}"
  page_url="https://github.com/swingdance/orgs/commits/main/$INPUT_REGION/$org_id.json"
  awk -v s="$template_value_key" -v r="$page_url" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"
  # - Updated At
  template_value_key="{KY_VALUE_updated_at}"
  local updated_at; updated_at="$(jq -r ".updated_at" "$INPUT_ENTITY_JSON_FILE")"
  awk -v s="$template_value_key" -v r="$updated_at" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"

  # View Raw Source File
  template_value_key="{KY_VALUE_view_raw_source_file}"
  page_url="https://github.com/swingdance/orgs/blob/main/$INPUT_REGION/$org_id.json"
  awk -v s="$template_value_key" -v r="$page_url" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"

  # Add Event
  template_value_key="{KY_VALUE_add_event}"
  local province; province="$(jq -r ".province" "$INPUT_ENTITY_JSON_FILE")"
  local city; city="$(jq -r ".city" "$INPUT_ENTITY_JSON_FILE")"
  page_url="$(sd_issue_url_to_add_event "$INPUT_REGION" "$province" "$city" "$G_CURRENT_YEAR" "" "$org_id")"
  awk -v s="$template_value_key" -v r="${page_url//&/\\\\&}" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"
}
