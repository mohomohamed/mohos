#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="DisplayMenu.app"
BUILD_DIR="$PROJECT_DIR/build"
INSTALL_DIR="$HOME/Applications"

echo "=== Building DisplayMenu ==="

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/Resources"

# Compile Swift code
echo "Compiling Swift source..."
swiftc -O "$PROJECT_DIR/main.swift" -o "$BUILD_DIR/$APP_NAME/Contents/MacOS/DisplayMenu"

# Copy Info.plist
echo "Packaging Info.plist..."
cp "$PROJECT_DIR/Info.plist" "$BUILD_DIR/$APP_NAME/Contents/Info.plist"

# Code sign ad-hoc
echo "Code signing app bundle..."
codesign --force --deep -s - "$BUILD_DIR/$APP_NAME"

# Install to ~/Applications
echo "Installing to $INSTALL_DIR/$APP_NAME..."
mkdir -p "$INSTALL_DIR"

# Kill running instance if exists
pkill -x "DisplayMenu" 2>/dev/null || true

# Copy bundle
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -R "$BUILD_DIR/$APP_NAME" "$INSTALL_DIR/$APP_NAME"

echo "=== Build and Installation Complete ==="
echo "DisplayMenu installed at: $INSTALL_DIR/$APP_NAME"
echo "Launching DisplayMenu..."
open "$INSTALL_DIR/$APP_NAME"
