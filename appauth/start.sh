#!/bin/bash

##########################################################################
# A script to provide an automated mobile OAuth setup for the code example
##########################################################################

#
# Change to this folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Check for a license file
#
if [ ! -f './license.json' ]; then
  echo "A license.json file must be copied into this script's folder"
  exit 1
fi

#
# This is for Curity developers only, to prevent accidental checkins of license details
#
if [ -d '../.git/hooks' ]; then
  cp ../hooks/pre-commit ../.git/hooks
fi

#
# Spin up ngrok, to get a trusted SSL internet URL for the Identity Server that mobile apps or simulators can connect to
#
kill -9 $(pgrep ngrok) 2>/dev/null
ngrok http 8443 -log=stdout &
sleep 5
export NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | select(.proto == "https") | .public_url')
if [ "$NGROK_URL" == "" ]; then
  echo "Problem encountered getting an NGROK URL"
  exit 1
fi

#
# Next deploy the Curity Identity server
#
docker compose --project-name appauth up --detach --force-recreate
if [ $? -ne 0 ]; then
  echo "Problem encountered starting Docker components"
  exit 1
fi

#
# Return the authority base URL to the parent script
#
echo "$NGROK_URL/oauth/v2/oauth-anonymous"
