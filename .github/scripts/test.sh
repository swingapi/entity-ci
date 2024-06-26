#!/bin/bash

set -e
echo

# shellcheck source=/dev/null
source "$(dirname "$0")/shared/get_entity_essential_data.sh"
test_get_entity_essential_data_sh

echo
echo "### Tests Succeeded ###"
echo
