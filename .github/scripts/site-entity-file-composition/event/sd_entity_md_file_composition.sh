#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../common.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../sd_issue_url.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../sd_entity_md_file_composition.sh"

KY_TEMPLATE_EVENT_COMMON_KEYS=(
    "name"
    "name_local"
)
KY_TEMPLATE_EVENT_MULTILINE_SECTION_KEYS=(
    "venue"
    "details"
)

# MARK: LANG/YEAR/REGION/ENTITY.md

sd_compose_entity_md_file() {
  local lang=$1
  local year=$2
  local region_code=$3
  local entity_file=$4
  local entity_json_file=$5

  ky_func_log_verbose "${FUNCNAME[0]}" "$entity_file"

  # Metadata
  __map_entity_page_metadata "$entity_json_file" "$entity_file" "$year"
  # Common Values
  sd_entity_file_composition_map_entity_common_values "$entity_json_file" "$entity_file" "${KY_TEMPLATE_EVENT_COMMON_KEYS[@]}"
  # Session Value
  __map_entity_session_value "$entity_json_file" "$entity_file"
  # Date Value
  __map_entity_date_value "$entity_json_file" "$entity_file"
  # City Value
  sd_entity_file_composition_map_entity_city_value "$entity_json_file" "$entity_file" "$lang" "$region_code"
  # Org Value
  __map_entity_org_value "$entity_json_file" "$entity_file" "$lang" "$region_code"
  # Styles Value
  sd_entity_file_composition_map_entity_styles_value "$entity_json_file" "$entity_file"
  # Page URLs
  __map_entity_page_urls "$entity_json_file" "$entity_file" "$lang" "$year" "$region_code"
  # Contact Section
  sd_entity_file_composition_map_entity_contact_section "$entity_json_file" "$entity_file"
  # Multi-line Sections
  sd_entity_file_composition_map_entity_multiline_sections "$entity_json_file" "$entity_file" "${KY_TEMPLATE_EVENT_MULTILINE_SECTION_KEYS[@]}"

  # Clean up.
  # sed -i '' -e "/<!---/d" "$entity_file"
  ky_sed_delete "$entity_file" "<!---"
}

# MARK: _Mapping - Metadata
__map_entity_page_metadata() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  local year=$3
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
  local abb; abb="$(jq -r ".abb" "$entity_json_file")"
  if [ -z "$abb" ] || [ "$abb" = null ]; then
    # sed -i '' -e "/$template_value_key/d" "$tmp_entity_file"
    ky_sed_delete "$tmp_entity_file" "$template_value_key"
  else
    local subtitle="$abb $year"
    # sed -i '' -e "s/$template_value_key/$subtitle/g" "$tmp_entity_file"
    ky_sed_replace "$tmp_entity_file" "$template_value_key" "$subtitle"
  fi

  # Description
  template_value_key="{KY_VALUE_description}"
  local date_starts date_ends date_text
  date_starts="$(jq -r '.date_starts' "$entity_json_file")"
  date_ends="$(jq -r '.date_ends' "$entity_json_file")"
  if [ "$date_starts" = "$date_ends" ]; then
    # sed -i '' -e "s/$template_value_key/$date_starts/g" "$tmp_entity_file"
    ky_sed_replace "$tmp_entity_file" "$template_value_key" "$date_starts"
  else
    # sed -i '' -e "s/$template_value_key/$date_starts ~ $date_ends/g" "$tmp_entity_file"
    ky_sed_replace "$tmp_entity_file" "$template_value_key" "$date_starts ~ $date_ends"
  fi
  # local name_local; name_local="$(jq -r ".name_local" "$entity_json_file")"
  # if [ -z "$name_local" ]; then
  #   sed -i '' -e "/$template_value_key/d" "$tmp_entity_file"
  # else
  #   local description="$name_local - $year"
  #   awk -v s="$template_value_key" -v r="${description//&/\\\\&}" '{sub(s,r)}1' "$tmp_entity_file" > "$tmp"
  #   mv "$tmp" "$tmp_entity_file"
  # fi
}

__get_lang_source_folder_name() {
  local lang=$1
  if [ -z "$lang" ]; then
    ky_func_log_error "${FUNCNAME[0]}" "Invalid lang: $lang"
    exit 1
  fi
  [ "$lang" = "default" ] && echo "en" || echo "$lang"
}

# MARK: _Mapping - Page URLs
__map_entity_page_urls() {
  local INPUT_ENTITY_JSON_FILE=$1
  local INPUT_ENTITY_FILE=$2
  local INPUT_LANG=$3
  local INPUT_YEAR=$4
  local INPUT_REGION=$5
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local template_value_key page_url
  local tmp; tmp=$(mktemp)

  # Shared
  local event_id; event_id="$(jq -r ".id" "$INPUT_ENTITY_JSON_FILE")"

  # Add to Calendar
  template_value_key="{KY_VALUE_add_to_cal}"
  local lang_folder_name; lang_folder_name="$(__get_lang_source_folder_name "$INPUT_LANG")"
  page_url="https://swing.news/ics/$lang_folder_name/$INPUT_YEAR/$INPUT_REGION/$event_id.ics"
  awk -v s="$template_value_key" -v r="$page_url" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"

  # Edit Info
  template_value_key="{KY_VALUE_edit_info}"

  local org_id; org_id="$(jq -r ".org_id" "$INPUT_ENTITY_JSON_FILE")"
  [ "$org_id" = null ] && org_id=""

  local name; name="$(jq -r ".name" "$INPUT_ENTITY_JSON_FILE")"
  # province=$(jq -r ".province" "$INPUT_ENTITY_JSON_FILE")
  # city=$(jq -r ".city" "$INPUT_ENTITY_JSON_FILE")
  page_url="$(sd_issue_url_to_update_event "$INPUT_YEAR" "$INPUT_REGION" "$event_id" "$org_id" "$name")"
  awk -v s="$template_value_key" -v r="${page_url//&/\\\\&}" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"

  # View Edit History
  template_value_key="{KY_VALUE_view_edit_history}"
  page_url="https://github.com/swingdance/events/commits/main/$INPUT_YEAR/$INPUT_REGION/$event_id.json"
  awk -v s="$template_value_key" -v r="$page_url" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"
  # - Updated At
  template_value_key="{KY_VALUE_updated_at}"
  local updated_at; updated_at="$(jq -r ".updated_at" "$INPUT_ENTITY_JSON_FILE")"
  awk -v s="$template_value_key" -v r="$updated_at" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"

  # View Raw Source File
  template_value_key="{KY_VALUE_view_raw_source_file}"
  page_url="https://github.com/swingdance/events/blob/main/$INPUT_YEAR/$INPUT_REGION/$event_id.json"
  awk -v s="$template_value_key" -v r="$page_url" '{sub(s,r)}1' "$INPUT_ENTITY_FILE" > "$tmp" && mv "$tmp" "$INPUT_ENTITY_FILE"
}

# MARK: _Mapping - Session
__map_entity_session_value() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local key="session"
  local template_value_key="{KY_VALUE_$key}"

  local value; value="$(jq -r ".${key}" "$entity_json_file")"
  if [ -n "$value" ] && [ "$value" != null ]; then
    # sed -i '' -e "s/$template_value_key/^$value^/g" "$tmp_entity_file" # TODO: "^6^" > "^6th^"
    ky_sed_replace "$tmp_entity_file" "$template_value_key" "^$value^"
  else
    # sed -i '' -e "s/$template_value_key//g" "$tmp_entity_file"
    ky_sed_replace "$tmp_entity_file" "$template_value_key" ""
  fi
}

# MARK: _Mapping - Date
__map_entity_date_value() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local template_value_key="{KY_VALUE_date}"

  local date_starts date_ends date_text
  date_starts="$(jq -r '.date_starts' "$entity_json_file")"
  date_ends="$(jq -r '.date_ends' "$entity_json_file")"
  # date_text="$(util_get_timeline_entity_date_text "$date_starts" "$date_ends")"
  date_text="$date_starts ~ $date_ends"
  
  # sed -i '' -e "s/$template_value_key/$date_text/g" "$tmp_entity_file"
  ky_sed_replace "$tmp_entity_file" "$template_value_key" "$date_text"
}

# MARK: _Mapping - Org

__map_entity_org_value() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  local lang=$3
  local region_code=$4
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local section_key="organizer"
  local template_section_start="KY_SECTION_$section_key"
  local template_section_end="$template_section_start END"

  local org_id_raw_value; org_id_raw_value=$(jq -r ".org_id" "$entity_json_file")
  if [ -z "$org_id_raw_value" ] || [ "$org_id_raw_value" = null ]; then
    # sed -i '' -e "/$template_section_start/,/$template_section_end/d" "$tmp_entity_file"
    ky_sed_delete "$tmp_entity_file" "$template_section_start/,/$template_section_end"
    return
  fi

  local content content_line
  local org_json_file
  local org_name_local org_name org_url

  IFS=',' read -r -a org_ids <<< "$org_id_raw_value"
  for org_id in "${org_ids[@]}"; do
    org_url="https://swing.kids/$region_code/$org_id"

    org_json_file="$SD_ORGS_JSON_REPO_PATH/$region_code/$org_id.json"
    if [ -f "$org_json_file" ]; then
      org_name="$(jq -r '.name' "$org_json_file")"
    else
      ky_func_log_warn "${FUNCNAME[0]}" "Org JSON File Not Found: $org_json_file"
      org_name=""
    fi
    
    if [ -z "$org_name" ] || [ "$org_name" = null ]; then
      content_line="    $org_id  "
    else
      # TEST:
      # $ csvgrep -c id -r "^rhythm-studio$" test_repos/orgs-csv/regions/zh_HK.csv | csvcut -c "id,name,name_local" | csvcut -c "name_local" | sed 1d
      # org_name_local="$(echo "$matched_org_row" | csvcut -c "name_local" | sed 1d)"
      org_name_local="$(jq -r '.name_local' "$org_json_file")"
      if [ -n "$org_name_local" ] && [ "$org_name_local" != null ] && [ "$org_name_local" != "\"\"" ]; then
        content_line="    [$org_name]($org_url) • $org_name_local  "
      else
        content_line="    [$org_name]($org_url)  "
      fi
    fi
    [ -z "$content" ] && content="$content_line" || content="$(echo -e "$content\n$content_line")"
  done

  # sed -i '' -e "/$template_section_start/d" "$tmp_entity_file"
  # sed -i '' -e "/$template_section_end/d" "$tmp_entity_file"
  ky_sed_delete "$tmp_entity_file" "$template_section_start"
  ky_sed_delete "$tmp_entity_file" "$template_section_end"

  local template_value_key="{KY_VALUE_$section_key}"
  local tmp; tmp=$(mktemp)

  awk '
  BEGIN { s=ARGV[1]; r=ARGV[2]; delete ARGV[1]; delete ARGV[2]; }
  { sub(s,r) }1
  END {}' "$template_value_key" "${content//&/\\\\&}" "$tmp_entity_file" > "$tmp"
  mv "$tmp" "$tmp_entity_file"
}
