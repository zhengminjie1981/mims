# MIMS v1.1.0 安装指南

> **快速、简单的安装体验** - 只需两步

---

## 安装方式

### 方式1：自动下载安装（推荐）⭐

**适合场景**：有公网访问

#### Windows PowerShell

```powershell
# 1. 进入项目目录
cd C:\your-project

# 2. 运行安装脚本
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))

# 3. 选择 "1. 自动下载安装（GitHub，推荐）"
```

#### Linux / macOS

```bash
# 1. 进入项目目录
cd /your-project

# 2. 运行安装脚本
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash

# 3. 选择 "1. 自动下载安装（GitHub，推荐）"
```

**安装过程**：
- ✅ 自动下载最新版本 zip
- ✅ 解压到当前目录
- ✅ 备份现有配置（如果有）
- ✅ 安装完成

**安装后的目录结构**：
```
your-project/
├── CLAUDE.md          # 迷悟师人设（加载到 Claude Code）
├── README.md          # 安装说明
├── USER_GUIDE.md      # 用户手册
├── .mims-version      # 版本标识
└── .claude/           # 核心实现
    ├── agents/        # 子代理
    │   ├── mims-validator.md
    │   └── mims-prototyper.md
    └── skills/mims/   # 工作流和知识库
        ├── SKILL.md
        └── references/
            ├── schema.md
            ├── schema-examples.md
            ├── prompt-ref.md
            ├── change-rules.md
            └── workflow-step0.5.md
```

---

### 方式2：手动下载安装

**适合场景**：内网环境、网络受限、或需要从 GitLab 下载

#### 步骤1：下载 zip 文件（任选其一）

**选项A：GitHub（公网，推荐）**
```
https://github.com/zhengminjie1981/mims/archive/refs/tags/v1.1.0.zip
```

**选项B：GitLab（企业内网）**
```
https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/v1.1.0/MIMS-v1.1.0.zip
```
*需要登录 GitLab*

#### 步骤2：运行安装脚本

**Windows PowerShell**：
```powershell
# 1. 进入项目目录
cd C:\your-project

# 2. 运行安装脚本
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))

# 3. 选择 "2. 手动下载安装"

# 4. 输入 zip 文件路径（例如）
# C:\Downloads\MIMS-v1.1.0.zip
```

**Linux / macOS**：
```bash
# 1. 进入项目目录
cd /your-project

# 2. 运行安装脚本
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash

# 3. 选择 "2. 手动下载安装"

# 4. 输入 zip 文件路径（例如）
# /home/user/Downloads/MIMS-v1.1.0.zip
```

**安装过程**：
- ✅ 提示输入 zip 文件路径
- ✅ 自动查找 Downloads 目录中的 zip
- ✅ 解压到当前目录
- ✅ 备份现有配置（如果有）
- ✅ 安装完成

---

## 安装后使用

### 1. 进入项目目录

```bash
cd /your-project
```

### 2. 启动 Claude Code

```bash
claude
```

### 3. 输入 MIMS 命令

```
/mims
```

应该看到：
```
╔════════════════════════════════════╗
║          迷悟师 - MIMS             ║
╚════════════════════════════════════╝

Make Idea Make Sense
让想法变得合理、清晰、可落地

命令列表：
  /mims:design      开始/继续设计流程
  /mims:model       查看当前域模型
  /mims:validate    验证模型完整性
  /mims:prototype   生成原型
  /mims:change      进入变更流程
```

### 4. 开始设计

```
/mims:design
```

---

## 常见问题

### Q1: 安装脚本报错"目录不存在"？

**原因**：目标目录不存在

**解决方案**：
```powershell
# 先创建目录
mkdir C:\your-project
cd C:\your-project

# 再运行安装脚本
```

### Q2: 安装到哪个目录？

**答案**：安装到**当前目录**

```powershell
# 查看当前目录
pwd

# 例如：C:\Users\zheng\Huaguoshan
# MIMS 会安装到这里
```

### Q3: 如何升级到新版本？

**方法**：重新运行安装脚本即可

```powershell
cd C:\your-project
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

脚本会：
- ✅ 自动检测已安装版本
- ✅ 提示是否升级
- ✅ 备份现有 `.claude/` 配置
- ✅ 安装新版本

### Q4: 升级后原有配置会丢失吗？

**答案**：不会，会自动备份

备份位置：`.claude.backup.时间戳/`

如需恢复：
```powershell
# 查看备份
dir .claude.backup.*

# 手动合并需要的文件
copy .claude.backup.20260330123456\skills\custom\* .claude\skills\ -recurse
```

### Q5: GitLab zip 下载很慢？

**解决方案**：使用 GitHub 源

GitHub 在国内访问速度通常更快，且无需登录。

### Q6: 找不到 /mims 命令？

**原因**：未在安装目录启动 Claude Code

**解决方案**：
```bash
# 确保在安装目录
cd C:\your-project  # 替换为实际安装目录

# 启动 Claude Code
claude

# 输入命令
/mims
```

---

## 获取帮助

- **用户手册**：安装后查看 `USER_GUIDE.md`
- **GitHub**：https://github.com/zhengminjie1981/mims
- **GitLab**：https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS

---

**安装愉快！** 🎉
