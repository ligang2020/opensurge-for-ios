#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PROJECT="$ROOT/apps/ios/OpenSurgeMobile.xcodeproj"
SCHEME="OpenSurgeMobile"
CONFIGURATION="${OPENSURGE_IOS_CONFIGURATION:-Release}"
VERSION="${OPENSURGE_VERSION:-0.1.0}"
BUILD_NUMBER="${OPENSURGE_BUILD_NUMBER:-1}"
ARTIFACT_DIR="${OPENSURGE_IOS_ARTIFACT_DIR:-$ROOT/artifacts/ios}"
DERIVED_DATA="${OPENSURGE_IOS_DERIVED_DATA:-$ARTIFACT_DIR/DerivedData}"
IPA="$ARTIFACT_DIR/OpenSurge-Mobile-$VERSION-unsigned.ipa"

if ! command -v xcodebuild >/dev/null 2>&1 || ! xcodebuild -version >/dev/null 2>&1; then
  echo "Full Xcode is required to build an iOS IPA. Install Xcode and run sudo xcode-select -s /Applications/Xcode.app/Contents/Developer." >&2
  exit 1
fi

rm -rf "$DERIVED_DATA" "$ARTIFACT_DIR/Payload"
mkdir -p "$ARTIFACT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  clean build >&2

APP="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphoneos/$SCHEME.app"
[[ -d "$APP" ]] || { echo "iOS app bundle was not produced at $APP" >&2; exit 1; }

mkdir -p "$ARTIFACT_DIR/Payload"
cp -R "$APP" "$ARTIFACT_DIR/Payload/"
rm -f "$IPA"
(cd "$ARTIFACT_DIR" && /usr/bin/zip -qry "$(basename "$IPA")" Payload)
rm -rf "$ARTIFACT_DIR/Payload"

echo "$IPA"
