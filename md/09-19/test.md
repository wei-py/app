### 🔧 问题定位

你的 CI/CD 构建失败的核心原因是：

> **`Your export_method in gym is defined as 'development' which might cause problems when signing your application`**

这表明你在 `Fastfile` 中的 `build_dev` lane 使用了 `export_method: "development"`，但 Fastlane 的 `gym` 工具在使用此方法时遇到了**签名或导出流程的问题**。

虽然这条信息是“警告”，但在某些情况下（尤其是 CI 环境中）它会直接导致构建失败。结合你提供的 `Fastfile` 和工作流配置，我们可以判断：

---

## ✅ 根本原因分析

1. **`export_method: "development"` 与手动签名冲突**
   - 你设置了 `signingStyle: "manual"` 并通过环境变量传入了 `provisioningProfiles`。
   - 但 `development` 导出方式要求使用 Xcode 自动管理的开发证书和描述文件，而你却用的是 **手动指定的 provisioning profile**。
   - 这种混合模式可能导致签名不一致或无法正确应用。

2. **CI 环境缺少模拟器支持**
   - `development` 模式通常用于在设备上调试，需要连接真实设备或使用模拟器。
   - GitHub Actions 的 macOS 跑道（macos-13）**没有物理设备连接**，且默认也不运行模拟器。
   - 因此，即使你成功编译了 `.app`，也无法完成 `development` 方法的导出。

3. **`gym` 工具对 `development` 的限制**
   - `gym` 在处理 `development` 方法时，会尝试生成一个可安装到设备上的 `.ipa`，但这个过程依赖于特定的签名规则。
   - 如果签名信息不完整或不匹配，就会报错。

---

## 🛠️ 解决方案

### ✅ 推荐方案：改用 `ad-hoc` 或 `enterprise` 导出方式（适用于 CI）

对于 CI 构建，**不应使用 `development`**，因为：
- 它只允许安装到注册过的设备；
- 不适合自动化分发；
- 可能因签名策略导致失败。

#### ✔️ 修改 `Fastfile` 中的 `build_dev` lane：

```ruby
lane :build_dev do |options|
  update_info_plist
  update_code_signing_settings

  # 设置版本号
  if ENV['FL_VERSION_NUMBER_VERSION_NUMBER']
    increment_version_number(
      version_number: ENV['FL_VERSION_NUMBER_VERSION_NUMBER']
    )
  end

  build_app(
    scheme: "app2",
    workspace: "app2.xcworkspace",
    export_method: "ad-hoc",  # ✅ 改为 ad-hoc
    configuration: "Debug",
    clean: true,
    xcargs: "GCC_PREPROCESSOR_DEFINITIONS='$(inherited) DEBUG=1'",
    export_options: {
      method: "ad-hoc",  # ✅ 同步修改
      compileBitcode: false,
      signingStyle: "manual",
      provisioningProfiles: {
        ENV['FL_APP_IDENTIFIER'] || "com.app2" => ENV['FL_PROVISIONING_PROFILE_SPECIFIER']
      }
    }
  )
end
```

> 💡 `ad-hoc` 允许你将 IPA 分发给最多 100 台测试设备，非常适合 CI 测试发布。

---

### ⚠️ 补充建议

#### 1. 确保 `provisioning_profile_specifier` 正确
检查你的 `DEBUG_PROVISIONING_PROFILE_SPECIFIER` 是否确实对应一个有效的 **Ad Hoc 描述文件**（不是 Development 类型），并且包含了所有必要的设备 UDID。

#### 2. 验证证书是否已导入
确保 `.github/scripts/import-certificate.sh` 成功导入了 P12 证书，并且可以被 Xcode 使用。

你可以添加以下命令来验证：

```bash
# 在 import-certificate.sh 后面加一句
security find-identity -p codesigning /System/Library/Keychains/System.keychain
```

查看是否有 `Apple Development` 或 `Apple Distribution` 证书。

#### 3. 检查 `Info.plist` 的 Bundle Identifier
确认 `app2/Info.plist` 中的 `CFBundleIdentifier` 是 `com.app2`，否则会导致签名失败。

---

### ✅ 最终修复后的 `Fastfile` 示例（关键部分）

```ruby
lane :build_dev do |options|
  update_info_plist
  update_code_signing_settings

  if ENV['FL_VERSION_NUMBER_VERSION_NUMBER']
    increment_version_number(version_number: ENV['FL_VERSION_NUMBER_VERSION_NUMBER'])
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
```

---

### ✅ 工作流无需修改（保持不变）

你的 `assemble_ios_debug.yml` 已经正确传递了所有必要参数，只需确保 `secrets.DEBUG_PROVISIONING_PROFILE_SPECIFIER` 对应的是一个 **Ad Hoc 类型的描述文件**。

---

## 📌 总结

| 问题 | 原因 | 解决方案 |
|------|------|-----------|
| 构建失败 | `export_method: development` 与手动签名冲突 | 改为 `ad-hoc` |
| 签名失败 | 描述文件类型错误 | 使用 Ad Hoc 描述文件 |
| 缺少设备 | CI 环境无物理设备 | 使用 ad-hoc 分发 |

---

✅ **推荐操作顺序：**

1. 将 `export_method` 改为 `"ad-hoc"`
2. 确认 `DEBUG_PROVISIONING_PROFILE_SPECIFIER` 是 Ad Hoc 类型
3. 重新触发 CI 构建

这样就能成功构建并上传 IPA 文件了。