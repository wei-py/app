# Android 构建工作流学习指南

## 概述

这个文档详细解释了 `assemble_android_debug.yml` 和 `Fastfile` 是如何协同工作来构建 Android 应用的。

## 🔄 整体流程图

```
GitHub 触发事件 → GitHub Actions 工作流 → 环境准备 → Fastlane 执行 → APK 构建 → 上传产物
```

## 📋 详细执行步骤

### 1. GitHub Actions 工作流触发 (`assemble_android_debug.yml`)

#### 触发条件
```yaml
on:
  push:
    branches: [main]        # 推送到 main 分支时触发
    tags: [v*]             # 推送标签时触发（如 v1.0.0）
  pull_request:
    branches: [main]        # 向 main 分支提交 PR 时触发
  workflow_dispatch:        # 手动触发
```

#### 环境变量设置
```yaml
env:
  APP_ID: com.app2                    # 应用包名
  APP_NAME: Taro Demo                 # 应用名称
  BUILD_TYPE: debug                   # 构建类型
  VERSION_NAME: 1.0.0                 # 版本名称
  VERSION_CODE: 10                    # 版本号
  KEYSTORE_FILE: debug.keystore       # 签名文件
  KEYSTORE_PASSWORD: android          # 签名密码
  KEYSTORE_KEY_ALIAS: androiddebugkey # 签名别名
  KEYSTORE_KEY_PASSWORD: android      # 签名别名密码
```

### 2. 构建环境准备

#### 步骤 1: 检出代码
```yaml
- name: Checkout Project
  uses: actions/checkout@v2
```
- **作用**: 下载项目源代码到 GitHub Actions 运行器

#### 步骤 2: 设置 Java 环境
```yaml
- uses: actions/setup-java@v4
  with:
    distribution: "zulu"
    java-version: "17"
```
- **作用**: 安装 Java 17，Android 构建需要 Java 环境

#### 步骤 3: 设置 Node.js 和 pnpm
```yaml
- uses: pnpm/action-setup@v2
  with:
    version: 8
- uses: actions/setup-node@v3
  with:
    node-version: 20
    cache: "pnpm"
- run: pnpm install
```
- **作用**: 安装 Node.js 20 和 pnpm 8，安装前端依赖

#### 步骤 4: 设置 Ruby 环境
```yaml
- name: Setup Ruby
  uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.1'
    bundler-cache: true
    working-directory: android
```
- **作用**: 安装 Ruby 3.1，Fastlane 需要 Ruby 环境

#### 步骤 5: 缓存 Gradle
```yaml
- name: Cache Gradle
  uses: actions/cache@v4
  with:
    path: ~/.gradle
    key: ${{ runner.os }}-gradle
```
- **作用**: 缓存 Gradle 依赖，加速后续构建

#### 步骤 6: 安装 Ruby 依赖
```yaml
- name: Install Ruby dependencies
  working-directory: android
  run: |
    gem install bundler
    bundle config set --local deployment 'false'
    bundle config set --local path 'vendor/bundle'
    bundle install --retry=3 --jobs=4
```
- **作用**: 安装 Fastlane 和其他 Ruby 依赖

### 3. 执行 Fastlane 构建

#### 步骤 7: 运行 Fastlane
```yaml
- name: Assemble Android debug
  working-directory: android
  run: bundle exec fastlane assemble
```
- **作用**: 执行 Fastlane 的 `assemble` lane，开始实际的 Android 构建

### 4. Fastlane 执行详解 (`Fastfile`)

#### Fastlane 配置结构
```ruby
default_platform(:android)  # 默认平台为 Android

platform :android do
  desc "assemble"
  lane :assemble do
    # 具体构建步骤
  end
end
```

#### 构建步骤详解

##### 4.1 更新应用名称
```ruby
update_android_strings(
  xml_path: 'app/src/main/res/values/strings.xml',
  block: lambda { |strings|
    strings['app_name'] = ENV['APP_NAME']  # 从环境变量获取应用名称
  }
)
```
- **作用**: 动态更新 `strings.xml` 中的应用名称

##### 4.2 执行 Gradle 构建
```ruby
gradle(
  task: "assemble",                    # 执行 assemble 任务
  build_type: ENV['BUILD_TYPE'],       # 构建类型 (debug)
  properties: {
    "app_id" => ENV['APP_ID'],                                    # 应用包名
    "android.injected.version.code" => ENV['VERSION_CODE'].to_i,  # 版本号
    "android.injected.version.name" => ENV['VERSION_NAME'],       # 版本名称
    "android.injected.signing.store.file" => ENV['KEYSTORE_FILE'], # 签名文件
    "android.injected.signing.store.password" => ENV['KEYSTORE_PASSWORD'], # 签名密码
    "android.injected.signing.key.alias" => ENV['KEYSTORE_KEY_ALIAS'],     # 签名别名
    "android.injected.signing.key.password" => ENV['KEYSTORE_KEY_PASSWORD'], # 别名密码
  }
)
```
- **作用**: 执行实际的 Android 构建，生成 APK 文件

### 5. 构建产物处理

#### 步骤 8: 上传构建产物
```yaml
- name: Upload Android Products
  uses: actions/upload-artifact@v4
  with:
    name: app-debug
    path: android/app/build/outputs/apk/debug/app-debug.apk
```
- **作用**: 将生成的 APK 文件上传为 GitHub Actions 产物

#### 步骤 9: 发布到 Release（仅标签触发时）
```yaml
- name: Upload release assets
  uses: softprops/action-gh-release@v1
  if: startsWith(github.ref, 'refs/tags/')
  with:
    prerelease: ${{ contains(github.ref, 'beta') }}
    files: android/app/build/outputs/apk/debug/app-debug.apk
```
- **作用**: 如果是标签触发，将 APK 附加到 GitHub Release

## 🔧 关键技术点

### 1. 环境变量传递
- GitHub Actions 环境变量 → Fastlane 环境变量 → Gradle 属性
- 实现了配置的统一管理和动态注入

### 2. 缓存策略
- **Gradle 缓存**: 缓存 `~/.gradle` 目录
- **Bundle 缓存**: 通过 `bundler-cache: true` 自动缓存
- **pnpm 缓存**: 通过 `cache: "pnpm"` 自动缓存

### 3. 错误处理
- Bundle 安装使用 `--retry=3` 重试机制
- 并行安装使用 `--jobs=4` 提高效率

### 4. 工作目录管理
- 使用 `working-directory: android` 避免 `cd` 命令
- 保持步骤的独立性和可读性

## 🚀 执行流程总结

1. **触发**: 代码推送/PR/手动触发
2. **准备**: 设置 Java、Node.js、Ruby 环境
3. **依赖**: 安装前端和 Ruby 依赖
4. **构建**: Fastlane 调用 Gradle 构建 APK
5. **签名**: 使用指定的 keystore 对 APK 签名
6. **上传**: 将 APK 上传为产物或发布到 Release

## 📚 学习要点

1. **GitHub Actions**: CI/CD 流水线的编排和执行
2. **Fastlane**: 移动应用构建自动化工具
3. **Gradle**: Android 项目的构建系统
4. **环境变量**: 配置管理和参数传递
5. **缓存机制**: 提高构建效率的关键技术

这个工作流实现了从源代码到可分发 APK 的完全自动化构建流程！
