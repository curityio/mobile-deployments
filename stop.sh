#!/bin/bash

###############################################################
# Free mobile OAuth setup resources for the mobile code example
###############################################################

#
# Change to this folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"
EXAMPLE_NAME="$1"

#
# Check for valid input
#
if [ "$EXAMPLE_NAME" == '' ]; then
  echo 'Incorrect command line arguments supplied to the start.sh script'
  exit 1
fi

#
# Stop ngrok
#
kill -9 $(pgrep ngrok) 2>/dev/null

#
# Stop Docker resources and set these Docker compose variables to prevent warnings
#
export RUNTIME_PROTOCOL='' 
export RUNTIME_BASE_URL=''
docker compose --project-name $EXAMPLE_NAME down
