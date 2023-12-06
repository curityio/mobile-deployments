#!/bin/bash

#########################################################################
# A script to teardown an automated OAuth setup for a mobile code example
#########################################################################

#
# Change to this folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Check for valid input
#
if [ "$EXAMPLE_NAME" == '' ]; then
  echo 'An EXAMPLE_NAME environment variable must be supplied to the stop.sh script'
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
