# iOS构建问题解决指南

## 问题描述
构建过程中出现 Error building the application 错误，通常是由于代码签名配置不匹配导致的。

## 根本原因分析

### 1. Bundle ID不匹配
- 问题：项目配置使用 com.app2，但配置文件是为 com.bto.Light 创建的
- 影响：导致代码签名失败

### 2. 导出方法错误
- **问题**：Debug构建使用了 `ad-hoc` 导出方法
- **正确配置**：Debug构建应使用 `development` 方法

### 3. 配置文件不匹配
- **问题**：Provisioning Profile与Bundle ID不对应

## 已修复的配置

### GitHub Actions工作流 (.github/workflows/assemble_ios_debug.yml)
```yaml
env:
  APP_ID: ${{secrets.APP_ID || 'com.bto.Light'}}
  APP_NAME: BTOLIGHT
```

### Fastfile配置 (ios/fastlane/Fastfile)
```ruby
# Debug构建
export_method: "development"
export_options: {
  method: "development",
  provisioningProfiles: {
    ENV['FL_APP_IDENTIFIER'] || "com.bto.Light" => ENV['FL_PROVISIONING_PROFILE_SPECIFIER']
  }
}
```

## 必需的GitHub Secrets配置

基于你的配置文件信息，需要在GitHub仓库设置以下Secrets：

### 基本配置
```
APP_ID = com.bto.Light
TEAM_ID = N59966K35U
```

### Debug配置
```
DEBUG_PROVISIONING_PROFILE_SPECIFIER = iOS Team Provisioning Profile: com.bto.Light
DEBUG_PROVISIONING_PROFILE_DATA = [Base64编码的.mobileprovision文件]
DEBUG_SIGNING_CERTIFICATE_P12_DATA = [Base64编码的.p12证书文件]
DEBUG_SIGNING_CERTIFICATE_PASSWORD = [证书密码]
```

## 配置步骤

### 1. 获取配置文件Base64数据
```bash
# 转换配置文件
base64 -i your_profile.mobileprovision | pbcopy
```

### 2. 获取证书Base64数据
```bash
# 转换证书文件
base64 -i your_certificate.p12 | pbcopy
```

### 3. 获取正确的配置文件名称
```bash
# 从配置文件中提取名称
security cms -D -i your_profile.mobileprovision | grep -A1 'Name' | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/'
```

## 验证配置

### 1. 检查Bundle ID匹配
确保以下配置一致：
- Xcode项目中的Bundle Identifier
- 配置文件中的App ID
- Fastfile中的FL_APP_IDENTIFIER

### 2. 检查证书类型
- Debug构建：使用 Apple Development 证书
- Release构建：使用 Apple Distribution 证书

### 3. 检查配置文件类型
- Debug构建：使用 Development 配置文件
- Release构建：使用 Distribution 配置文件

## 常见错误和解决方案

### 错误1：Code signing error
```
解决方案：
1. 确认证书和配置文件匹配
2. 检查Team ID是否正确
3. 验证配置文件未过期
```

### 错误2：Provisioning profile not found
```
解决方案：
1. 检查PROVISIONING_PROFILE_SPECIFIER名称是否正确
2. 确认配置文件已正确安装
3. 验证Bundle ID匹配
```

### 错误3：Export method mismatch
```
解决方案：
1. Debug构建使用 "development"
2. Release构建使用 "app-store" 或 "ad-hoc"
3. 确保export_options中的method与export_method一致
```

## 调试技巧

### 1. 查看详细日志
```bash
# 在GitHub Actions中查看完整的xcodebuild输出
# 日志路径：/Users/runner/Library/Logs/gym/app2-app2.log
```

### 2. 本地测试
```bash
# 在本地运行Fastlane命令测试
cd ios
bundle exec fastlane build_dev
```

### 3. 验证配置文件
```bash
# 检查已安装的配置文件
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# 查看配置文件详情
security cms -D -i profile.mobileprovision | plutil -p -
```

## 参考资源

- [Fastlane代码签名指南](https://docs.fastlane.tools/codesigning/getting-started/)
- [Apple开发者文档 - 代码签名](https://developer.apple.com/documentation/xcode/code-signing)
- [GitHub Actions iOS构建指南](https://docs.github.com/en/actions/guides/building-and-testing-swift)

## 总结

通过修复Bundle ID匹配性和导出方法配置，应该能够解决当前的构建失败问题。确保所有配置文件、证书和环境变量都与你的应用标识符 `com.bto.Light` 保持一致。