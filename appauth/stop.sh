#!/bin/bash

########################################################
# Free mobile OAuth setup resources for the code example
########################################################

#
# Change to this folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Stop ngrok
#
kill -9 $(pgrep ngrok) 2>/dev/null

#
# Stop Docker resources
#
docker compose --project-name appauth down --detach --force-recreate
