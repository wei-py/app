#!/bin/bash

set -euo pipefail

# 创建名为 build.keychain 的新钥匙串，密码为空
security create-keychain -p "" build.keychain
# 将新创建的钥匙串设置为搜索列表中的钥匙串
security list-keychains -s build.keychain
# 将其设置为默认钥匙串
security default-keychain -s build.keychain
# 解锁钥匙串（密码为空）
security unlock-keychain -p "" build.keychain
# 设置钥匙串为永不锁定
security set-keychain-settings
# 将Base64编码的证书数据解码并保存为 .p12 文件
echo $SIGNING_CERTIFICATE_P12_DATA | base64 --decode > signingCertificate.p12
security import signingCertificate.p12 \
                -f pkcs12 \
                -k build.keychain \
                -P $SIGNING_CERTIFICATE_PASSWORD \
                -T /usr/bin/codesign
# - -f pkcs12 : 指定文件格式为PKCS#12
# - -k build.keychain : 指定目标钥匙串
# - -P $SIGNING_CERTIFICATE_PASSWORD : 证书密码
# - -T /usr/bin/codesign : 允许codesign工具访问

# 设置钥匙串分区列表，允许Apple工具访问私钥
security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain