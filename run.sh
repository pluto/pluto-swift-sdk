###
#
#  This script works for the most part, however I believe it only works for
#  ios <= 16, due to the latest version of XCode support.  Also, to use this,
#  you will need to brew install ios-deploy.
#
###


#!/bin/bash
#
# Usage: ./run.sh [DEVICE_UDID]
#
#  - If you pass a UDID, it uses that.
#  - Otherwise, it tries to find an iPhone first.
#  - If no iPhone is found, it falls back to the first iOS device.

set -e  # Exit immediately on error

###################################
# Configuration
###################################
SCHEME="PlutoSDKTestApp"
PROJECT_PATH="PlutoSwiftSDK.xcodeproj"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="$(pwd)/Build"

###################################
# Step 1: Determine the UDID
###################################
DEVICE_UDID="$1"

if [ -z "$DEVICE_UDID" ]; then
  echo "No UDID provided on command line. Attempting to auto-detect…"

  # Attempt to find an iPhone first
  IPHONE_UDID=$(xcodebuild -showdestinations \
                  -project "$PROJECT_PATH" \
                  -scheme "$SCHEME" 2>/dev/null \
                | grep "platform:iOS" \
                | grep -i "iPhone" \
                | head -n1 \
                | sed 's/.*id:\([A-F0-9-]*\).*/\1/')

  if [ -n "$IPHONE_UDID" ]; then
    DEVICE_UDID="$IPHONE_UDID"
    echo "Found iPhone with UDID: $DEVICE_UDID"
  else
    # If we can't find an iPhone, fallback to the first iOS device
    FALLBACK_UDID=$(xcodebuild -showdestinations \
                     -project "$PROJECT_PATH" \
                     -scheme "$SCHEME" 2>/dev/null \
                   | grep "platform:iOS" \
                   | head -n1 \
                   | sed 's/.*id:\([A-F0-9-]*\).*/\1/')
    if [ -z "$FALLBACK_UDID" ]; then
      echo "ERROR: Could not find any iOS device."
      exit 1
    else
      DEVICE_UDID="$FALLBACK_UDID"
      echo "No iPhone found. Falling back to first iOS device: $DEVICE_UDID"
    fi
  fi
fi

###################################
# Step 2: Build for the device
###################################
echo "Building '$SCHEME' for device $DEVICE_UDID..."

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "id=$DEVICE_UDID" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  clean build

###################################
# Step 3: Locate the .app
###################################
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION-iphoneos/$SCHEME.app"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: .app not found at $APP_PATH"
  exit 1
fi

###################################
# Step 4: Deploy & launch with ios-deploy
###################################
echo "Installing and launching on device $DEVICE_UDID…"
ios-deploy --bundle "$APP_PATH" --debug
