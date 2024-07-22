#!/bin/bash

# MARK: - Prepare some localized text for entity (shared)

sd_prepare_shared_localized_text_for_lang() {
  local INPUT_LANG=$1

  # Entity
  # - Contact
  g_localized_entity_contact_title="$(sd_localization_localized_text "$SD_LOCALIZATIONS_CSV_REPO_PATH/contact.csv" "$INPUT_LANG" "contact")"
  export g_localized_entity_contact_title
}

# MARK: - Get localized city/province.

sd_localization_get_localized_city() {
  local lang=$1
  local region=$2
  local city=$3
  ky_func_log_verbose "${FUNCNAME[0]}" "- lang: $lang, region: $region"

  if [ ! -d "$SD_REGIONS_CSV_REPO_PATH" ]; then
    ky_func_log_error "${FUNCNAME[0]}" "Localizations repo not found: $SD_REGIONS_CSV_REPO_PATH."
    exit 1
  fi
  local localization_csv_file="$SD_REGIONS_CSV_REPO_PATH/city/$region.csv"
  local localized_value

  if [ -f "$localization_csv_file" ]; then
    localized_value=$(csvgrep -c key -r "^$city$" "$localization_csv_file" | csvcut -c "$lang" | sed 1d)
    if [ -z "$localized_value" ] || [ "$localized_value" = null ]; then
      localized_value=$(csvgrep -c key -r "^$city$" "$localization_csv_file" | csvcut -c "default" | sed 1d)
    fi
  else
    localized_value=$city
  fi
  [ -n "$localized_value" ] && echo "$localized_value" || echo "$city"
}

# MARK: - Get localized text

sd_localization_localized_text() {
  local localization_csv_file=$1
  local lang=$2
  local key=$3
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local localized_value
  if [ -f "$localization_csv_file" ]; then
    localized_value=$(csvgrep -c key -r "^$key$" "$localization_csv_file" | csvcut -c "$lang" | sed 1d)
    if [ -z "$localized_value" ] || [ "$localized_value" = null ]; then
      localized_value=$(csvgrep -c key -r "^$key$" "$localization_csv_file" | csvcut -c "default" | sed 1d)
    fi
  else
    localized_value="$key"
  fi
  echo "$localized_value"
}
