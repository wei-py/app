#!/bin/bash

# Helper script to fix common iOS build issues
# Usage: cd ios && ./fix_build_issues.sh

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print messages in color
echo_info() {
    echo "\033[1;32m[INFO]\033[0m $1"
}

echo_warning() {
    echo "\033[1;33m[WARNING]\033[0m $1"
}

echo_error() {
    echo "\033[1;31m[ERROR]\033[0m $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if we're in the correct directory
if [ ! -f "Podfile" ]; then
    echo_error "This script must be run from the ios directory"
    echo_error "Please run: cd ios && ./fix_build_issues.sh"
    exit 1
fi

# Check if required tools are installed
if ! command_exists "pod"; then
    echo_error "CocoaPods is not installed"
    echo_info "Please install it with: sudo gem install cocoapods"
    exit 1
fi

if ! command_exists "xcodebuild"; then
    echo_error "Xcode is not installed or not in PATH"
    echo_info "Please install Xcode from the App Store"
    exit 1
fi

# Step 1: Clean derived data
echo_info "Cleaning Xcode derived data..."
derived_data_path="$(xcodebuild -showBuildSettings -project app.xcodeproj | grep -m 1 -o 'DERIVED_DATA_DIR = .*' | cut -d '=' -f 2- | xargs)"
if [ -d "$derived_data_path" ]; then
    rm -rf "$derived_data_path"
    echo_info "Cleaned derived data at: $derived_data_path"
else
    echo_info "No derived data found to clean"
fi

# Step 2: Clean build folder
echo_info "Cleaning Xcode build folder..."
xcodebuild -project app.xcodeproj -scheme app clean || echo_warning "Build folder clean had issues"

# Step 3: Deintegrate and reinstall pods
echo_info "Deintegrating CocoaPods..."
pod deintegrate || echo_warning "Pod deintegration had issues"

echo_info "Reinstalling CocoaPods..."
pod install

# Step 4: Check Xcode version
xcode_version="$(xcodebuild -version | head -n 1)"
echo_info "Current Xcode version: $xcode_version"

# Step 5: Check Xcode path
xcode_path="$(xcode-select -p)"
echo_info "Current Xcode path: $xcode_path"

# Step 6: Check if node is installed for React Native
echo_info "Checking Node.js installation..."
if command_exists "node"; then
    node_version="$(node -v)"
    echo_info "Node.js version: $node_version"
else
    echo_warning "Node.js is not installed"
    echo_info "Please install Node.js for React Native development"
fi

# Step 7: Show important notes for manual setup
echo "\n\033[1;44mIMPORTANT MANUAL STEPS\033[0m"
echo_warning "Please complete these steps in Xcode to ensure proper code signing:\n"
echo "1. Open Xcode and load the project:"
echo "   $ open app.xcodeproj"
echo ""
echo "2. In Xcode, select your project in the Project Navigator"
echo ""
echo "3. Select the 'app' target under 'Targets'"
echo ""
echo "4. Go to the 'Signing & Capabilities' tab"
echo ""
echo "5. Check the 'Automatically manage signing' checkbox"
echo ""
echo "6. Select your development team from the dropdown menu"
echo ""
echo "7. If you encounter provisioning profile issues:"
echo "   - Try unchecking and rechecking 'Automatically manage signing'"
echo "   - Or manually select a provisioning profile"
echo ""
echo "8. Build the project in Xcode to verify everything works"
echo ""
echo_info "You can also use our custom Fastlane lane to fix issues:"
echo_info "$ cd ios && fastlane fix_build_issues"

# Make script executable
echo_info "Making script executable for future use..."
chmod +x "$(basename "$0")"

echo_info "✅ Build issue fixing process completed!"