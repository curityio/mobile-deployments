#!/bin/bash

##########################################################################
# A script to provide an automated OAuth setup for the mobile code example
##########################################################################

#
# Change to this folder and accept input
#
cd "$(dirname "${BASH_SOURCE[0]}")"
USE_NGROK="$1"
BASE_URL="$2"
EXAMPLE_NAME="$3"

#
# Check for valid input
#
if [ "$USE_NGROK" == '' ] || [ "$BASE_URL" == '' ] || [ "$EXAMPLE_NAME" == '' ]; then
  echo 'Incorrect command line arguments supplied to the start.sh script'
  exit 1
fi

#
# Check for a license file
#
if [ ! -f './resources/license.json' ]; then
  echo 'A license.json file must be provided in the resources folder'
  exit 1
fi

#
# This is for Curity developers only, to prevent accidental checkins of license details
#
if [ -d '.git/hooks' ]; then
  cp ./hooks/pre-commit ./.git/hooks
fi

#
# Spin up ngrok, to get a trusted SSL internet URL for the Identity Server that mobile apps or simulators can connect to
#
if [ "$USE_NGROK" == 'true' ]; then
  kill -9 $(pgrep ngrok) 2>/dev/null
  ngrok http 8443 --log=stdout &
  sleep 5
  export RUNTIME_BASE_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | select(.proto == "https") | .public_url')
  export RUNTIME_PROTOCOL="http"
  if [ "$RUNTIME_BASE_URL" == "" ]; then
    echo 'Problem encountered getting an NGROK URL'
    exit 1
  fi
else
  export RUNTIME_BASE_URL="$BASE_URL"
  if [[ "$BASE_URL" == https* ]]; then
    export RUNTIME_PROTOCOL="https"
  else
    export RUNTIME_PROTOCOL="http"
  fi
fi

#
# Set up sample specific configuration
#
cp $EXAMPLE_NAME/example-config.xml resources/
cd resources

#
# Next deploy the Curity Identity server
#
docker compose --project-name $EXAMPLE_NAME up --detach --force-recreate
if [ $? -ne 0 ]; then
  echo 'Problem encountered starting Docker components'
  exit 1
fi

#
# Wait for the Identity Server to become available
#
echo 'Waiting for the Curity Identity Server ...'
RESTCONF_BASE_URL='https://localhost:6749/admin/api/restconf/data'
ADMIN_USER='admin'
ADMIN_PASSWORD='Password1'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ADMIN_USER:$ADMIN_PASSWORD" "$RESTCONF_BASE_URL?content=config")" != "200" ]; do
  sleep 2
done

#
# Apply the code example's configuration via a RESTCONF PATCH
#
echo 'Applying code example configuration ...'
HTTP_STATUS=$(curl -k -s \
-X PATCH "$RESTCONF_BASE_URL" \
-u "$ADMIN_USER:$ADMIN_PASSWORD" \
-H 'Content-Type: application/yang-data+xml' \
-d @example-config.xml \
-o /dev/null -w '%{http_code}')
if [ "$HTTP_STATUS" != '204' ]; then
  echo "Problem encountered updating the configuration: $HTTP_STATUS"
  exit 1
fi

#
# Return the base URL to the parent script
#
cd ..
echo "$RUNTIME_BASE_URL">./output.txt
exit 0
