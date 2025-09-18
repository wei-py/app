# Taro React Native Template

## Requirements

0. taro: `@tarojs/cli@^3.5.0`
1. framework: 'react'

## Quick Start

### Install React Native Libraries
> Install peerDependencies of `@tarojs/taro-rn` `@tarojs/components-rn` and `@tarojs/router-rn`, which will also run `post-install`. When you change the Taro version, please modify and run the `upgradePeerdeps` script.
> 
> **Run this script after project initialization.**

`pnpm upgradePeerdeps`

### Install Pod
> Run this script when you add new React Native libraries or update React Native library versions.
> 
> Check [pod-install](https://www.npmjs.com/package/pod-install) for more information.

`pnpm podInstall`

### Start iOS App

`pnpm ios`

### Start Android App

`pnpm android`

### Start Packager

`pnpm start`

### More Information

0. [Taro React Native Development Process](https://docs.taro.zone/docs/next/react-native)
1. [GitHub](https://github.com/NervJS/taro)

## Release

### Build iOS Package

`pnpm build:rn --platform ios`

### Build Android Package

`pnpm build:rn --platform android`

### Publish iOS App

See [Publishing to App Store](https://reactnative.dev/docs/publishing-to-app-store) for details.

### Publish Android APK

See [Generating Signed APK](https://reactnative.dev/docs/signed-apk-android) for details.

## GitHub Workflows
> Use GitHub Actions to build your app. This template includes basic GitHub Action configurations.

See [.github/workflows](.github/workflows) for details.

### Events

By default, we build debug and release products for Android and iOS when you push or pull request to master branch. Design your own workflow by modifying [.github/workflows](.github/workflows) files.

See [Events that trigger workflows](https://docs.github.com/en/actions/reference/events-that-trigger-workflows)

### iOS

#### Configuration

Modify the following configurations to package and publish your app.

> [.github/workflows/assemble_ios_debug.yml](.github/workflows/assemble_ios_debug.yml)
> [.github/workflows/assemble_ios_release.yml](.github/workflows/assemble_ios_release.yml)

---

# Taro React Native 模板

## 要求

0. taro: `@tarojs/cli@^3.5.0`
1. 框架: 'react'

## 快速开始

### 安装 React Native 库
> 安装 `@tarojs/taro-rn` `@tarojs/components-rn` 和 `@tarojs/router-rn` 的 peerDependencies，这也会运行 `post-install`。当你更改 Taro 版本时，请修改并运行 `upgradePeerdeps` 脚本。
> 
> **在项目初始化后运行此脚本。**

`pnpm upgradePeerdeps`

### 安装 Pod
> 当你添加新的 React Native 库或更新 React Native 库版本时运行此脚本。
> 
> 查看 [pod-install](https://www.npmjs.com/package/pod-install) 获取更多信息。

`pnpm podInstall`

### 启动 iOS 应用

`pnpm ios`

### 启动 Android 应用

`pnpm android`

### 启动打包器

`pnpm start`

### 更多信息

0. [Taro React Native 开发流程](https://docs.taro.zone/docs/next/react-native)
1. [GitHub](https://github.com/NervJS/taro)

## 发布

### 构建 iOS 包

`pnpm build:rn --platform ios`

### 构建 Android 包

`pnpm build:rn --platform android`

### 发布 iOS 应用

查看 [发布到 App Store](https://reactnative.cn/docs/publishing-to-app-store) 获取详细信息。

### 发布 Android APK

查看 [生成已签名的 APK](https://reactnative.cn/docs/signed-apk-android) 获取详细信息。

## GitHub 工作流
> 使用 GitHub Actions 构建你的应用。此模板包含基本的 GitHub Action 配置。

查看 [.github/workflows](.github/workflows) 获取详细信息。

### 事件

默认情况下，当你推送或在 master 分支上发起拉取请求时，我们会为 Android 和 iOS 构建调试版和发布版产品。通过修改 [.github/workflows](.github/workflows) 文件来设计你自己的工作流。

查看 [触发工作流的事件](https://docs.github.com/en/actions/reference/events-that-trigger-workflows)

### iOS

#### 配置

修改以下配置项以打包和发布你的应用。

> [.github/workflows/assemble_ios_debug.yml](.github/workflows/assemble_ios_debug.yml)
> [.github/workflows/assemble_ios_release.yml](.github/workflows/assemble_ios_release.yml)
