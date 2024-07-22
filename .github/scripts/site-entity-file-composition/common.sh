#!/bin/bash

ky_get_lang_folder_name() {
  local lang=$1
  [ "$lang" = "default" ] && echo "en" || echo "$lang"
}

ky_sed_replace() {
  local INPUT_FILE=$1
  local INPUT_PATTERN=$2
  local INPUT_VALUE=$3

  if [ -n "$G_IS_CI" ]; then
    sed -i "s/$INPUT_PATTERN/$INPUT_VALUE/g" "$INPUT_FILE"
  else
    sed -i '' -e "s/$INPUT_PATTERN/$INPUT_VALUE/g" "$INPUT_FILE"
  fi
}

ky_sed_delete() {
  local INPUT_FILE=$1
  local INPUT_PATTERN=$2

  if [ -n "$G_IS_CI" ]; then
    sed -i "/$INPUT_PATTERN/d" "$INPUT_FILE"
  else
    sed -i '' -e "/$INPUT_PATTERN/d" "$INPUT_FILE"
  fi
}
