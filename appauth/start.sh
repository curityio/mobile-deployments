#!/bin/bash

##########################################################################
# A script to provide an automated mobile OAuth setup for the code example
##########################################################################

#
# Check for a correct configuration file
#
CONFIG_FILE_PATH=$1
if [ "$CONFIG_FILE_PATH" == "" ]; then
  echo "A configuration file path must be provided as a runtime parameter"
fi
if [ ! -f $CONFIG_FILE_PATH ]; then
  echo "The configuration file path provided does not exist"
  exit 1
fi

#
# Check for a license file
#
if [ ! -f './license.json' ]; then
  echo "A license.json file must be copied into this script's folder"
  exit 1
fi

#
# This is for Curity developers only, to prevent accidental checkins of license files
#
cp ../hooks/pre-commit ./.git/hooks

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
# Update the mobile app's configuration file to set the issuer / authority to the NGROK URL
#
AUTHORITY_URL="$NGROK_URL/oauth/v2/oauth-anonymous"
MOBILE_CONFIG="$(cat $CONFIG_FILE_PATH)"
echo $MOBILE_CONFIG | jq --arg i "$AUTHORITY_URL" '.issuer = $i' > $CONFIG_FILE_PATH

#
# Also output the URL, which can be useful to grab for development purposes
#
DISCOVERY_URL="$AUTHORITY_URL/.well-known/openid-configuration"
echo "Identity Server is running at $DISCOVERY_URL"
