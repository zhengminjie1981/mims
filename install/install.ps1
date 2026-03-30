# MIMS 一键安装脚本 (Windows PowerShell)
#
# 用法：
#   iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
#
#   或指定安装目录：
#   .\install.ps1 -TargetDir "C:\your-project"
#
#   或从本地 zip 文件安装：
#   .\install.ps1 -ZipFile "C:\Downloads\MIMS-v1.1.0.zip"

param(
    [string]$TargetDir = "",
    [string]$ZipFile = ""
)

# 版本配置
$MIMS_VERSION = "1.1.0"
$GITHUB_ZIP = "https://github.com/zhengminjie1981/mims/archive/refs/tags/v$MIMS_VERSION.zip"
$GITLAB_ZIP = "https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/v$MIMS_VERSION/MIMS-v$MIMS_VERSION.zip"

# 颜色输出函数
function Write-Info { param($msg) Write-Host "ℹ " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function Write-Success { param($msg) Write-Host "✓ " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warning { param($msg) Write-Host "⚠ " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Error { param($msg) Write-Host "✗ " -ForegroundColor Red -NoNewline; Write-Host $msg; exit 1 }

# 欢迎信息
Clear-Host
Write-Host ""
Write-Host "╔════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     MIMS v$MIMS_VERSION 安装程序     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "迷悟师 — " -NoNewline
Write-Host "Make Idea Make Sense" -ForegroundColor Green
Write-Host "通过对话帮助非技术用户完成软件设计"
Write-Host ""

# 检查 Claude Code
Write-Info "检查 Claude Code..."
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Host ""
    Write-Warning "未检测到 Claude Code CLI"
    Write-Host ""
    Write-Host "请先安装 Claude Code："
    Write-Host "  https://claude.ai/code" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
$version = & claude --version 2>$null | Select-Object -First 1
Write-Success "Claude Code 已安装（$version）"
Write-Host ""

# 确定目标目录
if ($TargetDir -eq "") {
    $TargetDir = Get-Location
}
Write-Info "安装目录：$TargetDir"
Write-Host ""

# 检查目标目录是否存在
if (-not (Test-Path $TargetDir)) {
    Write-Error "目录不存在：$TargetDir"
}

# 检查是否已安装
$versionFile = Join-Path $TargetDir ".mims-version"
if (Test-Path $versionFile) {
    $currentVersion = Get-Content $versionFile | Select-Object -First 1
    Write-Warning "检测到已安装 MIMS v$currentVersion"
    Write-Host ""
    $response = Read-Host "是否升级到 v$MIMS_VERSION？(y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Info "开始升级..."
    } else {
        Write-Info "安装已取消"
        exit 0
    }
    Write-Host ""
}

# 选择安装方式
Write-Host "请选择安装方式：" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. 自动下载安装（GitHub，推荐）" -ForegroundColor Green
Write-Host "     • 自动下载 zip 并安装到当前目录"
Write-Host "     • 需要公网访问"
Write-Host ""
Write-Host "  2. 手动下载安装" -ForegroundColor Yellow
Write-Host "     • 从 GitLab 或 GitHub 手动下载 zip"
Write-Host "     • 适合内网环境或网络受限场景"
Write-Host ""
$choice = Read-Host "请输入 1 或 2"

if ($choice -eq "1") {
    # 方式1：自动下载安装
    Write-Host ""
    Write-Info "从 GitHub 下载 MIMS v$MIMS_VERSION..."

    $tempDir = Join-Path $env:TEMP "mims-install-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $zipPath = Join-Path $tempDir "mims.zip"

    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        Invoke-WebRequest -Uri $GITHUB_ZIP -OutFile $zipPath -UseBasicParsing
        Write-Success "下载完成"
    } catch {
        Write-Error "下载失败：$_`n请检查网络连接或使用手动安装方式"
    }

} elseif ($choice -eq "2") {
    # 方式2：手动下载安装
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│               手动下载安装指引                       │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "下载链接（任选其一）：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  GitHub（公网，推荐）：" -ForegroundColor Green
    Write-Host "    $GITHUB_ZIP" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  GitLab（企业内网）：" -ForegroundColor Yellow
    Write-Host "    $GITLAB_ZIP" -ForegroundColor Cyan
    Write-Host "    （需要登录 GitLab）"
    Write-Host ""
    Write-Host "步骤：" -ForegroundColor Yellow
    Write-Host "  1. 点击上面其中一个链接，或在浏览器中复制打开"
    Write-Host "  2. 下载 zip 文件到任意位置"
    Write-Host "  3. 记住下载路径（如 C:\Downloads\MIMS-v1.1.0.zip）"
    Write-Host "  4. 回到此窗口继续"
    Write-Host ""

    # 如果已指定 zip 文件
    if ($ZipFile -ne "" -and (Test-Path $ZipFile)) {
        Write-Success "使用指定的 zip 文件：$ZipFile"
        $zipPath = $ZipFile
    } else {
        Read-Host "下载完成后按 Enter 继续"

        # 查找下载的 zip 文件
        Write-Host ""
        Write-Info "查找下载的 zip 文件..."

        $downloadsDir = if ($env:USERPROFILE) {
            Join-Path $env:USERPROFILE "Downloads"
        } elseif ($env:HOME) {
            Join-Path $env:HOME "Downloads"
        } else {
            "/tmp"
        }

        # 查找匹配的 zip 文件
        $zipCandidates = Get-ChildItem -Path $downloadsDir -Filter "*.zip" -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -match "MIMS-v?$MIMS_VERSION|mims-v?$MIMS_VERSION" } |
                        Sort-Object LastWriteTime -Descending |
                        Select-Object -First 3

        if ($zipCandidates) {
            Write-Host ""
            Write-Host "找到以下 zip 文件：" -ForegroundColor Green
            for ($i = 0; $i -lt $zipCandidates.Count; $i++) {
                Write-Host "  $($i+1). $($zipCandidates[$i].FullName)" -ForegroundColor Cyan
                Write-Host "     修改时间：$($zipCandidates[$i].LastWriteTime)" -ForegroundColor Gray
            }
            Write-Host ""

            if ($zipCandidates.Count -eq 1) {
                $zipPath = $zipCandidates[0].FullName
                Write-Success "自动选择：$zipPath"
            } else {
                $selection = Read-Host "请选择文件（1-$($zipCandidates.Count)）"
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $zipCandidates.Count) {
                    $zipPath = $zipCandidates[$index].FullName
                    Write-Success "已选择：$zipPath"
                } else {
                    Write-Error "无效选择"
                }
            }
        } else {
            # 手动输入路径
            Write-Host ""
            Write-Warning "未在 Downloads 目录找到 zip 文件"
            Write-Host "请输入 zip 文件的完整路径："
            Write-Host "（可以直接拖拽文件到此窗口）" -ForegroundColor Gray
            $manualPath = Read-Host

            # 移除引号
            $manualPath = $manualPath.Trim('"').Trim("'")

            if (-not (Test-Path $manualPath)) {
                Write-Error "文件不存在：$manualPath"
            }

            $zipPath = $manualPath
            Write-Success "已选择：$zipPath"
        }
    }

    Write-Host ""
} else {
    Write-Error "无效选择：$choice"
}

# 解压和安装
Write-Host ""
Write-Info "解压文件..."

$tempDir = if ($choice -eq "1") { $tempDir } else { Join-Path $env:TEMP "mims-install-$(Get-Date -Format 'yyyyMMddHHmmss')" }
if ($choice -eq "2") {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

try {
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    Write-Success "解压完成"
} catch {
    Write-Error "解压失败：$_"
}

# 查找解压后的目录
$extractedDir = Get-ChildItem -Path $tempDir -Directory |
                Where-Object { $_.Name -like "MIMS-*" -or $_.Name -eq "mims-*" } |
                Select-Object -First 1

if (-not $extractedDir) {
    Write-Error "发布包格式错误：找不到 MIMS 目录"
}

# 备份现有配置
$claudeDir = Join-Path $TargetDir ".claude"
$backupDir = $null

if (Test-Path $claudeDir) {
    Write-Host ""
    Write-Info "备份现有配置..."
    $backupDir = Join-Path $TargetDir ".claude.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Move-Item -Path $claudeDir -Destination $backupDir
    Write-Success "已备份到：$backupDir"
}

# 安装文件
Write-Host ""
Write-Info "安装文件..."

$implDir = Join-Path $extractedDir.FullName "impl"
if (-not (Test-Path $implDir)) {
    Write-Error "发布包格式错误：缺少 impl 目录"
}

# 复制所有文件到目标目录
Get-ChildItem -Path $implDir -Force | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $TargetDir -Recurse -Force
}

Write-Success "核心文件已安装"

# 创建版本文件
$versionContent = @"
$MIMS_VERSION
source: manual
repo: https://github.com/zhengminjie1981/mims
installed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
$versionContent | Out-File -FilePath $versionFile -Encoding utf8
Write-Success "版本标识已创建"

# 清理临时文件
if ($choice -eq "1" -or $choice -eq "2") {
    try {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
}

# 完成
Write-Host ""
Write-Host "╔════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         ✓ 安装完成！              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "已安装版本：v$MIMS_VERSION"
Write-Host "安装目录：$TargetDir"
Write-Host ""
Write-Host "安装的文件：" -ForegroundColor Cyan
Write-Host "  ├── CLAUDE.md          # 迷悟师人设（加载到 Claude Code）"
Write-Host "  ├── README.md          # 安装说明"
Write-Host "  ├── USER_GUIDE.md      # 用户手册"
Write-Host "  ├── .mims-version      # 版本标识"
Write-Host "  └── .claude/           # 核心实现"
Write-Host "      ├── agents/        # 子代理"
Write-Host "      └── skills/mims/   # 工作流和知识库"
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "  1. cd $TargetDir"
Write-Host "  2. claude"
Write-Host "  3. 输入 " -NoNewline
Write-Host "/mims" -ForegroundColor Green -NoNewline
Write-Host " 开始使用"
Write-Host ""
Write-Host "文档：" -ForegroundColor Cyan
Write-Host "  • 用户手册：$TargetDir\USER_GUIDE.md"
Write-Host "  • GitHub：https://github.com/zhengminjie1981/mims"
Write-Host ""

# 备份提示
if ($backupDir) {
    Write-Warning "备份目录：$backupDir"
    Write-Host "  如需恢复自定义配置，请手动合并以下文件："
    Write-Host "  • .claude\agents\ 中的自定义子代理"
    Write-Host "  • .claude\skills\ 中的自定义技能"
    Write-Host ""
}

Write-Host "安装完成！祝您使用愉快！ 🎉" -ForegroundColor Green
Write-Host ""
