#!/bin/bash

RESTCONF_BASE_URL='https://localhost:6749/admin/api/restconf/data'
ADMIN_USER='admin'
ADMIN_PASSWORD='Password1'

HTTP_STATUS=$(curl -k -s \
-X PATCH "$RESTCONF_BASE_URL" \
-u "$ADMIN_USER:$ADMIN_PASSWORD" \
-H 'Content-Type: application/yang-data+xml' \
-d @resources/example-config.xml \
-o go.txt -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "Problem encountered updating the configuration: $HTTP_STATUS"
  exit 1
fi