#!/bin/bash
# Script to automatically increment version for Android & iOS (by date and build count per day, using dot for iOS/UI)
set -e

# Get version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
DATE=$(date +%Y%m%d)
BUILD_FILE=.build_number

# Read build count for the day
if [ -f "$BUILD_FILE" ]; then
	read LAST_DATE LAST_NUM <"$BUILD_FILE"
	if [ "$LAST_DATE" = "$DATE" ]; then
		BUILD_NUM=$((LAST_NUM + 1))
	else
		BUILD_NUM=1
	fi
else
	BUILD_NUM=1
fi

# Save the latest build count
printf "%s %02d" "$DATE" "$BUILD_NUM" >"$BUILD_FILE"

# Create versionCode/buildNumber: YYYYMMDDNN (Android: number, iOS: date.build)
BUILD_NUMBER_ANDROID="${DATE}$(printf '%02d' $BUILD_NUM)"
BUILD_NUMBER_IOS="${DATE}.$(printf '%02d' $BUILD_NUM)"

# --- Android ---
APP_BUILD_GRADLE=android/app/build.gradle.kts
if [ -f "$APP_BUILD_GRADLE" ]; then
	sed -i '' "s/versionName = .*/versionName = \"$VERSION\"/" $APP_BUILD_GRADLE
	sed -i '' "s/versionCode = .*/versionCode = $BUILD_NUMBER_ANDROID/" $APP_BUILD_GRADLE
	echo "[Android] Updated versionName=$VERSION, versionCode=$BUILD_NUMBER_ANDROID"
fi

# --- iOS ---
for FLAVOR in dev staging; do
	PLIST=ios/Runner/$FLAVOR/Info.plist
	if [ -f "$PLIST" ]; then
		/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST" ||
			/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$PLIST"
		/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER_IOS" "$PLIST" ||
			/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER_IOS" "$PLIST"
		echo "[iOS][$FLAVOR] Updated CFBundleShortVersionString=$VERSION, CFBundleVersion=$BUILD_NUMBER_IOS"
	fi
done
