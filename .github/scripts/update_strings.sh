#!/bin/bash
set -e

# 从环境变量获取值（兼容你的 GitHub Actions env）
APP_NAME="${APP_NAME:-Taro Demo}"
VERSION_NAME="${VERSION_NAME:-1.0.0}"
VERSION_CODE="${VERSION_CODE:-1}"
APP_ID="${APP_ID:-com.app}"

STRINGS_FILE="android/app/src/main/res/values/strings.xml"
GRADLE_PROPERTIES_FILE="android/gradle.properties"

# 备份原始文件
cp $GRADLE_PROPERTIES_FILE $GRADLE_PROPERTIES_FILE.bak 2>/dev/null || true

# 创建或更新gradle.properties文件
cat > $GRADLE_PROPERTIES_FILE << EOL
# 从GitHub Actions环境变量生成的配置
# 此文件由update_strings.sh脚本自动生成
appId=${APP_ID}
versionCode=${VERSION_CODE}
versionName=${VERSION_NAME}
EOL

# 追加原始文件中不存在的配置
if [ -f $GRADLE_PROPERTIES_FILE.bak ]; then
    grep -v -f $GRADLE_PROPERTIES_FILE $GRADLE_PROPERTIES_FILE.bak >> $GRADLE_PROPERTIES_FILE
    rm $GRADLE_PROPERTIES_FILE.bak
fi

echo "🔄 Created gradle.properties with appId=$APP_ID, versionCode=$VERSION_CODE, versionName=$VERSION_NAME"

# 替换 app_name
if grep -q '<string name="app_name">' "$STRINGS_FILE"; then
    sed -i "s|<string name="app_name">.*</string>|<string name="app_name">${APP_NAME}</string>|g" "$STRINGS_FILE"
    echo "✅ Updated app_name to: $APP_NAME"
else
    echo "⚠️  <string name="app_name"> not found, adding it..."
    sed -i '/<resources>/a\    <string name="app_name">'${APP_NAME}'</string>' "$STRINGS_FILE"
fi

# 替换 version_name（可选）
if grep -q '<string name="version_name">' "$STRINGS_FILE"; then
    sed -i "s|<string name="version_name">.*</string>|<string name="version_name">${VERSION_NAME}</string>|g" "$STRINGS_FILE"
    echo "✅ Updated version_name to: $VERSION_NAME"
else
    echo "⚠️  <string name="version_name"> not found, adding it..."
    sed -i '/<resources>/a\    <string name="version_name">'${VERSION_NAME}'</string>' "$STRINGS_FILE"
fi

echo "📄 Final strings.xml:"
cat "$STRINGS_FILE"

echo "📄 Final gradle.properties:"
cat "$GRADLE_PROPERTIES_FILE"