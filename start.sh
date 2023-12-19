#!/bin/bash

########################################################################
# A script to provide an automated OAuth setup for a mobile code example
########################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

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
# The example name determines which RESTCONF PATCH is applied
# AppAuth examples work with a community edition license file
# HAAPI examples require a paid license file
#
USE_NGROK="$1"
BASE_URL="$2"
EXAMPLE_NAME="$3"
if [ "$EXAMPLE_NAME" == '' ] || [ "$BASE_URL" == '' ]; then
  echo 'Incorrect command line arguments supplied to the start.sh script'
  exit 1
fi

#
# If required, get a trusted SSL internet URL that mobile apps or simulators can connect to
# This enables mobile associated domain files to be hosted
#
if [ "$USE_NGROK" == 'true' ]; then

  if [ "$(pgrep ngrok)" == '' ]; then
    ngrok http 8443 --log=stdout &
    sleep 5
  fi

  RUNTIME_BASE_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | select(.proto == "https") | .public_url')
  RUNTIME_PROTOCOL="http"
  if [ "$RUNTIME_BASE_URL" == "" ]; then
    echo 'Problem encountered getting an NGROK URL'
    exit 1
  fi
else
  RUNTIME_BASE_URL="$BASE_URL"
  if [[ "$BASE_URL" == https* ]]; then
    RUNTIME_PROTOCOL="https"
  else
    RUNTIME_PROTOCOL="http"
  fi
fi

#
# Deploy the Curity Identity server
#
export RUNTIME_PROTOCOL
export RUNTIME_BASE_URL
cd resources

# Ensure the latest Curity Identity Server image is used
docker pull curity.azurecr.io/curity/idsvr

docker compose --project-name $EXAMPLE_NAME down
docker compose --project-name $EXAMPLE_NAME up --detach
if [ $? -ne 0 ]; then
  echo 'Problem encountered starting Docker components'
  exit 1
fi

#
# Wait for endpoints to become available
#
echo 'Waiting for the Curity Identity Server ...'
RESTCONF_BASE_URL='https://localhost:6749/admin/api/restconf/data'
ADMIN_USER='admin'
ADMIN_PASSWORD='Password1'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ADMIN_USER:$ADMIN_PASSWORD" "$RESTCONF_BASE_URL?content=config")" != "200" ]; do
  sleep 2
done

#
# For the HAAPI example, update configuration dynamically
#
cd ../$EXAMPLE_NAME
if [ "$EXAMPLE_NAME" == 'haapi' ]; then

  if [ "$ANDROID_FINGERPRINT" == '' ]; then
    ANDROID_FINGERPRINT='67:60:CA:11:93:B6:5D:61:56:42:70:29:A1:10:B3:86:A8:48:C7:33:83:7B:B0:54:B0:0A:E3:E1:4A:7D:A0:A4'
  fi
  if [ "$ANDROID_SIGNATURE_DIGEST" == '' ]; then
    ANDROID_SIGNATURE_DIGEST='Z2DKEZO2XWFWQnApoRCzhqhIxzODe7BUsArj4Up9oKQ='
  fi
  if [ "$APPLE_APP_ID" == '' ]; then
    APPLE_APP_ID='io.curity.cat.ios.client'
  fi
  if [ "$APPLE_TEAM_ID" == '' ]; then
    APPLE_TEAM_ID='MYTEAMID'
  fi

  export APPLE_APP_ID
  export APPLE_TEAM_ID
  export ANDROID_FINGERPRINT
  export ANDROID_SIGNATURE_DIGEST
  envsubst < example-config-template.xml > example-config.xml
  if [ $? -ne 0 ]; then
    echo 'Problem encountered using envsubst to update example configuration'
    exit 1
  fi
fi

#
# Apply the code example's specific configuration via a RESTCONF PATCH
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
