#!/bin/bash

ky_prepare_edit_file_to_create_entity() {
  local INPUT_FILE=$1
  local LOCAL_DEBUG=$2

  echo >&2
  echo "### Prepare an edit file to create entity." >&2
  if [ -n "$LOCAL_DEBUG" ]; then
    local temp_edit_file="$INPUT_FILE~"
    cp -v "$INPUT_FILE" "$temp_edit_file" >&2
  else
    local temp_edit_file="$INPUT_FILE"
  fi

  echo "$temp_edit_file"
}
