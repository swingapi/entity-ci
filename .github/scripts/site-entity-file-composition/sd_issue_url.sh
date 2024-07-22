#!/bin/bash

# MARK: Add/Update Org

sd_issue_url_to_add_org() {
  local region=$1
  local province=$2
  local city=$3

  local url="https://github.com/swingdance/orgs/issues/new?assignees=&labels=add+org&projects=&template=02-add_entity.yml"
  # url+="&title=Add+Org%3A+${region}+•+%3CName%3E&region=${region}"
  url+="$(__query_field "title" "[${region}] <Name>")"
  url+="$(__query_field "region" "$region")"
  url+="$(__query_field "province" "$province")"
  url+="$(__query_field "city" "$city")"
  echo "$url"
}

sd_issue_url_to_update_org() {
  local region=$1
  local org_id=$2
  local name=$3

  local url="https://github.com/swingdance/orgs/issues/new?assignees=&labels=update+org&projects=&template=03-update_entity.yml"
  url+="$(__query_field "title" "[${region}] ${name}")"
  url+="$(__query_field "region" "$region")"
  url+="$(__query_field "id" "$org_id")"
  url+="$(__query_field "name" "$name")"
  echo "$url"
}

# MARK: Add/Update Event

sd_issue_url_to_add_event() {
  local region=$1
  local province=$2
  local city=$3
  local year=$4
  local month=$5
  local org_id=$6

  local url="https://github.com/swingdance/events/issues/new?assignees=&labels=add+event&projects=&template=02-add_entity.yml"
  if [ -n "$year" ]; then
    url+="$(__query_field "title" "[${year}/${region}] <Name>")"
  else
    url+="$(__query_field "title" "[${region}] <Name>")"
  fi
  url+="$(__query_field "region" "$region")"
  url+="$(__query_field "province" "$province")"
  url+="$(__query_field "city" "$city")"
  url+="$(__query_field "org_id" "$org_id")"

  if [ -n "$year" ]; then
    local date_text
    if [ -n "$month" ]; then
      date_text="$year-$month-" # $(printf "%02d" "$month")
    else
      date_text="$year-"
    fi
    url+="$(__query_field "date_starts" "$date_text")"
    url+="$(__query_field "date_ends" "$date_text")"
  fi
  echo "$url"
}

sd_issue_url_to_update_event() {
  local year=$1
  local region=$2
  local event_id=$3
  local org_id=$4
  local name=$5

  local url="https://github.com/swingdance/events/issues/new?assignees=&labels=update+event&projects=&template=03-update_entity.yml"
  url+="$(__query_field "title" "[${year}/${region}] ${name}")"
  url+="$(__query_field "region" "$region")"
  url+="$(__query_field "year" "$year")"
  url+="$(__query_field "id" "$event_id")"
  url+="$(__query_field "name" "$name")"
  url+="$(__query_field "org_id" "$org_id")"
  echo "$url"
}

# MARK: Private

__query_field() {
  key=$1
  value=$2
  # REF: https://stackoverflow.com/a/34407620/904365
  encoded_value="$(jq -rn --arg x "$value" '$x|@uri')"
  echo "&${key}=${encoded_value}"
}
