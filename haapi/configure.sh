#!/bin/bash

############################################################
# Configure HAAPI parameters that vary between code examples
############################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# The UI SDK code examples and the React Native code example provide these parameters explicitly
# The following defaulting of parameters is only used by older HAAPI model SDK code examples
# - https://github.com/curityio/android-haapi-demo-app
# - https://github.com/curityio/ios-haapi-demo-app
#
if [ "$ANDROID_PACKAGE_NAME" == '' ]; then
    ANDROID_PACKAGE_NAME='io.curity.haapidemo'
  fi
  if [ "$ANDROID_FINGERPRINT" == '' ]; then
    ANDROID_FINGERPRINT='67:60:CA:11:93:B6:5D:61:56:42:70:29:A1:10:B3:86:A8:48:C7:33:83:7B:B0:54:B0:0A:E3:E1:4A:7D:A0:A4'
  fi
  if [ "$ANDROID_SIGNATURE_DIGEST" == '' ]; then
    ANDROID_SIGNATURE_DIGEST='Z2DKEZO2XWFWQnApoRCzhqhIxzODe7BUsArj4Up9oKQ='
  fi
  if [ "$APPLE_BUNDLE_ID" == '' ]; then
    APPLE_BUNDLE_ID='io.curity.haapidemo'
  fi
  if [ "$APPLE_TEAM_ID" == '' ]; then
    APPLE_TEAM_ID='MYTEAMID'
  fi
fi

#
# All HAAPI examples use a shared configuration to avoid duplication, since there are many configuration settings
#
envsubst < example-config-template.xml > example-config.xml
if [ $? -ne 0 ]; then
  echo 'Problem encountered using envsubst to update example configuration'
  exit 1
fi
