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
  echo "错误：证书文件解码失败"
  exit 1
fi

# 导入证书 - 优化参数格式
# 如果密码环境变量不存在，使用空字符串
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
  # 备选方法：不指定类型
  security import signingCertificate.p12 \
                  -k "$KEYCHAIN_PATH" \
                  -P "$SECURITY_PASSWORD" \
                  -T /usr/bin/codesign \
                  -T /usr/bin/security \
                  -A
}

# 设置密钥分区列表 - 修复参数格式问题
echo "设置密钥分区列表..."
security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KEYCHAIN_PATH" || {
  echo "密钥分区列表设置失败，尝试简化参数..."
  # 简化参数版本
  security set-key-partition-list -S apple-tool:,apple: -s -k "" -d "$KEYCHAIN_PATH"
}

# 验证证书是否成功导入
echo "验证证书是否成功导入..."
security find-identity -v -p codesigning "$KEYCHAIN_PATH"

# 清理临时文件
echo "清理临时文件..."
rm -f signingCertificate.p12

echo "证书导入流程完成！"