#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "::error:: The entity type is required."
  exit 1
elif [ -z "$2" ]; then
  echo "::error:: A filename is required."
  exit 1
fi
ENTITY_TYPE=$1
INPUT_FILE=$2
LOCAL_DEBUG=$3

# shellcheck source=/dev/null
source "$(dirname "$0")/shared/constants.sh"
# shellcheck source=/dev/null
source "$(dirname "$0")/shared/common.sh"
# shellcheck source=/dev/null
source "$(dirname "$0")/shared/update_entity.sh"
# shellcheck source=/dev/null
source "$(dirname "$0")/shared/get_entity_essential_data.sh"

# Get entity essential data.

read -r entity_essential_data <<< "$(ky_get_entity_essential_data "$ENTITY_TYPE" "$INPUT_FILE" "$LOCAL_DEBUG")"
IFS=$'\n' read -rd '' -a entity_essential_data_values <<< "${entity_essential_data//$KY_STRING_DELIMITER/$'\n'}" || 'true'

YEAR=${entity_essential_data_values[0]} # For event type only
CODE=${entity_essential_data_values[1]}
ENTITY_ID=${entity_essential_data_values[2]}
ENTITY_FILE=${entity_essential_data_values[3]}
TEMPLATE_FILE=${entity_essential_data_values[4]}
error_msg=${entity_essential_data_values[5]}

echo
echo "### Entity Essential Data:"
echo "- YEAR: $YEAR"
echo "- CODE: $CODE"
echo "- ENTITY_ID: $ENTITY_ID"
echo "- ENTITY_FILE: $ENTITY_FILE"
echo "- TEMPLATE_FILE: $TEMPLATE_FILE"
# echo "- error_msg: $error_msg"

# Verify Entity
if [ "$ENTITY_TYPE" = "event" ] && [ -z "$YEAR" ]; then
  error_msg="Invalid entity essential data - YEAR: $YEAR"
elif [ -z "$CODE" ] || [ -z "$ENTITY_ID" ] || [ -z "$ENTITY_FILE" ] || [ -z "$TEMPLATE_FILE" ]; then
  error_msg="Invalid entity essential data."
fi

# Make sure the entity file exists.
if [ -z "$error_msg" ] && [ ! -e "$ENTITY_FILE" ]; then
  error_msg="File Not Found: $ENTITY_FILE."
fi

if [ "$error_msg" != "" ]; then
  echo
  if [ -n "$LOCAL_DEBUG" ]; then
    echo "error=$error_msg"
  else
    echo "error=$error_msg" >> "$GITHUB_OUTPUT"
  fi
  exit 1
fi

# Update input file: convert values from array to string.
if [ "$ENTITY_TYPE" = "org" ]; then
  ky_update_file_to_convert_value_from_array_to_string "$INPUT_FILE" "${KY_ORG_ARRAY_KEYS[@]}"
elif [ "$ENTITY_TYPE" = "event" ]; then
  ky_update_file_to_convert_value_from_array_to_string "$INPUT_FILE" "${KY_EVENT_ARRAY_KEYS[@]}"
fi

# Prepare edit file to update entity.
EDIT_FILE=$(ky_prepare_edit_file_to_update_entity "$TEMPLATE_FILE" "$ENTITY_FILE")

# Update the edit file with the info from the input file.
ky_update_file_with_modified_data "$EDIT_FILE" "$INPUT_FILE"

# Delete all empty key-value pairs.
ky_update_file_to_delete_all_empty_key_value_pairs "$EDIT_FILE"

# Save and sort entity file.

if [ -n "$LOCAL_DEBUG" ]; then
  echo
  echo "### LOCAL DEBUG - Backup the original file ($ENTITY_FILE)."
  if [ "$ENTITY_TYPE" = "event" ]; then
    cp -v "$ENTITY_FILE" "$YEAR/$CODE/_$ENTITY_ID.json"
  else
    cp -v "$ENTITY_FILE" "$CODE/_$ENTITY_ID.json"
  fi
fi

original_file_preview_content=$(cat "$ENTITY_FILE")
updated_file_preview_content=$(cat "$EDIT_FILE")

echo
echo "### Save the edited file ($EDIT_FILE)."
mv -v "$EDIT_FILE" "$ENTITY_FILE"

echo "### Sort the entity file ($ENTITY_FILE)."
# shellcheck source=/dev/null
source "$(dirname "$0")/shared/sort_json_file.sh"
ky_sort_json_file "$ENTITY_FILE"

# Clean up.

if [ -z "$LOCAL_DEBUG" ]; then
  echo
  echo "### DELETE the input file $INPUT_FILE."
  rm "$INPUT_FILE"
fi

echo
echo "### DONE ###"
echo

# echo
# echo "Remove temp folder: $TEMP_FOLDER"
# rm -rfv $TEMP_FOLDER

# File Preview.

echo "Original File Preview: $original_file_preview_content"
echo "Updated File Preview: $updated_file_preview_content"

if [ -z "$LOCAL_DEBUG" ]; then
  echo "file_path=$ENTITY_FILE" >> "$GITHUB_OUTPUT"

  EOF=$(dd if=/dev/urandom bs=15 count=1 status=none | base64)
  {
    echo "original_file_preview<<$EOF"
    echo "$original_file_preview_content"
    echo "$EOF"
  } >> "$GITHUB_OUTPUT"

  {
    echo "updated_file_preview<<$EOF"
    echo "$updated_file_preview_content"
    echo "$EOF"
  } >> "$GITHUB_OUTPUT"
fi
