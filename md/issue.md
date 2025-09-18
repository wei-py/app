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

## 解决方案

### 步骤 1：正确设置 GitHub Secrets

您需要将每个 Secret 的 值 设置为实际的证书数据、密码等，而不是 Secret 的名称。以下是正确的设置方式：

1. TEAM_ID : 设置为您的 Apple Developer 团队 ID（例如： ABCDE12345 ）
2. DEBUG_SIGNING_CERTIFICATE_P12_DATA : 设置为您的.p12 证书文件的 base64 编码内容
3. DEBUG_SIGNING_CERTIFICATE_PASSWORD : 设置为您的证书密码
4. DEBUG_PROVISIONING_PROFILE_DATA : 设置为您的配置文件的 base64 编码内容
5. DEBUG_PROVISIONING_PROFILE_SPECIFIER : 设置为您的配置文件名称


base64 -i ./BoGuang.mobileprovision -o ./BoGuang.mobileprovision.txt
base64 -i ./newBto.p12 -o ./newBto.p12.txt


### 步骤 2：如何获取正确的证书数据

要获取.p12 证书和配置文件的 base64 编码内容，请在本地计算机上执行以下命令：
对于.p12 证书：

```bash
openssl base64 -in path/to/your/certificate.p12 -out certificate.p12.base64
```

对于.mobileprovision 配置文件：

```bash
openssl base64 -in path/to/your/provisioning/profile.mobileprovision -out profile.mobileprovision.base64
```

这些命令会将 base64 编码的内容复制到剪贴板，您可以直接粘贴到 GitHub Secrets 中。

### 步骤 3：优化脚本以提高错误处理能力

修改 .github/scripts/import-certificate.sh 脚本，添加更严格的验证和更详细的错误信息：

```bash
#!/bin/bash
set -euo pipefail

# 设置调试模式，帮助诊断问题
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
# set -x

# 验证关键环境变量格式
validate_env() {
  local var_name="$1"
  local var_value="${!var_name}"

  # 检查是否只是变量名本身（常见错误）
  if [[ "$var_value" == "$var_name" ]]; then
    echo "错误：环境变量 $var_name 的值被错误地设置为变量名本身。请在GitHub Secrets中设置正确的值。"
    return 1
  fi

  # 对于证书数据，检查是否包含有效的base64字符
  if [[ "$var_name" == *"_DATA" ]]; then
    if ! echo "$var_value" | base64 --decode > /dev/null 2>&1; then
      echo "错误：环境变量 $var_name 包含无效的base64数据。"
      return 1
    fi
  fi

  return 0
}

# 确保环境变量存在并验证格式
if ! validate_env "SIGNING_CERTIFICATE_P12_DATA"; then
  exit 1
fi

if ! validate_env "SIGNING_CERTIFICATE_PASSWORD"; then
  exit 1
fi

# 创建和配置钥匙串 - 使用绝对路径
KEYCHAIN_PATH="$(pwd)/build.keychain"
echo "创建钥匙串：$KEYCHAIN_PATH"
security delete-keychain "$KEYCHAIN_PATH" || true
security create-keychain -p "" "$KEYCHAIN_PATH"
security list-keychains -s "$KEYCHAIN_PATH"
security default-keychain -s "$KEYCHAIN_PATH"
security unlock-keychain -p "" "$KEYCHAIN_PATH"
security set-keychain-settings -t 3600 "$KEYCHAIN_PATH"

echo "钥匙串配置完成，当前钥匙串列表："
security list-keychains

# 解码证书
echo "解码证书..."
echo "$SIGNING_CERTIFICATE_P12_DATA" | base64 --decode > signingCertificate.p12

# 检查证书文件是否创建成功
if [[ ! -f signingCertificate.p12 ]]; then
  echo "错误：证书文件解码失败。请检查SIGNING_CERTIFICATE_P12_DATA是否为有效的base64编码证书。"
  exit 1
fi

# 检查证书文件大小是否合理
if [[ $(stat -f%z signingCertificate.p12) -lt 1000 ]]; then
  echo "警告：证书文件大小异常小（小于1KB），可能是base64解码失败。请检查SIGNING_CERTIFICATE_P12_DATA的值。"
fi

# 导入证书 - 优化参数格式
SECURITY_PASSWORD="${SIGNING_CERTIFICATE_PASSWORD:-}"
echo "导入证书到钥匙串..."
security import signingCertificate.p12 \
                -f pkcs12 \
                -k "$KEYCHAIN_PATH" \
                -P "$SECURITY_PASSWORD" \
                -T /usr/bin/codesign \
                -T /usr/bin/security \
                -A || {
  echo "证书导入失败，尝试使用备选方法..."
  security import signingCertificate.p12 \
                  -k "$KEYCHAIN_PATH" \
                  -P "$SECURITY_PASSWORD" \
                  -T /usr/bin/codesign \
                  -T /usr/bin/security \
                  -A || {
    echo "错误：证书导入失败。请检查证书文件和密码是否正确。"
    exit 1
  }
}

# 设置密钥分区列表
echo "设置密钥分区列表..."
security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KEYCHAIN_PATH" || {
  echo "密钥分区列表设置失败，尝试简化参数..."
  security set-key-partition-list -S apple-tool:,apple: -s -k "" -d "$KEYCHAIN_PATH" || {
    echo "错误：密钥分区列表设置失败。"
    exit 1
  }
}

# 验证证书是否成功导入
echo "验证证书是否成功导入..."
security find-identity -v -p codesigning "$KEYCHAIN_PATH" || {
  echo "错误：未找到有效的签名证书。"
  exit 1
}

# 清理临时文件
echo "清理临时文件..."
rm -f signingCertificate.p12

echo "✅ 证书导入流程成功完成！"
```

## 总结

核心问题是您错误地设置了 GitHub Secrets 的值，将它们设置为变量名本身而不是实际的证书数据和配置信息。通过正确设置 Secrets 并使用优化后的脚本来进行更严格的错误检查，您的 iOS 构建流程应该能够正常工作。
