# iOS 构建所需的密钥信息

以下是 GitHub Actions 工作流 `assemble_ios_debug.yml` 中使用的密钥信息，需要在 GitHub 仓库的 Secrets 中配置。

## 应用信息

| 密钥名称 | 说明 | 示例值 |
|---------|------|--------|
| `APP_ID` | 应用标识符 | com.bto.Light |
| `TEAM_ID` | 开发者团队 ID | 从 Apple Developer 账户获取 |

## 证书信息

根据截图，证书信息如下：

| 密钥名称 | 说明 | 示例值/获取方式 |
|---------|------|----------------|
| `DEBUG_SIGNING_CERTIFICATE_P12_DATA` | 开发证书的 P12 文件（Base64 编码） | 从 Mac 的钥匙串访问导出证书，转为 Base64 |
| `DEBUG_SIGNING_CERTIFICATE_PASSWORD` | P12 文件的密码 | 导出证书时设置的密码 |
| `CODE_SIGN_IDENTITY` | 签名身份 | "Apple Development" |

证书详情：
- 证书名称：Yiliang Liao
- 证书类型：Development
- 过期日期：2026/09/19
- 创建者：Yiliang Liao (info@btosolar.com)

## 配置文件信息

| 密钥名称 | 说明 | 示例值/获取方式 |
|---------|------|----------------|
| `DEBUG_PROVISIONING_PROFILE_SPECIFIER` | 配置文件名称 | BTOLIGHTDev |
| `DEBUG_PROVISIONING_PROFILE_DATA` | 配置文件内容（Base64 编码） | 从 Apple Developer 下载配置文件，转为 Base64 |

配置文件详情：
- 名称：BTOLIGHTDev
- 状态：Active
- 平台：iOS
- 类型：Development
- 过期日期：2026/09/20
- 启用功能：In-App Purchase
- 应用 ID：BTOLIGHT (com.bto.Light)
- 设备数量：13 个

## 如何获取这些值

1. **APP_ID**：从 Apple Developer 账户的 Identifiers 部分获取
2. **TEAM_ID**：从 Apple Developer 账户的 Membership 部分获取
3. **证书 P12 文件**：
   - 从 Apple Developer 下载证书
   - 在 Mac 的钥匙串访问中导出为 P12 文件
   - 使用以下命令转为 Base64：`base64 -i certificate.p12 | pbcopy`
4. **配置文件**：
   - 从 Apple Developer 下载配置文件（.mobileprovision）
   - 使用以下命令转为 Base64：`base64 -i profile.mobileprovision | pbcopy`

## 在 GitHub 中设置这些密钥

1. 进入 GitHub 仓库
2. 点击 Settings > Secrets and variables > Actions
3. 点击 "New repository secret"
4. 添加上述所有密钥