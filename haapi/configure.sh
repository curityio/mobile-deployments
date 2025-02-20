#!/bin/bash

############################################################
# Configure HAAPI parameters that vary between code examples
############################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# The settings file in the haapi/example-config-template.xml file are only used by the model SDK examples
# - https://github.com/curityio/android-haapi-demo-app
# - https://github.com/curityio/ios-haapi-demo-app
#

#
# The UI SDK and React Native examples copy in their own version of the haapi/example-config-template.xml file
# This allows each HAAPI code example to control its own deployment settings
#

#
# Produce the final HAAPI configuration for the deployment
#
envsubst < example-config-template.xml > example-config.xml
if [ $? -ne 0 ]; then
  echo 'Problem encountered using envsubst to update example configuration'
  exit 1
fi
