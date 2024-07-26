#!/bin/bash

# MARK: _LANG/REGION/ENTITY.ics

sd_compose_entity_ics_file() {
  local INPUT_LANG=$1
  local INPUT_YEAR=$2
  local INPUT_REGION=$3
  local INPUT_ENTITY_ID=$4
  local INPUT_ENTITY_FILE=$5
  local INPUT_ENTITY_JSON_FILE=$6

  ky_func_log_verbose "${FUNCNAME[0]}" "- * $INPUT_ENTITY_FILE"

  # UID
  local event_uid_lang
  [ "$INPUT_LANG" != "default" ] && event_uid_lang="${INPUT_LANG}_"
  local event_uid="swing-news_${event_uid_lang}${INPUT_REGION}_${INPUT_ENTITY_ID}"

  # URL
  local event_url="https://swing.news"
  if [ "$INPUT_LANG" != "default" ]; then
    event_url+="/$INPUT_LANG"
  fi
  event_url+="/$INPUT_REGION/$INPUT_ENTITY_ID"

  # Location
  local city localized_city
  city="$(jq -r '.city' "$INPUT_ENTITY_JSON_FILE")"
  localized_city="$(sd_localization_get_localized_city "$INPUT_LANG" "$INPUT_REGION" "$city")"

  # Timezone
  # Refer to https://www.tzurl.org
  # local tzid="Asia/Shanghai"
  # local tzhr="+0800"

  # Date
  local date_starts date_ends
  date_starts="$(jq -r '.date_starts' "$INPUT_ENTITY_JSON_FILE")"
  date_ends="$(jq -r '.date_ends' "$INPUT_ENTITY_JSON_FILE")"
  # - Plus 1 day to the date ends.
  if [ -n "$G_IS_CI" ]; then
    date_ends="$(date -d "$date_ends +1 days" +"%Y-%m-%d")"
  else
    date_ends="$(date -j -f "%Y-%m-%d" -v+1d "$date_ends" "+%Y%m%d")"
  fi

  # Summary
  local name name_local
  name="$(jq -r '.name' "$INPUT_ENTITY_JSON_FILE")"
  name_local="$(jq -r '.name_local' "$INPUT_ENTITY_JSON_FILE")"
  name_abb="$(jq -r '.abb' "$INPUT_ENTITY_JSON_FILE")"

  local event_summary=""
  [ -n "$name_abb" ] && [ "$name_abb" != null ] && event_summary+="[$name_abb $INPUT_YEAR] "
  event_summary+="$name"
  [ -n "$name_local" ] && [ "$name_local" != null ] && event_summary+=" • $name_local"

  {
    #
    # Refer to https://ical.marudot.com
    #
    echo "BEGIN:VCALENDAR"
    # echo "VERSION:2.0"
    # echo "PRODID:-//tzurl.org//NONSGML Olson 2024a//EN"
    echo "CALSCALE:GREGORIAN"

    # - TimeZone
    # echo "BEGIN:VTIMEZONE"
    # echo "TZID:$tzid"
    # echo "LAST-MODIFIED:20240713T235959Z"
    # echo "TZURL:https://www.tzurl.org/zoneinfo/$tzid"
    # echo "X-LIC-LOCATION:$tzid"
    # echo "BEGIN:STANDARD"
    # echo "TZNAME:CST"
    # echo "TZOFFSETFROM:$tzhr"
    # echo "TZOFFSETTO:$tzhr"
    # echo "DTSTART:19700101T000000"
    # echo "END:STANDARD"
    # echo "END:VTIMEZONE"

    # - Event
    echo "BEGIN:VEVENT"
    # echo "DTSTAMP:20240713T235959Z"
    echo "UID:$event_uid"
    echo "DTSTART;VALUE=DATE:${date_starts//-/}"
    echo "DTEND;VALUE=DATE:${date_ends//-/}"
    echo "SUMMARY:$event_summary"
    echo "URL:$event_url"
    # echo "DESCRIPTION:xxx\nxxx"
    echo "LOCATION:$localized_city"
    echo "END:VEVENT"
    echo "END:VCALENDAR"

  } >> "$INPUT_ENTITY_FILE"
}
