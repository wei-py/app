
✅ 使用 `pnpm` 安装依赖  
✅ Node.js 22 环境  
✅ 根据分支自动区分构建 **测试版（staging）** 和 **生产版（production）**  
✅ 支持 Android（APK/AAB）和 iOS（IPA）  
✅ 构建产物上传为 GitHub Artifacts 便于下载  
✅ 环境变量注入（如 API 地址、Bundle ID 等）  
✅ 清晰的日志和错误处理

---

📁 文件路径：`.github/workflows/build-react-native.yml`

```yaml
name: Build React Native App (Android & iOS)

on:
  push:
    branches:
      - main        # 生产环境
      - master      # 生产环境（兼容）
      - staging     # 测试环境

env:
  BUILD_TYPE: ${{ github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master' && 'production' || 'staging' }}
  NODE_VERSION: "22"
  PNPM_VERSION: "latest"
  REACT_NATIVE_PACKAGE: "react-native"

jobs:
  build-android:
    name: 🤖 Build Android (${{ env.BUILD_TYPE }})
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🟢 Setup Node.js ${{ env.NODE_VERSION }} with pnpm
        uses: pnpm/action-setup@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          pnpm-version: ${{ env.PNPM_VERSION }}

      - name: 📦 Install dependencies with pnpm
        run: |
          pnpm install --frozen-lockfile
          pnpm exec react-native config

      - name: 📱 Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: 🧩 Inject environment config (optional)
        run: |
          # 示例：根据环境写入不同 API 地址（你可以自定义）
          echo "REACT_APP_API_URL=${{ env.BUILD_TYPE == 'production' && 'https://api.prod.com' || 'https://api.staging.com' }}" > .env
          cat .env

      - name: 🏗️ Build Android ${{ env.BUILD_TYPE }} (APK)
        run: |
          cd android
          chmod +x ./gradlew
          ./gradlew assemble${{ env.BUILD_TYPE == 'production' && 'Release' || 'Debug' }}
        env:
          # 可选：签名密钥（如用于 release），建议使用 GitHub Secrets
          # ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          # KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}

      - name: 💾 Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-android-${{ env.BUILD_TYPE }}-apk
          path: android/app/build/outputs/apk/${{ env.BUILD_TYPE == 'production' && 'release' || 'debug' }}/app-${{ env.BUILD_TYPE == 'production' && 'release' || 'debug' }}.apk

      - name: 📦 Optional: Build AAB (for Google Play)
        if: env.BUILD_TYPE == 'production'
        run: |
          cd android
          ./gradlew bundleRelease

      - name: 💾 Upload AAB Artifact (Production Only)
        if: env.BUILD_TYPE == 'production'
        uses: actions/upload-artifact@v4
        with:
          name: app-android-production-aab
          path: android/app/build/outputs/bundle/release/app-release.aab

  build-ios:
    name: 🍏 Build iOS (${{ env.BUILD_TYPE }})
    runs-on: macos-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🟢 Setup Node.js ${{ env.NODE_VERSION }} with pnpm
        uses: pnpm/action-setup@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          pnpm-version: ${{ env.PNPM_VERSION }}

      - name: 📦 Install dependencies with pnpm
        run: |
          pnpm install --frozen-lockfile
          pnpm exec react-native config

      - name: 🍎 Setup iOS (CocoaPods)
        run: |
          cd ios
          pod install --repo-update

      - name: 🧩 Inject environment config (optional)
        run: |
          # 示例：写入不同环境变量
          echo "REACT_APP_API_URL=${{ env.BUILD_TYPE == 'production' && 'https://api.prod.com' || 'https://api.staging.com' }}" > .env
          cat .env

      - name: 🏗️ Build iOS ${{ env.BUILD_TYPE }}
        run: |
          # 使用 Release 模式构建生产版，Debug 构建测试版
          SCHEME="YourAppScheme"  # 👈 替换为你的 Xcode Scheme 名称
          CONFIGURATION="${{ env.BUILD_TYPE == 'production' && 'Release' || 'Debug' }}"

          xcodebuild clean build \
            -workspace ios/YourApp.xcworkspace \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -archivePath "build/YourApp.xcarchive" \
            -sdk iphoneos \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO

          # 导出 IPA
          xcodebuild -exportArchive \
            -archivePath "build/YourApp.xcarchive" \
            -exportPath "build/export" \
            -exportOptionsPlist ios/exportOptions.plist \
            -allowProvisioningUpdates

        env:
          # 如果需要签名，应配置证书和 Provisioning Profile（建议用 Fastlane 或 Secrets）
          # MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          # FASTLANE_USER: ${{ secrets.FASTLANE_USER }}

      - name: 💾 Upload IPA Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-ios-${{ env.BUILD_TYPE }}-ipa
          path: build/export/*.ipa

      - name: 📁 Upload Archive (Optional)
        uses: actions/upload-artifact@v4
        with:
          name: app-ios-${{ env.BUILD_TYPE }}-xcarchive
          path: build/YourApp.xcarchive

    # 注意：iOS 构建需要 macOS 环境，且首次构建可能较慢（Pod 安装）

```

---

## 📌 使用前你需要修改

1. **iOS Scheme 名称**  
   替换 `YourAppScheme` 为你的实际 Scheme（在 Xcode → Product → Scheme → Manage Schemes 中查看）。

2. **iOS 项目路径**  
   确保 `ios/YourApp.xcworkspace` 路径正确（通常是 `ios/YourProjectName.xcworkspace`）。

3. **环境变量注入**  
   `.env` 文件写入方式仅为示例。你也可以使用 `react-native-config` 或 `@env` 方式管理环境变量，推荐配合 `.env.staging` / `.env.production` 文件。

4. **签名配置（生产发布必需）**  
   - Android：配置签名密钥（建议用 GitHub Secrets 存储 `ANDROID_KEYSTORE_BASE64` 等）。
   - iOS：如需自动签名上传 TestFlight，建议集成 `fastlane match` + GitHub Secrets。

5. **导出选项（iOS）**  
   创建 `ios/exportOptions.plist` 文件，内容示例：

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>method</key>
       <string>development</string> <!-- 或 app-store / ad-hoc -->
       <key>destination</key>
       <string>export</string>
   </dict>
   </plist>
   ```

---

## ✅ 产物输出

构建完成后，你可以在 GitHub Actions 页面的 **Artifacts** 区域下载：

- Android: `app-debug.apk` / `app-release.apk` / `app-release.aab`
- iOS: `YourApp.ipa` / `.xcarchive`

---

## 🚀 进阶建议

- ✅ 集成 **Fastlane** 自动上传到 Firebase / TestFlight
- ✅ 使用 **CodePush** 热更新（可选 job）
- ✅ 添加 **单元测试 / E2E 测试** 步骤
- ✅ Slack / 钉钉通知构建结果

---

如果你提供你的项目结构（如 Scheme 名称、是否用 CodePush、是否需要签名等），我可以进一步为你定制！

希望这个工作流助你高效自动化构建 🚀
