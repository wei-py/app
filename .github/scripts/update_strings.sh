#!/bin/bash
set -e

# 从环境变量获取值（兼容你的 GitHub Actions env）
APP_NAME="${APP_NAME:-Taro Demo}"
VERSION_NAME="${VERSION_NAME:-1.0.0}"

STRINGS_FILE="android/app/src/main/res/values/strings.xml"

echo "🔄 Updating strings.xml with APP_NAME=$APP_NAME, VERSION_NAME=$VERSION_NAME"

# 替换 app_name
if grep -q '<string name="app_name">' "$STRINGS_FILE"; then
    sed -i "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">${APP_NAME}</string>|g" "$STRINGS_FILE"
    echo "✅ Updated app_name to: $APP_NAME"
else
    echo "⚠️  <string name=\"app_name\"> not found, adding it..."
    sed -i '/<resources>/a\    <string name="app_name">'${APP_NAME}'</string>' "$STRINGS_FILE"
fi

# 替换 version_name（可选）
if grep -q '<string name="version_name">' "$STRINGS_FILE"; then
    sed -i "s|<string name=\"version_name\">.*</string>|<string name=\"version_name\">${VERSION_NAME}</string>|g" "$STRINGS_FILE"
    echo "✅ Updated version_name to: $VERSION_NAME"
else
    echo "⚠️  <string name=\"version_name\"> not found, adding it..."
    sed -i '/<resources>/a\    <string name="version_name">'${VERSION_NAME}'</string>' "$STRINGS_FILE"
fi

echo "📄 Final strings.xml:"
cat "$STRINGS_FILE"