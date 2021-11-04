#!/bin/bash

###############################################################
# Free mobile OAuth setup resources for the mobile code example
###############################################################

#
# Change to this folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"
USE_NGROK="$1"
EXAMPLE_NAME="$2"

#
# Check for valid input
#
if [ "$USE_NGROK" == '' ] || [ "$EXAMPLE_NAME" == '' ]; then
  echo 'Incorrect command line arguments supplied to the stop.sh script'
  exit 1
fi

#
# Stop ngrok if required
#
if [ "$USE_NGROK" == 'true' ]; then
  kill -9 $(pgrep ngrok) 2>/dev/null
fi

#
# Stop Docker resources and set these Docker compose variables to prevent warnings
#
export RUNTIME_PROTOCOL='' 
export RUNTIME_BASE_URL=''
docker compose --project-name $EXAMPLE_NAME down
