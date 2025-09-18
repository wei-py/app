#!/bin/bash

# iOS Build Fix Script
# This script fixes common iOS build issues related to code signing and deployment targets

echo "🔧 Starting iOS build fix..."

# Navigate to iOS directory
cd "$(dirname "$0")"

echo "📁 Current directory: $(pwd)"

# Clean derived data
echo "🧹 Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean build folder
echo "🧹 Cleaning build folder..."
rm -rf build/

# Deintegrate and reinstall pods
echo "📦 Deintegrating CocoaPods..."
pod deintegrate

echo "📦 Installing CocoaPods with updated configuration..."
pod install

echo "✅ iOS build fix completed!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode and verify your development team is selected"
echo "2. Ensure automatic code signing is enabled"
echo "3. Try building again with: fastlane ios build_dev"
echo ""
echo "🔍 If you still have issues:"
echo "- Check that your Apple Developer account is properly configured"
echo "- Verify your bundle identifier is unique"
echo "- Make sure you have valid certificates in your keychain"