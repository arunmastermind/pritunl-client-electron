#!/bin/bash
set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"
cd ../

rm -rf build

export APP_VER="$(cat client/package.json | grep version | cut -d '"' -f 4)"

# Service
cd service
go get
go build -v
cd ..
mkdir -p build/resources
cp service/service build/resources/pritunl-service
codesign --force --timestamp --options=runtime -s "Developer ID Application: Pritunl, Inc. (U22BLATN63)" build/resources/pritunl-service

# CLI
cd cli
go get
go build -v
cd ..
mkdir -p build/resources
cp cli/cli build/resources/pritunl-client
codesign --force --timestamp --options=runtime -s "Developer ID Application: Pritunl, Inc. (U22BLATN63)" build/resources/pritunl-client

# Openvpn
cp openvpn_macos/openvpn_arm64 build/resources/pritunl-openvpn
codesign --force --timestamp --options=runtime -s "Developer ID Application: Pritunl, Inc. (U22BLATN63)" build/resources/pritunl-openvpn


# Pritunl
mkdir -p build/macos/Applications
cd client
npm install
./node_modules/.bin/electron-rebuild
./node_modules/.bin/electron-packager ./ Pritunl \
  --platform=darwin \
  --arch=arm64 \
  --icon=./www/img/pritunl.icns \
  --darwinDarkModeSupport=true \
  --extra-resource="../build/resources/pritunl-service" \
  --extra-resource="../build/resources/pritunl-client" \
  --extra-resource="../build/resources/pritunl-openvpn" \
  --osx-sign.hardenedRuntime \
  --osx-sign.hardened-runtime \
  --no-osx-sign.gatekeeper-assess \
  --osx-sign.entitlements="/Users/apple/go/src/github.com/pritunl/pritunl-client-electron/resources_macos/entitlements.plist" \
  --osx-sign.entitlements-inherit="/Users/apple/go/src/github.com/pritunl/pritunl-client-electron/resources_macos/entitlements.plist" \
  --osx-sign.entitlementsInherit="/Users/apple/go/src/github.com/pritunl/pritunl-client-electron/resources_macos/entitlements.plist" \
  --osx-sign.identity="Developer ID Application: Pritunl, Inc. (U22BLATN63)" \
  --osx-notarize.appleId="contact@pritunl.com" \
  --osx-notarize.appleIdPassword="@keychain:xcode" \
  --out=../build/macos/Applications

cd ../
mv build/macos/Applications/Pritunl-darwin-arm64/Pritunl.app build/macos/Applications/
rm -rf build/macos/Applications/Pritunl-darwin-arm64
sleep 3
#codesign --force --deep --timestamp --options=runtime --entitlements="./resources_macos/entitlements.plist" --sign "Developer ID Application: Pritunl, Inc. (U22BLATN63)" build/macos/Applications/Pritunl.app/Contents/MacOS/Pritunl

# Files
mkdir -p build/macos/var/run
touch build/macos/var/run/pritunl_auth
mkdir -p build/macos/var/log
touch build/macos/var/log/pritunl-client.log
touch build/macos/var/log/pritunl-client.log.1

# Service Daemon
mkdir -p build/macos/Library/LaunchDaemons
cp service_macos/com.pritunl.service.plist build/macos/Library/LaunchDaemons

# Package
chmod +x resources_macos/scripts/postinstall
chmod +x resources_macos/scripts/preinstall
cd build
pkgbuild --root macos --scripts ../resources_macos/scripts --sign "Developer ID Installer: Pritunl, Inc. (U22BLATN63)" --identifier com.pritunl.pkg.Pritunl --version $APP_VER --ownership recommended --install-location / Build.pkg
productbuild --resources ../resources_macos --distribution ../resources_macos/distribution_arm64.xml --sign "Developer ID Installer: Pritunl, Inc. (U22BLATN63)" --version $APP_VER Pritunl.arm64.pkg
zip Pritunl.arm64.pkg.zip Pritunl.arm64.pkg
rm -f Build.pkg

# Notarize
xcrun altool --notarize-app --primary-bundle-id "com.pritunl.client.electron.pkg" --username "contact@pritunl.com" --password "@keychain:xcode" --asc-provider U22BLATN63 --file Pritunl.arm64.pkg
#sleep 3
#xcrun altool --notarize-app --primary-bundle-id "com.pritunl.client.electron.zip" --username "contact@pritunl.com" --password "@keychain:xcode" --asc-provider U22BLATN63 --file Pritunl.arm64.pkg.zip
sleep 10
xcrun altool --notarization-history 0 --username "contact@pritunl.com" --password "@keychain:xcode"
