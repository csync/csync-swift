#!/bin/bash

# Determine version number
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" CSyncSDK/Info.plist)

jazzy \
  --clean \
  --author IBM \
  --author_url https://www.ibm.com \
  --module CSyncSDK \
  --module-version $version \
  --swift-version 2.2 \
  --readme README.md \
  --output docs
