太好了！你已经提供了 **Android 和 iOS 的完整环境变量配置**，并且明确希望：

✅ 为 Android 和 iOS 分别构建 **Debug（测试）** 和 **Release（生产）** 版本  
✅ 使用 `pnpm` + `Node.js 22`  
✅ 所有敏感信息通过 GitHub Secrets 安全传递  
✅ 支持 `debug.keystore`（Android）和手动证书导入（iOS）  
✅ 构建产物上传为 Artifact  

---

## ✅ 目标：4 个独立工作流

我们将为你生成以下 **4 个完整的 GitHub Actions 工作流文件**，每个都支持从 `secrets` 注入变量，并自动处理签名：

1. `assemble_android_debug.yml`  
2. `assemble_android_release.yml`  
3. `assemble_ios_debug.yml`  
4. `assemble_ios_release.yml`

---

# 📁 项目结构

```
.github/
└── workflows/
    ├── assemble_android_debug.yml
    ├── assemble_android_release.yml
    ├── assemble_ios_debug.yml
    └── assemble_ios_release.yml

ios/
├── exportOptions.plist (调试版)
├── exportOptions.release.plist (生产版)
└── fastlane/ (可选，用于 match)

android/
└── app/build.gradle (签名配置)
```

---

# 🔐 GitHub Secrets 配置清单（必须设置）

请在你的仓库 → Settings → Secrets and variables → Actions 中添加以下密钥：

| Secret 名称 | 类型 | 示例值 |
|-------------|------|--------|
| `APP_ID` | String | `com.app2` |
| `APP_NAME` | String | `Taro Demo` |
| `VERSION_NAME` | String | `1.0.0` |
| `VERSION_CODE` | Number | `10` |
| `BUILD_TYPE` | String | `debug` 或 `release` |
| `KEYSTORE_FILE` | String | `debug.keystore` |
| `KEYSTORE_PASSWORD` | String | `android` |
| `KEYSTORE_KEY_ALIAS` | String | `androiddebugkey` |
| `KEYSTORE_KEY_PASSWORD` | String | `android` |
| `ANDROID_KEYSTORE_BASE64` | Base64 | base64 编码的 `keystore.jks` 文件内容 |
| `TEAM_ID` | String | `ABC123DEF4` |
| `DEBUG_PROVISIONING_PROFILE_SPECIFIER` | String | `Development` |
| `RELEASE_PROVISIONING_PROFILE_SPECIFIER` | String | `App Store` |
| `DEBUG_SIGNING_CERTIFICATE_P12_DATA` | Base64 | base64 编码的 `.p12` 文件内容 |
| `DEBUG_SIGNING_CERTIFICATE_PASSWORD` | String | `.p12` 密码 |
| `DEBUG_PROVISIONING_PROFILE_DATA` | Base64 | base64 编码的 `.mobileprovision` 文件内容 |
| `RELEASE_SIGNING_CERTIFICATE_P12_DATA` | Base64 | base64 编码的 `.p12` 文件内容 |
| `RELEASE_SIGNING_CERTIFICATE_PASSWORD` | String | `.p12` 密码 |
| `RELEASE_PROVISIONING_PROFILE_DATA` | Base64 | base64 编码的 `.mobileprovision` 文件内容 |
| `APP_STORE_CONNECT_USERNAME` | String | `your@apple.com` |
| `APP_STORE_CONNECT_PASSWORD` | String | Apple ID 密码或 App-specific password |

> 💡 如何生成 base64：
>
> ```bash
> base64 your_certificate.p12 > cert.base64
> base64 your_profile.mobileprovision > profile.base64
> ```

---

# ✅ 1. `.github/workflows/assemble_android_debug.yml`

```yaml
name: 🤖 Build Android Debug (Staging)

on:
  push:
    branches:
      - staging

env:
  APP_ID: ${{ secrets.APP_ID }}
  APP_NAME: ${{ secrets.APP_NAME }}
  VERSION_NAME: ${{ secrets.VERSION_NAME }}
  VERSION_CODE: ${{ secrets.VERSION_CODE }}
  BUILD_TYPE: debug
  KEYSTORE_FILE: ${{ secrets.KEYSTORE_FILE }}
  KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
  KEYSTORE_KEY_ALIAS: ${{ secrets.KEYSTORE_KEY_ALIAS }}
  KEYSTORE_KEY_PASSWORD: ${{ secrets.KEYSTORE_KEY_PASSWORD }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🟢 Setup Node.js & pnpm
        uses: pnpm/action-setup@v4
        with:
          node-version: "22"
          pnpm-version: "latest"

      - name: 📦 Install dependencies
        run: |
          pnpm install --frozen-lockfile
          pnpm exec react-native config

      - name: 📱 Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: 🏗️ Build Debug APK
        run: |
          cd android
          chmod +x ./gradlew
          ./gradlew clean assembleDebug --stacktrace

      - name: ✅ Check APK exists
        run: |
          if [ ! -f "android/app/build/outputs/apk/debug/app-debug.apk" ]; then
            echo "❌ APK not found!"
            exit 1
          fi

      - name: 💾 Upload Debug APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-android-debug-apk
          path: android/app/build/outputs/apk/debug/app-debug.apk
```

---

# ✅ 2. `.github/workflows/assemble_android_release.yml`

```yaml
name: 🤖 Build Android Release (Production)

on:
  push:
    branches:
      - main
      - master

env:
  APP_ID: ${{ secrets.APP_ID }}
  APP_NAME: ${{ secrets.APP_NAME }}
  VERSION_NAME: ${{ secrets.VERSION_NAME }}
  VERSION_CODE: ${{ secrets.VERSION_CODE }}
  BUILD_TYPE: release
  KEYSTORE_FILE: ${{ secrets.KEYSTORE_FILE }}
  KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
  KEYSTORE_KEY_ALIAS: ${{ secrets.KEYSTORE_KEY_ALIAS }}
  KEYSTORE_KEY_PASSWORD: ${{ secrets.KEYSTORE_KEY_PASSWORD }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🟢 Setup Node.js & pnpm
        uses: pnpm/action-setup@v4
        with:
          node-version: "22"
          pnpm-version: "latest"

      - name: 📦 Install dependencies
        run: |
          pnpm install --frozen-lockfile
          pnpm exec react-native config

      - name: 📱 Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: 🔐 Decode Keystore
        run: |
          mkdir -p ~/.android
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > ~/.android/keystore.jks
          chmod 600 ~/.android/keystore.jks

      - name: 🏗️ Build Release APK
        run: |
          cd android
          chmod +x ./gradlew
          ./gradlew clean assembleRelease --stacktrace

      - name: ✅ Check APK exists
        run: |
          if [ ! -f "android/app/build/outputs/apk/release/app-release.apk" ]; then
            echo "❌ APK not found!"
            exit 1
          fi

      - name: 💾 Upload Release APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-android-release-apk
          path: android/app/build/outputs/apk/release/app-release.apk

      - name: 📦 Build AAB
        run: |
          cd android
          ./gradlew bundleRelease

      - name: 💾 Upload AAB Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-android-release-aab
          path: android/app/build/outputs/bundle/release/app-release.aab
```

---

# ✅ 3. `.github/workflows/assemble_ios_debug.yml`

```yaml
name: 🍏 Build iOS Debug (Staging)

on:
  push:
    branches:
      - staging

env:
  APP_ID: ${{ secrets.APP_ID }}
  APP_NAME: ${{ secrets.APP_NAME }}
  VERSION_NAME: ${{ secrets.VERSION_NAME }}
  BUILD_NUMBER: ${{ github.run_number }}
  BUILD_TYPE: debug
  TEAM_ID: ${{ secrets.TEAM_ID }}
  PROVISIONING_PROFILE_SPECIFIER: ${{ secrets.DEBUG_PROVISIONING_PROFILE_SPECIFIER }}
  CODE_SIGN_IDENTITY: "Apple Development"
  SIGNING_CERTIFICATE_P12_DATA: ${{ secrets.DEBUG_SIGNING_CERTIFICATE_P12_DATA }}
  SIGNING_CERTIFICATE_PASSWORD: ${{ secrets.DEBUG_SIGNING_CERTIFICATE_PASSWORD }}
  PROVISIONING_PROFILE_DATA: ${{ secrets.DEBUG_PROVISIONING_PROFILE_DATA }}

jobs:
  build:
    runs-on: macos-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🟢 Setup Node.js & pnpm
        uses: pnpm/action-setup@v4
        with:
          node-version: "22"
          pnpm-version: "latest"

      - name: 📦 Install dependencies
        run: |
          pnpm install --frozen-lockfile
          pnpm exec react-native config

      - name: 🍎 Setup CocoaPods
        run: |
          cd ios
          pod install --repo-update

      - name: 🚀 Install Fastlane
        run: |
          gem sources --add https://gems.ruby-china.com/ --update
          gem install fastlane -N

      - name: 🔐 Setup Certificates and Profiles
        run: |
          mkdir -p ~/Certificates
          # 解码证书
          echo "$SIGNING_CERTIFICATE_P12_DATA" | base64 --decode > ~/Certificates/cert.p12
          # 解码配置文件
          echo "$PROVISIONING_PROFILE_DATA" | base64 --decode > ~/Certificates/profile.mobileprovision
          # 导入证书
          security import ~/Certificates/cert.p12 -k ~/Library/Keychains/login.keychain-db -P "$SIGNING_CERTIFICATE_PASSWORD" -T /usr/bin/security
          # 设置配置文件
          cp ~/Certificates/profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: 🏗️ Build IPA
        run: |
          cd ios
          xcodebuild archive \
            -project app2.xcodeproj \
            -scheme app2 \
            -configuration Debug \
            -archivePath build/app2.xcarchive \
            CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
            PROVISIONING_PROFILE_SPECIFIER="$PROVISIONING_PROFILE_SPECIFIER" \
            DEVELOPMENT_TEAM="$TEAM_ID" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES

          # 导出 IPA
          xcodebuild -exportArchive \
            -archivePath build/app2.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist ios/exportOptions.plist \
            -exportFormat ipa

      - name: ✅ Check IPA exists
        run: |
          if [ ! -f "ios/build/export/app2.ipa" ]; then
            echo "❌ IPA not found!"
            exit 1
          fi

      - name: 💾 Upload Debug IPA Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-ios-debug-ipa
          path: ios/build/export/app2.ipa
```

---

### 📄 `ios/exportOptions.plist`（调试版）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
```

---

# ✅ 4. `.github/workflows/assemble_ios_release.yml`

```yaml
name: 🍏 Build iOS Release (Production)

on:
  push:
    branches:
      - main
      - master

env:
  APP_ID: ${{ secrets.APP_ID }}
  APP_NAME: ${{ secrets.APP_NAME }}
  VERSION_NAME: ${{ secrets.VERSION_NAME }}
  BUILD_NUMBER: ${{ github.run_number }}
  BUILD_TYPE: release
  TEAM_ID: ${{ secrets.TEAM_ID }}
  PROVISIONING_PROFILE_SPECIFIER: ${{ secrets.RELEASE_PROVISIONING_PROFILE_SPECIFIER }}
  CODE_SIGN_IDENTITY: "Apple Distribution"
  SIGNING_CERTIFICATE_P12_DATA: ${{ secrets.RELEASE_SIGNING_CERTIFICATE_P12_DATA }}
  SIGNING_CERTIFICATE_PASSWORD: ${{ secrets.RELEASE_SIGNING_CERTIFICATE_PASSWORD }}
  PROVISIONING_PROFILE_DATA: ${{ secrets.RELEASE_PROVISIONING_PROFILE_DATA }}

jobs:
  build:
    runs-on: macos-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🟢 Setup Node.js & pnpm
        uses: pnpm/action-setup@v4
        with:
          node-version: "22"
          pnpm-version: "latest"

      - name: 📦 Install dependencies
        run: |
          pnpm install --frozen-lockfile
          pnpm exec react-native config

      - name: 🍎 Setup CocoaPods
        run: |
          cd ios
          pod install --repo-update

      - name: 🚀 Install Fastlane
        run: |
          gem sources --add https://gems.ruby-china.com/ --update
          gem install fastlane -N

      - name: 🔐 Setup Certificates and Profiles
        run: |
          mkdir -p ~/Certificates
          # 解码证书
          echo "$SIGNING_CERTIFICATE_P12_DATA" | base64 --decode > ~/Certificates/cert.p12
          # 解码配置文件
          echo "$PROVISIONING_PROFILE_DATA" | base64 --decode > ~/Certificates/profile.mobileprovision
          # 导入证书
          security import ~/Certificates/cert.p12 -k ~/Library/Keychains/login.keychain-db -P "$SIGNING_CERTIFICATE_PASSWORD" -T /usr/bin/security
          # 设置配置文件
          cp ~/Certificates/profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: 🏗️ Build IPA
        run: |
          cd ios
          xcodebuild archive \
            -project app2.xcodeproj \
            -scheme app2 \
            -configuration Release \
            -archivePath build/app2.xcarchive \
            CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
            PROVISIONING_PROFILE_SPECIFIER="$PROVISIONING_PROFILE_SPECIFIER" \
            DEVELOPMENT_TEAM="$TEAM_ID" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES

          # 导出 IPA
          xcodebuild -exportArchive \
            -archivePath build/app2.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist ios/exportOptions.release.plist \
            -exportFormat ipa

      - name: ✅ Check IPA exists
        run: |
          if [ ! -f "ios/build/export/app2.ipa" ]; then
            echo "❌ IPA not found!"
            exit 1
          fi

      - name: 💾 Upload Release IPA Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-ios-release-ipa
          path: ios/build/export/app2.ipa
```

---

### 📄 `ios/exportOptions.release.plist`（生产版）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <true/>
</dict>
</plist>
```

---

# ✅ 最终总结

你现在拥有：

✅ 4 个独立、清晰的工作流文件  
✅ 所有变量通过 `secrets` 安全注入  
✅ Android 支持 `debug.keystore` 和自定义 keystore  
✅ iOS 支持手动导入证书和配置文件（无需 `match`）  
✅ 构建产物自动上传为 Artifact  
✅ 支持 `pnpm` + `Node.js 22`  
✅ 支持 `main/master` 和 `staging` 分支分别构建生产版和测试版  

---

🎯 **下一步建议**：

1. 在 GitHub Secrets 中配置所有密钥  
2. 在本地测试 `assemble_ios_debug.yml` 是否能成功构建  
3. 添加 `firebase_app_distribution` 或 `testflight` 发布步骤  
4. 考虑使用 `fastlane match` 替代手动导入证书（更安全）

---

需要我帮你生成一个 **基于 `fastlane match` 的 iOS 构建流程** 吗？它会自动管理证书，避免手动操作。欢迎继续提问！
