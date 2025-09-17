#!/bin/bash
set -euo pipefail

# 设置调试模式，帮助诊断问题
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
# set -x

# 确保环境变量存在
if [[ -z "${SIGNING_CERTIFICATE_P12_DATA:-}" ]]; then
  echo "错误：SIGNING_CERTIFICATE_P12_DATA 环境变量为空"
  exit 1
fi

# 创建和配置钥匙串 - 使用绝对路径
KEYCHAIN_PATH="$(pwd)/build.keychain"
security delete-keychain "$KEYCHAIN_PATH" || true
security create-keychain -p "" "$KEYCHAIN_PATH"
security list-keychains -s "$KEYCHAIN_PATH"
security default-keychain -s "$KEYCHAIN_PATH"
security unlock-keychain -p "" "$KEYCHAIN_PATH"
security set-keychain-settings -t 3600 "$KEYCHAIN_PATH"

# 解码证书
echo "$SIGNING_CERTIFICATE_P12_DATA" | base64 --decode > signingCertificate.p12

# 导入证书 - 使用更稳健的参数
# 如果密码环境变量不存在，使用空字符串
SECURITY_PASSWORD="${SIGNING_CERTIFICATE_PASSWORD:-}"
security import signingCertificate.p12 \
                -k "$KEYCHAIN_PATH" \
                -P "$SECURITY_PASSWORD" \
                -T /usr/bin/codesign \
                -T /usr/bin/security \
                -A

# 设置密钥分区列表
security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KEYCHAIN_PATH"

# 验证证书是否成功导入
security find-identity -v -p codesigning "$KEYCHAIN_PATH"

# 清理临时文件
rm -f signingCertificate.p12