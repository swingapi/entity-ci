#!/bin/bash

# MARK: Mapping - Common
sd_entity_file_composition_map_entity_common_values() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  shift 2
  local keys=("$@")
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local template_value_key value
  local tmp; tmp=$(mktemp)

  # local name_abb name name_local entity_title
  # name_abb="$(jq -r '.abb' "$entity_json_file")"
  # name="$(jq -r '.name' "$entity_json_file")"
  # name_local="$(jq -r '.name_local' "$entity_json_file")"
  # entity_title="$(util_get_entity_title "$name_abb" "$name" "$name_local")"
  
  for key in "${keys[@]}"; do
    template_value_key="{KY_VALUE_$key}"
    value="$(jq -r ".${key}" "$entity_json_file")"
    ky_func_log_verbose "${FUNCNAME[0]}" "- $key: $value"

    if [ -n "$value" ] && [ "$value" != null ]; then
      awk -v s="$template_value_key" -v r="${value//&/\\\\&}" '{sub(s,r)}1' "$tmp_entity_file" > "$tmp"
      mv "$tmp" "$tmp_entity_file"
    else
      # sed -i '' -e "/$template_value_key/d" "$tmp_entity_file"
      ky_sed_delete "$tmp_entity_file" "$template_value_key"
    fi
  done
}

# MARK: Mapping - City

sd_entity_file_composition_map_entity_city_value() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  local lang=$3
  local region_code=$4
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  # local province city
  # province="$(jq -r '.province' "$entity_json_file")"
  # city="$(jq -r '.city' "$entity_json_file")"

  local key="city"
  local template_value_key="{KY_VALUE_$key}"
  local tmp; tmp=$(mktemp)

  local city; city=$(jq -r ".${key}" "$entity_json_file")
  
  if [ -n "$city" ] && [ "$city" != null ]; then
    local localized_city
    localized_city="$(sd_localization_get_localized_city "$lang" "$region_code" "$city")"
    awk -v s="$template_value_key" -v r="$localized_city" '{sub(s,r)}1' "$tmp_entity_file" > "$tmp"
    mv "$tmp" "$tmp_entity_file"
  else
    # sed -i '' -e "/$template_value_key/d" "$tmp_entity_file"
    ky_sed_delete "$tmp_entity_file" "$template_value_key"
  fi
}

# MARK: Mapping - Styles

sd_entity_file_composition_map_entity_styles_value() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local key="styles"
  local template_value_key="{KY_VALUE_$key}"
  local template_section_start="KY_SECTION_$key"
  local template_section_end="<!--- ${template_section_start} END -->"

  local value; value=$(jq -r ".${key}" "$entity_json_file")
  if [ -z "$value" ] || [ "$value" = null ]; then
    # sed -i '' -e "/$template_value_key/d" "$tmp_entity_file"
    # sed -i '' -e "/$template_section_start/,/$template_section_end/d" "$tmp_entity_file"
    ky_sed_delete "$tmp_entity_file" "$template_section_start/,/$template_section_end"
    return
  fi

  local styles
  IFS=',' read -r -a styles <<< "$value"
  for style in "${styles[@]}"; do
    __insert_line_before_template_anchor "$tmp_entity_file" "  - $style" "$template_section_end"
  done
}

# MARK: Mapping - Contact

sd_entity_file_composition_map_entity_contact_section() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  # local tmp_entity_contact_file=$3
  # shift 3
  # local keys=("$@")
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local section_key="contact"
  local is_section_available=""
  local tmp; tmp=$(mktemp)

  local template_value_key value adjusted_value

  local tmp_entity_contact_file
  if [ -n "$G_IS_CI" ]; then
    tmp_entity_contact_file="tmp_entity_contact.md"
  else
    tmp_entity_contact_file="$KY_TMP_DIR/tmp_entity_contact.md"
  fi
  touch "$tmp_entity_contact_file"
  echo -e "\n## ${g_localized_entity_contact_title:?}\n" >> "$tmp_entity_contact_file"

  # Contact Common
  KY_ENTITY_CONTACT_COMMON_KEYS=(
      "email"
      "website"
  )
  for contact_key in "${KY_ENTITY_CONTACT_COMMON_KEYS[@]}"; do
    # template_value_key="{KY_VALUE_$contact_key}"
    value=$(jq -r ".${contact_key}" "$entity_json_file")

    if [ -z "$value" ] || [ "$value" = null ]; then
      # sed -i '' -e "/$template_value_key/d" "$tmp_entity_contact_file"
      continue
    fi
    is_section_available="1"

    # Email
    if [ "$contact_key" = "email" ]; then
      echo ":fontawesome-solid-envelope: <$value>  " >> "$tmp_entity_contact_file"
    # Website
    elif [ "$contact_key" = "website" ]; then
      echo ":fontawesome-solid-globe: <$value>{ target='_blank' }  " >> "$tmp_entity_contact_file"
    # Unknown
    else
      echo ":fontawesome-fa-question: $value  " >> "$tmp_entity_contact_file"
    fi
    # awk -v s="$template_value_key" -v r="${adjusted_value//&/\\\\&}" '{sub(s,r)}1' "$tmp_entity_contact_file" > "$tmp"
    # mv "$tmp" "$tmp_entity_contact_file"
  done

  # Social Links
  local social_links=""

  KY_ENTITY_CONTACT_SOCIAL_LINK_KEYS=(
      "fb"
      "ig"
      "yt"
      "bl"
      "rb"
      "wo"
  )
  for contact_key in "${KY_ENTITY_CONTACT_SOCIAL_LINK_KEYS[@]}"; do
    # template_value_key="{KY_VALUE_$contact_key}"
    value=$(jq -r ".${contact_key}" "$entity_json_file")

    if [ -z "$value" ] || [ "$value" = null ]; then
      # sed -i '' -e "/$template_value_key/d" "$tmp_entity_contact_file"
      continue
    fi
    is_section_available="1"

    # Facebook
    if [ "$contact_key" = "fb" ]; then
      if   [[ "$value" =~ "https://" ]]; then adjusted_value="$value"
      elif [[ "$value" =~ "id=" ]];      then adjusted_value="https://www.facebook.com/profile.php?$value"
      else                                    adjusted_value="https://www.facebook.com/$value"
      fi
      social_links="$social_links [:fontawesome-brands-facebook-f:{ .ky_social_links_icon }]($adjusted_value){ target='_blank' }"
    # Instagram
    elif [ "$contact_key" = "ig" ]; then
      if [[ "$value" =~ "https://" ]]; then adjusted_value="$value"
      else                                  adjusted_value="https://instagram.com/$value"
      fi
      social_links="$social_links [:fontawesome-brands-instagram:{ .ky_social_links_icon }]($adjusted_value){ target='_blank' }"
    # YouTube
    elif [ "$contact_key" = "yt" ]; then
      if [[ "$value" =~ "https://" ]]; then adjusted_value="$value"
      else                                  adjusted_value="https://youtube.com/$value"
      fi
      social_links="$social_links [:fontawesome-brands-youtube:{ .ky_social_links_icon }]($adjusted_value){ target='_blank' }"
    # Bilibili
    elif [ "$contact_key" = "bl" ]; then
      if [[ "$value" =~ "https://" ]]; then adjusted_value="$value"
      else                                  adjusted_value="https://space.bilibili.com/$value"
      fi
      social_links="$social_links [:fontawesome-brands-bilibili:{ .ky_social_links_icon }]($adjusted_value){ target='_blank' }"
    # Xiaohongshu
    elif [ "$contact_key" = "rb" ]; then
      if [[ "$value" =~ "https://" ]]; then adjusted_value="$value"
      else                                  adjusted_value="https://xiaohongshu.com/$value"
      fi
      social_links="$social_links [:simple-xiaohongshu:{ .ky_social_links_icon }]($adjusted_value){ target='_blank' }"
    # WeChat Official Account
    elif [ "$contact_key" = "wo" ]; then
      if [[ "$value" =~ "https://" ]]; then adjusted_value="$value"
      else                                  adjusted_value="# \"$value\""
      fi
      social_links="$social_links [:fontawesome-brands-weixin:{ .ky_social_links_icon }]($adjusted_value){ target='_blank' }"
    fi
    # awk -v s="$template_value_key" -v r="${adjusted_value//&/\\\\&}" '{sub(s,r)}1' "$tmp_entity_contact_file" > "$tmp"
    # mv "$tmp" "$tmp_entity_contact_file"
  done

  if [ -n "$social_links" ]; then
    if [ -z "$is_section_available" ]; then
      echo -e "---\n\n$social_links" >> "$tmp_entity_contact_file"
    else
      echo -e "\n---\n\n$social_links" >> "$tmp_entity_contact_file"
    fi
  fi

  if [ -z "$is_section_available" ] && [ -z "$is_section_available" ]; then
    # sed -i '' -e "/$section_key/d" "$tmp_entity_file"
    ky_sed_delete "$tmp_entity_file" "$section_key"
  else
    __replace_section_with_another_file_content "$tmp_entity_file" "$section_key" "$tmp_entity_contact_file"
  fi
  rm "$tmp_entity_contact_file"
}

# MARK: Mapping - Multiline Text Sections
sd_entity_file_composition_map_entity_multiline_sections() {
  local entity_json_file=$1
  local tmp_entity_file=$2
  shift 2
  local keys=("$@")
  ky_func_log_verbose "${FUNCNAME[0]}" ""

  local tmp; tmp=$(mktemp)

  local value multiline_content

  for section_key in "${keys[@]}"; do
    local template_section_start="KY_SECTION_$section_key"
    local template_section_end="$template_section_start END"

    value="$(jq -r ".${section_key}" "$entity_json_file" | sed -e 's/&/\\\\&/g')"

    if [ -z "$value" ] || [ "$value" = null ]; then
      # sed -i '' -e "/$template_section_start/,/$template_section_end/d" "$tmp_entity_file"
      ky_sed_delete "$tmp_entity_file" "$template_section_start/,/$template_section_end"
    else
      # sed -i '' -e "/$template_section_start/d" "$tmp_entity_file"
      # sed -i '' -e "/$template_section_end/d" "$tmp_entity_file"
      ky_sed_delete "$tmp_entity_file" "$template_section_start"
      ky_sed_delete "$tmp_entity_file" "$template_section_end"

      local template_value_key="{KY_VALUE_$section_key}"

      value="${value//\\r\\n/\\n}" # replace "\r\n" with "\n"
      value="${value//\\n/$'\n'}" # replace "\n" with newline
      # value="${value//\\n/  \\n    }" # replace "\n" with "  \n    "
      # multiline_content="$(echo -e "$value")"

      multiline_content=""
      while read -r value_line; do
        multiline_content="${multiline_content}    ${value_line}  \n"
      done < <(echo "$value")
      multiline_content="$(echo -e "$multiline_content")"

      awk '
      BEGIN { s=ARGV[1]; r=ARGV[2]; delete ARGV[1]; delete ARGV[2]; }
      { sub(s,r) }1
      END {}' "$template_value_key" "$multiline_content" "$tmp_entity_file" > "$tmp"
      mv "$tmp" "$tmp_entity_file"
    fi
  done
}

# MARK: _Line Insertion
__insert_line_before_template_anchor() {
  file=$1
  line=$2
  anchor=$3

  local escaped_line
  escaped_line="${line//\//\\/}"        # "/" > "\/"
  escaped_line="${escaped_line//&/\\&}" # "&" > "\&"

  if [ -n "$G_IS_CI" ]; then
    sed -i "s/\($anchor\)/$escaped_line\n\1/g" "$file"
  else
    sed -i '' -e "s/\($anchor\)/$escaped_line\n\1/g" "$file"
  fi
  #sed -i '' -e "s/\($anchor\)/${escaped_line//&/\\&}\n\1/g" "$file"
}

# MARK: _Section Replacement
__replace_section_with_another_file_content() {
  local tmp_entity_file=$1
  local section_key=$2
  local section_tmp_entity_file=$3
  ky_func_log_verbose "${FUNCNAME[0]}" "- $section_key"

  local tmp; tmp=$(mktemp)

  local section_content template_section_key
  section_content="$(<"$section_tmp_entity_file")"
  template_section_key="{KY_SECTION_$section_key}"
  # awk: 
  # - https://www.gnu.org/software/gawk/manual/html_node/Using-BEGIN_002fEND.html
  # - https://www.ibm.com/docs/en/aix/7.2?topic=awk-command
  # The cmd below will fail if $section_content contains newline.
  #   awk -v s="$template_section_key" -v r="$section_content" '{sub(s,r)}1' "$tmp_entity_file" > "$tmp"
  awk '
  BEGIN { s=ARGV[1]; r=ARGV[2]; delete ARGV[1]; delete ARGV[2]; }
  { sub(s,r) }1
  END {}' "$template_section_key" "${section_content//&/\\&}" "$tmp_entity_file" > "$tmp"
  mv "$tmp" "$tmp_entity_file"
}
