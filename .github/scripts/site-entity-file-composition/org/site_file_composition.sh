#!/bin/bash

# MARK: Compose

compose_site_files_for_one_entity() {
  local INPUT_REGION=$1
  local INPUT_ENTITY_ID=$2
  local INPUT_ENTITY_JSON_FILE=$3

  ky_func_log_info "${FUNCNAME[0]}" ""

  local templates_dir; templates_dir="$(dirname "$0")/site-entity-file-composition/org/templates"
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
  source "$(dirname "$0")/site-entity-file-composition/org/sd_entity_md_file_composition.sh"

  local template_file 
  local lang_folder_name region_dir entity_md_file

  for lang in "${KY_SWING_KIDS_LANGS[@]}"; do
    echo "# Compose site files for $lang"
    sd_prepare_shared_localized_text_for_lang "$lang"

    lang_folder_name="$(ky_get_lang_folder_name "$lang")"

    # Compoose .md file.
    template_file="$templates_dir/$lang_folder_name/REGION-ORG.md"
    if [ ! -f "$template_file" ]; then
      ky_func_log_error "${FUNCNAME[0]}" "Template file not found: $template_file"
      exit 1
    fi

    region_dir="$KY_MD_DIR/$lang_folder_name/$INPUT_REGION"
    [ ! -d "$region_dir" ] && mkdir -p "$region_dir"

    entity_md_file="$region_dir/$INPUT_ENTITY_ID.md"
    echo "- $entity_md_file"
    cp "$template_file" "$entity_md_file"
    sd_compose_entity_md_file "$lang" "$INPUT_REGION" "$entity_md_file" "$INPUT_ENTITY_JSON_FILE"
  done
}
