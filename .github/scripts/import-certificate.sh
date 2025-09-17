#!/bin/bash
set -euo pipefail

# 创建和配置钥匙串
security create-keychain -p "" build.keychain
security list-keychains -s build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "" build.keychain
security set-keychain-settings -t 3600 -l ~/Library/Keychains/build.keychain

# 确保环境变量存在
if [[ -z "${SIGNING_CERTIFICATE_P12_DATA}" ]]; then
  echo "错误：SIGNING_CERTIFICATE_P12_DATA 环境变量为空"
  exit 1
fi

if [[ -z "${SIGNING_CERTIFICATE_PASSWORD}" ]]; then
  echo "警告：SIGNING_CERTIFICATE_PASSWORD 环境变量为空"
  # 如果密码为空，使用空字符串
  SIGNING_CERTIFICATE_PASSWORD=""
fi

# 解码并导入证书
echo "$SIGNING_CERTIFICATE_P12_DATA" | base64 --decode > signingCertificate.p12

# 修改导入命令，添加额外的参数以提高兼容性
security import signingCertificate.p12 \
                -f pkcs12 \
                -k build.keychain \
                -P "$SIGNING_CERTIFICATE_PASSWORD" \
                -A \
                -T /usr/bin/codesign \
                -T /usr/bin/xcrun \
                -T /usr/bin/productbuild

# 设置密钥分区列表
security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

# 清理临时文件
rm -f signingCertificate.p12