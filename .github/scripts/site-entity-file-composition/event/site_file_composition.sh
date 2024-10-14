#!/bin/bash

KY_TEMPLATE_EVENT_COMMON_KEYS=(
    "name"
    "name_local"
)
KY_TEMPLATE_EVENT_MULTILINE_SECTION_KEYS=(
    "venue"
    "details"
)
export KY_TEMPLATE_EVENT_COMMON_KEYS KY_TEMPLATE_EVENT_MULTILINE_SECTION_KEYS

# MARK: Compose

compose_site_files_for_one_entity() {
  local INPUT_YEAR=$1
  local INPUT_REGION=$2
  local INPUT_ENTITY_ID=$3
  local INPUT_ENTITY_JSON_FILE=$4

  ky_func_log_info "${FUNCNAME[0]}" ""

  local templates_dir; templates_dir="$(dirname "$0")/site-entity-file-composition/event/templates"
  if [ ! -d "$templates_dir" ]; then
    ky_func_log_error "${FUNCNAME[0]}" "Templates not found: $templates_dir"
    exit 1
  fi

  if [ -n "$G_IS_CI" ]; then
    echo "Install csvkit..."
    python3 -m venv .venv
    # shellcheck source=/dev/null
    source .venv/bin/activate
    pip install -q csvkit
  fi

  # shellcheck source=/dev/null
  source "$(dirname "$0")/site-entity-file-composition/constants.sh"
  # shellcheck source=/dev/null
  source "$(dirname "$0")/site-entity-file-composition/sd_issue_url.sh"
  # shellcheck source=/dev/null
  source "$(dirname "$0")/site-entity-file-composition/sd_localization.sh"
  # shellcheck source=/dev/null
  source "$(dirname "$0")/site-entity-file-composition/event/sd_entity_md_file_composition.sh"
  # shellcheck source=/dev/null
  source "$(dirname "$0")/site-entity-file-composition/event/sd_entity_ics_file_composition.sh"

  local lang_folder_name region_dir entity_md_file entity_ics_file

  for lang in "${KY_SWING_NEWS_LANGS[@]}"; do
    echo "# Compose site files for $lang"
    sd_prepare_shared_localized_text_for_lang "$lang"

    lang_folder_name="$(ky_get_lang_folder_name "$lang")"

    # Compoose .md file.
    region_dir="$KY_MD_DIR/$lang_folder_name/$INPUT_YEAR/$INPUT_REGION"
    [ ! -d "$region_dir" ] && mkdir -p "$region_dir"

    entity_md_file="$region_dir/$INPUT_ENTITY_ID.md"
    echo "- $entity_md_file"
    cp "$templates_dir/$lang_folder_name/YEAR-REGION-EVENT.md" "$entity_md_file"
    sd_compose_entity_md_file "$lang" "$INPUT_YEAR" "$INPUT_REGION" "$entity_md_file" "$INPUT_ENTITY_JSON_FILE"

    # Compoose .ics file.
    region_dir="$KY_ICS_DIR/$lang_folder_name/$INPUT_YEAR/$INPUT_REGION"
    [ ! -d "$region_dir" ] && mkdir -p "$region_dir"

    entity_ics_file="$region_dir/$INPUT_ENTITY_ID.ics"
    echo "- $entity_ics_file"
    [ -f "$entity_ics_file" ] && rm "$entity_ics_file"
    touch "$entity_ics_file"
    sd_compose_entity_ics_file "$lang" "$INPUT_YEAR" "$INPUT_REGION" "$INPUT_ENTITY_ID" "$entity_ics_file" "$INPUT_ENTITY_JSON_FILE"
  done
}
