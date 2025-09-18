# iOS Build Fixes Documentation

This document explains the fixes we've implemented to resolve common build issues in the iOS project, particularly focusing on the Xcode version and code signing errors.

## Table of Contents
- [Issue Summary](#issue-summary)
- [Implemented Fixes](#implemented-fixes)
- [How to Use the Fixes](#how-to-use-the-fixes)
- [Manual Setup Instructions](#manual-setup-instructions)
- [Troubleshooting](#troubleshooting)

## Issue Summary

The build process was failing with errors related to:

1. **Xcode Version Mismatch**: The error indicated multiple Xcode versions were found, and the build was using `/Applications/Xcode_15.2.app`
2. **Provisioning Profile Issues**: "No profile for team '***' matching '***' found"
3. **Code Signing Configuration**: Missing proper development team selection

## Implemented Fixes

### 1. Fastfile Improvements

We've completely refactored the Fastfile with these key improvements:

- **Explicit Xcode Path**: Added `xcode_select("/Applications/Xcode.app")` to ensure the correct Xcode version is used
- **Team ID Configuration**: Set up environment-based team ID management
- **Reusable Signing Configuration**: Created a `configure_signing` helper lane
- **Detailed Export Options**: Added explicit export options with team ID and signing style
- **Utility Lane**: Added a `fix_build_issues` lane to automate common fixes

### 2. Appfile Configuration

Updated the Appfile to better handle team and provisioning profile configuration:
- Added environment variable support for team ID
- Included comments and guidance for provisioning profiles
- Ensured consistency with Fastfile configuration

### 3. Helper Script

Created a comprehensive bash script `fix_build_issues.sh` that:
- Cleans Xcode derived data
- Cleans the build folder
- Deintegrates and reinstalls CocoaPods
- Checks Xcode and Node.js installations
- Provides step-by-step manual setup instructions

## How to Use the Fixes

### Option 1: Use the Helper Script

The easiest way to apply all fixes is to run our helper script:

```bash
# From the root of your project
cd ios
./fix_build_issues.sh
```

This script will automatically clean your build environment and provide you with manual setup instructions.

### Option 2: Use Fastlane

If you have Fastlane installed, you can use our custom lane:

```bash
# From the root of your project
cd ios
fastlane fix_build_issues
```

### Option 3: Manual Build

After applying the fixes, you can build your project using:

```bash
# For development builds
cd ios
fastlane build_dev

# For release builds
cd ios
fastlane build_release
```

## Manual Setup Instructions

Even with our automated fixes, you may need to complete these manual steps in Xcode:

1. Open Xcode and load the project: `open ios/app.xcodeproj`
2. In Xcode, select your project in the Project Navigator
3. Select the 'app' target under 'Targets'
4. Go to the 'Signing & Capabilities' tab
5. Check the 'Automatically manage signing' checkbox
6. Select your development team from the dropdown menu
7. Build the project to verify everything works

## Important Configuration Notes

1. **Team ID Setup**

   You need to set your actual team ID in one of these places:
   - In your environment variables: `export FASTLANE_TEAM_ID="YOUR_ACTUAL_TEAM_ID"`
   - Directly in the Fastfile by replacing `'YOUR_TEAM_ID'` with your actual team ID
   - In the Appfile by uncommenting and setting the `team_id` line

2. **Xcode Version**

   Our fixes use the Xcode installation at `/Applications/Xcode.app`
   - Verify this is correct with: `xcode-select -p`
   - If you need to use a different version, update the path in the Fastfile

3. **Provisioning Profiles**

   For more advanced setups, you may want to use Fastlane Match for provisioning profile management:
   - https://docs.fastlane.tools/actions/match/
   - We've included commented-out configuration in the Appfile to help with this

## Troubleshooting

If you're still experiencing issues:

1. **Clean Everything**
   ```bash
   cd ios
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   pod deintegrate
   pod install
   ```

2. **Verify Xcode Configuration**
   ```bash
   xcode-select -p       # Check Xcode path
   xcodebuild -version   # Check Xcode version
   ```

3. **Check Signing Configuration in Xcode**
   - Ensure 'Automatically manage signing' is checked
   - Ensure your development team is selected
   - Check for any errors or warnings in the 'Signing & Capabilities' tab

4. **Update Dependencies**
   ```bash
   cd ..  # Go to project root
   npm install  # or yarn install
   cd ios
   pod update
   ```

5. **Check for Multiple Xcode Versions**
   ```bash
   ls -la /Applications/ | grep Xcode
   ```
   If multiple versions are found, ensure the correct one is selected with `xcode-select -s`

## Additional Resources

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Xcode Code Signing Guide](https://developer.apple.com/documentation/xcode/signing-a-binary)
- [React Native iOS Setup](https://reactnative.dev/docs/environment-setup)
