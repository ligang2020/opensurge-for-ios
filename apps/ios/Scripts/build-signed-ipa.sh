#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PROJECT="$ROOT/apps/ios/OpenSurgeMobile.xcodeproj"
SCHEME="OpenSurgeMobile"
CONFIGURATION="${OPENSURGE_IOS_CONFIGURATION:-Release}"
VERSION="${OPENSURGE_VERSION:-0.1.0}"
BUILD_NUMBER="${OPENSURGE_BUILD_NUMBER:-1}"
ARTIFACT_DIR="${OPENSURGE_IOS_ARTIFACT_DIR:-$ROOT/artifacts/ios}"
ARCHIVE_PATH="$ARTIFACT_DIR/OpenSurgeMobile.xcarchive"
EXPORT_PATH="$ARTIFACT_DIR/signed-export"
EXPORT_OPTIONS="$ARTIFACT_DIR/ExportOptions.plist"
TEAM_ID="${IOS_DEVELOPMENT_TEAM:?IOS_DEVELOPMENT_TEAM is required}"
BUNDLE_ID="${IOS_BUNDLE_IDENTIFIER:-com.opensurge.mobile}"
PROFILE_SPECIFIER="${IOS_PROVISIONING_PROFILE_SPECIFIER:?IOS_PROVISIONING_PROFILE_SPECIFIER is required}"
EXPORT_METHOD="${IOS_EXPORT_METHOD:-ad-hoc}"
CODE_SIGN_IDENTITY="${IOS_CODE_SIGN_IDENTITY:-Apple Distribution}"

if ! command -v xcodebuild >/dev/null 2>&1 || ! xcodebuild -version >/dev/null 2>&1; then
  echo "Full Xcode is required to build an iOS IPA. Install Xcode and run sudo xcode-select -s /Applications/Xcode.app/Contents/Developer." >&2
  exit 1
fi

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p "$ARTIFACT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  PROVISIONING_PROFILE_SPECIFIER="$PROFILE_SPECIFIER" \
  CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
  clean archive

cat >"$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>compileBitcode</key>
  <false/>
  <key>method</key>
  <string>$EXPORT_METHOD</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>$BUNDLE_ID</key>
    <string>$PROFILE_SPECIFIER</string>
  </dict>
  <key>signingCertificate</key>
  <string>$CODE_SIGN_IDENTITY</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>$TEAM_ID</string>
</dict>
</plist>
EOF

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

IPA="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print -quit)"
[[ -n "$IPA" && -f "$IPA" ]] || { echo "Signed IPA was not produced in $EXPORT_PATH" >&2; exit 1; }
FINAL_IPA="$ARTIFACT_DIR/OpenSurge-Mobile-$VERSION-signed.ipa"
mv "$IPA" "$FINAL_IPA"
echo "$FINAL_IPA"
