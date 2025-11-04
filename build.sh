#!/bin/bash

# Build script for WebsiteLoginBot
# This script compiles both the menu-bar app and the worker tool,
# then packages everything for installation.

set -e  # Exit on error

echo "🚀 Building WebsiteLoginBot..."
echo ""

# Configuration
PROJECT_NAME="WebsiteLoginBot"
SCHEME_APP="WebsiteLoginBot"
SCHEME_WORKER="LoginWorker"
CONFIGURATION="Release"
BUILD_DIR="./build"
DERIVED_DATA="./.build/DerivedData"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${DERIVED_DATA}"
mkdir -p "${BUILD_DIR}"

# Build the main menu-bar application
echo "📱 Building menu-bar application..."
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_APP}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${DERIVED_DATA}" \
    clean build

# Build the worker tool
echo "⚙️  Building worker tool..."
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_WORKER}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${DERIVED_DATA}" \
    clean build

# Copy built products
echo "📦 Packaging applications..."
cp -R "${DERIVED_DATA}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app" "${BUILD_DIR}/"
cp "${DERIVED_DATA}/Build/Products/${CONFIGURATION}/LoginWorker" "${BUILD_DIR}/"

# Copy worker into the app bundle
echo "🔧 Integrating worker tool into app bundle..."
mkdir -p "${BUILD_DIR}/${PROJECT_NAME}.app/Contents/MacOS/"
cp "${BUILD_DIR}/LoginWorker" "${BUILD_DIR}/${PROJECT_NAME}.app/Contents/MacOS/"

# Create LaunchAgents directory and copy plists
echo "📋 Preparing LaunchAgent configurations..."
mkdir -p "${BUILD_DIR}/LaunchAgents"
cp LaunchAgents/*.plist "${BUILD_DIR}/LaunchAgents/"

# Update plist paths to point to the installed location
USER_HOME="$HOME"
APP_PATH="/Applications/${PROJECT_NAME}.app/Contents/MacOS/LoginWorker"
LOG_DIR="${USER_HOME}/Library/Logs/WebsiteLoginBot"

# Create logs directory
mkdir -p "${LOG_DIR}"

echo "✏️  Updating LaunchAgent paths..."
for plist in "${BUILD_DIR}/LaunchAgents/"*.plist; do
    # Replace placeholder paths
    sed -i '' "s|/Applications/WebsiteLoginBot.app/Contents/MacOS/LoginWorker|${APP_PATH}|g" "$plist"
    sed -i '' "s|~/Library/Logs/WebsiteLoginBot|${LOG_DIR}|g" "$plist"
done

# Code signing (optional, but recommended)
if [ -n "${CODE_SIGN_IDENTITY}" ]; then
    echo "✍️  Code signing application..."
    codesign --force --deep --sign "${CODE_SIGN_IDENTITY}" "${BUILD_DIR}/${PROJECT_NAME}.app"
else
    echo "⚠️  Skipping code signing (no CODE_SIGN_IDENTITY set)"
fi

echo ""
echo "✅ Build complete!"
echo ""
echo "📍 Build artifacts:"
echo "   App:          ${BUILD_DIR}/${PROJECT_NAME}.app"
echo "   LaunchAgents: ${BUILD_DIR}/LaunchAgents/"
echo ""
echo "📥 To install:"
echo "   1. cp -R ${BUILD_DIR}/${PROJECT_NAME}.app /Applications/"
echo "   2. cp ${BUILD_DIR}/LaunchAgents/*.plist ~/Library/LaunchAgents/"
echo "   3. launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist"
echo "   4. launchctl load ~/Library/LaunchAgents/com.websiteloginbot.retry.plist"
echo "   5. Launch the app from /Applications/${PROJECT_NAME}.app"
echo ""
echo "📚 See README.md for complete installation instructions."
echo ""