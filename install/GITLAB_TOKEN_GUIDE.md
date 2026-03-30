# GitLab Private Token 获取指南

## 为什么需要 Token？

企业 GitLab 仓库的文件下载需要认证。安装脚本访问 GitLab 时需要提供 Private Token 进行身份验证。

## 获取步骤

### 1. 登录 GitLab

访问：https://gitlab.xyitech.com

使用您的企业账号登录。

### 2. 进入 Access Tokens 页面

1. 点击右上角头像
2. 选择 **Settings** (设置)
3. 左侧菜单选择 **Access Tokens** (访问令牌)

### 3. 创建新 Token

填写以下信息：

| 字段 | 值 |
|------|---|
| **Name** | `MIMS-Install` 或其他易识别名称 |
| **Expiration date** | 建议设置 30 天 |
| **Select scopes** | 勾选以下权限： |
| | ✅ `read_api` - 读取 API |
| | ✅ `read_repository` - 读取仓库 |

### 4. 复制 Token

⚠️ **重要**：Token 只显示一次，请立即复制保存！

点击 **Create personal access token** 后，页面会显示生成的 Token（格式：`glpat-xxxxxxxxxxxxxxxxxxxx`）。

### 5. 使用 Token 安装

**方式1：交互式输入**（推荐）
```powershell
# 运行脚本，按提示选择 GitLab 并输入 Token
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

**方式2：命令行参数**
```powershell
# 先下载脚本
$script = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1" -UseBasicParsing

# 执行时传入 Token
$token = "glpat-your-token-here"
Invoke-Expression "$($script.Content) -GitLabToken `$token"
```

**方式3：从 GitHub 下载（推荐）**
```powershell
# 使用 GitHub 安装脚本（无需 Token，自动检测网络）
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

## Token 权限说明

| 权限 | 用途 | 必需 |
|------|------|------|
| `read_api` | 读取仓库信息 | ✅ 是 |
| `read_repository` | 下载文件 | ✅ 是 |
| `write_repository` | 写入仓库 | ❌ 否 |
| `api` | 完整 API 访问 | ❌ 否（权限过大） |

## 安全建议

1. ✅ **最小权限原则**：只勾选必需的权限
2. ✅ **设置过期时间**：建议 7-30 天
3. ✅ **妥善保管**：Token 等同于密码，不要分享或提交到代码库
4. ✅ **定期轮换**：定期删除旧 Token，创建新 Token
5. ✅ **用后即焚**：如果 Token 泄露，立即到 Settings → Access Tokens 删除

## 常见问题

### Q1: Token 忘记了怎么办？
A: Token 只显示一次。如果忘记了，删除旧 Token，重新创建一个新的。

### Q2: Token 泄露了怎么办？
A: 立即到 Settings → Access Tokens 页面，点击 Token 旁边的 **Revoke** 按钮撤销。

### Q3: 可以不使用 Token 吗？
A: 可以。推荐使用 GitHub 安装脚本（无需认证）：
```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

### Q4: 为什么 GitHub 不需要 Token？
A: GitHub 仓库是公开的，无需认证即可访问。安装脚本会自动检测网络环境，选择最快的下载源。

## 相关链接

- GitLab 官方文档：https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html
- MIMS 安装指南：`install/README.md`
