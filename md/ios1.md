## ios/fastlane/Fastfile

```
# This file contains the fastlane.tools configuration
# You can find the documentation at https://docs.fastlane.tools
#
# For a list of all available actions, check out
#
#     https://docs.fastlane.tools/actions
#
# For a list of all available plugins, check out
#
#     https://docs.fastlane.tools/plugins/available-plugins
#

# Uncomment the line if you want fastlane to automatically update itself
# update_fastlane

default_platform(:ios)

platform :ios do
  desc "Description of what the lane does"
  lane :custom_lane do
    # add actions here: https://docs.fastlane.tools/actions
  end

  desc "development"
	lane :build_dev do |options|
		update_info_plist
		update_code_signing_settings
		
		# 设置版本号（如果环境变量中有指定）
		if ENV['FL_VERSION_NUMBER_VERSION_NUMBER']
			increment_version_number(
				version_number: ENV['FL_VERSION_NUMBER_VERSION_NUMBER']
			)
		end
		
		build_app(
			scheme: "app2",
			workspace: "app2.xcworkspace",
			export_method: "ad-hoc",
			configuration: "Debug",
			clean: true,
			xcargs: "GCC_PREPROCESSOR_DEFINITIONS='$(inherited) DEBUG=1'",
			export_options: {
				method: "ad-hoc",
				compileBitcode: false,
				signingStyle: "manual",
				provisioningProfiles: {
					ENV['FL_APP_IDENTIFIER'] || "com.app2" => ENV['FL_PROVISIONING_PROFILE_SPECIFIER']
				}
			}
		)
	end

	desc "release"
	lane :build_release do |options|
		update_info_plist
		update_code_signing_settings
		
		# 设置版本号（如果环境变量中有指定）
		if ENV['FL_VERSION_NUMBER_VERSION_NUMBER']
			increment_version_number(
				version_number: ENV['FL_VERSION_NUMBER_VERSION_NUMBER']
			)
		end
		
		# 设置构建号（如果环境变量中有指定）
		if ENV['FL_BUILD_NUMBER_BUILD_NUMBER']
			increment_build_number(
				build_number: ENV['FL_BUILD_NUMBER_BUILD_NUMBER']
			)
		end
		
		build_app(
			scheme: "app2",
			workspace: "app2.xcworkspace",
			export_method: "app-store",
			configuration: "Release",
			clean: true,
			export_options: {
				method: "app-store",
				compileBitcode: false,
				signingStyle: "manual",
				provisioningProfiles: {
					ENV['FL_APP_IDENTIFIER'] || "com.app2" => ENV['FL_PROVISIONING_PROFILE_SPECIFIER']
				}
			}
		)
	end
	
end
```

## .github/workflow/assemble_ios_debug.yml

```sh
# 工作流名称
name: Assemble Ios Debug

# 触发工作流程的事件
on:
  push:
    branches: [ main ]
    tags: [ v* ]
  pull_request:
    branches: [ main ]

  workflow_dispatch:

# 工作流环境变量
env:
  # 应用的application_id
  APP_ID: ${{secrets.APP_ID_DEBUG || 'com.app2'}}
  APP_NAME: Taro Demo
  VERSION_NUMBER: 1.0.0
  BUILD_NUMBER: ${{ github.run_number }}
  BUILD_TYPE: debug
  TEAM_ID: ${{secrets.TEAM_ID}}
  PROVISIONING_PROFILE_SPECIFIER: ${{secrets.DEBUG_PROVISIONING_PROFILE_SPECIFIER}}
  CODE_SIGN_IDENTITY: Apple Development
  SIGNING_CERTIFICATE_P12_DATA: ${{secrets.DEBUG_SIGNING_CERTIFICATE_P12_DATA}}
  SIGNING_CERTIFICATE_PASSWORD: ${{secrets.DEBUG_SIGNING_CERTIFICATE_PASSWORD}}
  PROVISIONING_PROFILE_DATA: ${{secrets.DEBUG_PROVISIONING_PROFILE_DATA}}

jobs:
  assemble:
    runs-on: macos-13
    steps:
      - name: Checkout Project
        uses: actions/checkout@v2
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v3
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install
      - name: Cache Pods
        uses: actions/cache@v4
        with:
          path: ios/Pods
          key: ${{ runner.os }}-pods-${{ hashFiles('**/Podfile.lock') }}
          restore-keys: |
            ${{ runner.os }}-pods-
      - name: Install pods
        run: cd ios && pod update --no-repo-update
      - name: Import signing certificate
        env:
          SIGNING_CERTIFICATE_P12_DATA: ${{ env.SIGNING_CERTIFICATE_P12_DATA }}
          SIGNING_CERTIFICATE_PASSWORD: ${{ env.SIGNING_CERTIFICATE_PASSWORD }}
        run: |
          exec .github/scripts/import-certificate.sh
      - name: Import provisioning profile
        env:
          PROVISIONING_PROFILE_DATA: ${{ env.PROVISIONING_PROFILE_DATA }}
        run: |
          exec .github/scripts/import-profile.sh
      - name: Build app
        env:
          FL_APP_IDENTIFIER: ${{ env.APP_ID }}
          FL_UPDATE_PLIST_DISPLAY_NAME: ${{ env.APP_NAME }}
          FL_UPDATE_PLIST_PATH: app2/Info.plist
          FL_VERSION_NUMBER_VERSION_NUMBER: ${{ env.VERSION_NUMBER }}
          FL_BUILD_NUMBER_BUILD_NUMBER: ${{ env.BUILD_NUMBER }}
          FL_CODE_SIGN_IDENTITY: ${{ env.CODE_SIGN_IDENTITY }}
          FL_PROVISIONING_PROFILE_SPECIFIER: ${{ env.PROVISIONING_PROFILE_SPECIFIER }}
          FASTLANE_TEAM_ID: ${{ env.TEAM_ID }}
          NODE_PATH: ${{ github.workspace }}/node_modules/.pnpm/node_modules:$NODE_PATH
        run: |
          cd ios
          bundle update
          bundle exec fastlane build_dev
      - name: Upload Ios Products
        uses: actions/upload-artifact@v4
        with:
          name: app-${{ env.BUILD_TYPE }}
          path: |
            ${{ github.workspace }}/ios/app2.ipa
            ${{ github.workspace }}/ios/app2.app.dSYM.zip
      - name: Rename release assets
        run: |
          mv ios/app2.ipa ios/app-${{ env.BUILD_TYPE }}.ipa
          mv ios/app2.app.dSYM.zip ios/app-${{ env.BUILD_TYPE }}.app.dSYM.zip
      - name: Upload release assets
        uses: softprops/action-gh-release@v1
        if: startsWith(github.ref, 'refs/tags/')
        with:
          prerelease: ${{ contains(github.ref, 'beta') }}
          files: |
            ios/app-${{ env.BUILD_TYPE }}.ipa
            ios/app-${{ env.BUILD_TYPE }}.app.dSYM.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

