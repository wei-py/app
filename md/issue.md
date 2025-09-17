# android

## 配置

1. TEAM_ID

- 含义 ：Apple Developer 团队的唯一标识符，由 Apple 分配
- 用途 ：指定应用开发所属的开发者团队，在代码签名和 App Store 提交过程中必须
- 在工作流中的应用 ：传递给 Fastlane 用于构建配置，在 fastlane build_dev 命令中使用

2. DEBUG_PROVISIONING_PROFILE_SPECIFIER

- 含义 ：调试配置文件的名称标识符
- 用途 ：指定构建调试版本时使用的配置文件名称
- 在工作流中的应用 ：通过环境变量传递给 Fastlane，用于 update_code_signing_settings 操作

3. DEBUG_SIGNING_CERTIFICATE_P12_DATA

- 含义 ：开发者证书的 P12 格式数据，包含证书和私钥
- 用途 ：用于在构建过程中对应用进行签名，确保应用的完整性和 Authenticity
- 在工作流中的应用 ：传递给 Fastlane 用于构建配置，在 fastlane build_dev 命令中使用

4. DEBUG_SIGNING_CERTIFICATE_PASSWORD

- 含义 ：开发者证书的密码，用于解密 P12 格式的证书数据
- 用途 ：与 DEBUG_SIGNING_CERTIFICATE_P12_DATA 配合使用，确保证书的安全
- 在工作流中的应用 ：传递给 Fastlane 用于构建配置，在 fastlane build_dev 命令中使用

5. DEBUG_PROVISIONING_PROFILE_DATA

- 含义 ：开发者配置文件的二进制数据，包含应用的签名信息和权限配置
- 用途 ：用于在构建过程中对应用进行配置，确保应用在设备上的正确运行
