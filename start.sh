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
# Code examples provide these command line parameters:
# - USE_NGROK - a boolean to determine whether the script spins up an ngrok tunnel
# - RUNTIME_BASE_URL - The base URL through which an emulator or device calls the Curity Identity Server if not using NGROK
# - EXAMPLE_NAME - the subfolder from which the mobile configuration is applied, eg 'haapi' or 'appauth'
#
USE_NGROK="$1"
RUNTIME_BASE_URL="$2"
EXAMPLE_NAME="$3"
if [ "$USE_NGROK" == '' ] || [ "$RUNTIME_BASE_URL" == '' ] || [ "$EXAMPLE_NAME" == '' ]; then
  echo 'Incorrect command line arguments supplied to the start.sh script'
  exit 1
fi

#
# Shared logic to spin up an ngrok tunnel to expose the Curity Identity Server using a trusted HTTPS internet URL.
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
  if [[ "$RUNTIME_BASE_URL" == https* ]]; then
    RUNTIME_PROTOCOL="https"
  else
    RUNTIME_PROTOCOL="http"
  fi
fi

#
# Deploy an up to date version of the Curity Identity server
#
export RUNTIME_PROTOCOL
export RUNTIME_BASE_URL
cd resources
docker pull curity.azurecr.io/curity/idsvr
docker compose --project-name $EXAMPLE_NAME down
docker compose --project-name $EXAMPLE_NAME up --detach
if [ $? -ne 0 ]; then
  echo 'Problem encountered starting Docker components'
  exit 1
fi

#
# Wait for Curity Identity Server endpoints to become available
#
echo 'Waiting for the Curity Identity Server ...'
RESTCONF_BASE_URL='https://localhost:6749/admin/api/restconf/data'
ADMIN_USER='admin'
ADMIN_PASSWORD='Password1'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ADMIN_USER:$ADMIN_PASSWORD" "$RESTCONF_BASE_URL?content=config")" != "200" ]; do
  sleep 2
done

#
# If the license allows it, use RESTCONF to activate the DevOps dashboard to enable test user administration.
#
base64url_decode() {
  local len=$((${#1} % 4))
  local result="$1"
  if [ $len -eq 2 ]; then result="$1"'=='
  elif [ $len -eq 3 ]; then result="$1"'=' 
  fi
  echo "$result" | tr '_-' '/+' | base64 --decode
}

LICENSE_DATA=$(cat './license.json')
LICENSE_JWT=$(echo $LICENSE_DATA | jq -r .License)
LICENSE_PAYLOAD=$(base64url_decode $(echo $LICENSE_JWT | cut -d '.' -f 2))
DASHBOARD=$(echo $LICENSE_PAYLOAD | jq -r '.Features[]  | select(.feature == "dashboard")')
if [ "$DASHBOARD" != '' ]; then

  echo 'Activating the DevOps dashboard ...'
  HTTP_STATUS=$(curl -k -s \
    -X PATCH "$RESTCONF_BASE_URL" \
    -u "$ADMIN_USER:$ADMIN_PASSWORD" \
    -H 'Content-Type: application/yang-data+xml' \
    -d @devops-dashboard.xml \
    -o /dev/null -w '%{http_code}')
  if [ "$HTTP_STATUS" != '204' ]; then
    echo "Problem encountered applying the DevOps Dashboard configuration: $HTTP_STATUS"
    exit 1
  fi
fi

#
# For the HAAPI example, update configuration dynamically based on additional environment variables 
#
cd ../$EXAMPLE_NAME
if [ "$EXAMPLE_NAME" == 'haapi' ]; then
  ./configure.sh
  if [ $? -ne 0 ]; then
    echo 'Problem encountered updating HAAPI configuration'
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
  echo "Problem encountered applying the code example configuration: $HTTP_STATUS"
  exit 1
fi

#
# Return the final runtime base URL to the parent script
#
cd ..
echo "$RUNTIME_BASE_URL">./output.txt
