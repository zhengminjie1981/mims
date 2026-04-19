# MIMS 全局安装脚本 (Windows PowerShell)
#
# 安装迷悟师 Skill + Agents 到 ~/.claude/ 和 ~/.agents/
# 安装一次，所有项目可用 /mims
#
# 用法：
#   iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
#
#   非交互模式（AI 代理适用）：
#   iex "& {$(Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1' -UseBasicParsing)} -Silent"

param(
    [switch]$Silent,
    [string]$Source = ""
)

$MIMS_VERSION = "1.2.0"
$GITHUB_ZIP = "https://github.com/zhengminjie1981/mims/archive/refs/tags/v$MIMS_VERSION.zip"
$GITLAB_ZIP = "https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/v$MIMS_VERSION/MIMS-v$MIMS_VERSION.zip"

$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$AGENTS_DIR = "$env:USERPROFILE\.agents"

Write-Host ""
Write-Host "MIMS v$MIMS_VERSION 全局安装" -ForegroundColor Cyan
Write-Host "迷悟师 - Make Idea Make Sense" -ForegroundColor Green
Write-Host ""

# 获取源文件
if ($Source -ne "") {
    $implDir = Join-Path $Source "impl"
    if (-not (Test-Path $implDir)) {
        Write-Host "错误：找不到 impl 目录：$implDir" -ForegroundColor Red; exit 1
    }
    Write-Host "ℹ 从本地安装：$Source" -ForegroundColor Blue
} else {
    $tempDir = Join-Path $env:TEMP "mims-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    Write-Host "ℹ 下载 MIMS v$MIMS_VERSION..." -ForegroundColor Blue
    $zipFile = Join-Path $tempDir "mims.zip"
    try {
        Invoke-WebRequest -Uri $GITHUB_ZIP -OutFile $zipFile -UseBasicParsing
    } catch {
        try {
            Invoke-WebRequest -Uri $GITLAB_ZIP -OutFile $zipFile -UseBasicParsing
        } catch {
            Write-Host "错误：下载失败" -ForegroundColor Red; exit 1
        }
    }
    Write-Host "✓ 下载完成" -ForegroundColor Green

    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
    $extractedDir = Get-ChildItem -Path $tempDir -Directory -Filter "mims-*" | Select-Object -First 1
    if (-not $extractedDir) {
        $extractedDir = Get-ChildItem -Path $tempDir -Directory -Filter "MIMS-*" | Select-Object -First 1
    }
    $implDir = Join-Path $extractedDir.FullName "impl"
}

if (-not (Test-Path (Join-Path $implDir ".claude\skills\mims\SKILL.md"))) {
    Write-Host "错误：找不到 Skill 文件" -ForegroundColor Red; exit 1
}

# 安装 Skill
$skillTarget = "$CLAUDE_DIR\skills\mims"
Write-Host "ℹ 安装 Skill → $skillTarget" -ForegroundColor Blue
New-Item -ItemType Directory -Path "$skillTarget\references" -Force | Out-Null
Copy-Item "$implDir\.claude\skills\mims\SKILL.md" "$skillTarget\SKILL.md" -Force
Copy-Item "$implDir\.claude\skills\mims\references\*" "$skillTarget\references\" -Force
Write-Host "✓ Skill 已安装" -ForegroundColor Green

# 安装 Agents
$agentsTarget = "$CLAUDE_DIR\agents"
Write-Host "ℹ 安装 Agents → $agentsTarget" -ForegroundColor Blue
New-Item -ItemType Directory -Path $agentsTarget -Force | Out-Null
Get-ChildItem "$implDir\.claude\agents\mims-*.md" | ForEach-Object {
    Copy-Item $_.FullName $agentsTarget -Force
}
Write-Host "✓ Agents 已安装" -ForegroundColor Green

# Codex 兼容
$codexSkillTarget = "$AGENTS_DIR\skills\mims"
$codexAgentsTarget = "$AGENTS_DIR\agents"
Write-Host "ℹ 安装 Codex 兼容 → $AGENTS_DIR" -ForegroundColor Blue
New-Item -ItemType Directory -Path "$codexSkillTarget\references" -Force | Out-Null
New-Item -ItemType Directory -Path $codexAgentsTarget -Force | Out-Null
Copy-Item "$skillTarget\SKILL.md" "$codexSkillTarget\SKILL.md" -Force
Copy-Item "$skillTarget\references\*" "$codexSkillTarget\references\" -Force
Copy-Item "$agentsTarget\mims-*.md" $codexAgentsTarget -Force
Write-Host "✓ Codex 兼容已安装" -ForegroundColor Green

# 完成
Write-Host ""
Write-Host "✓ MIMS v$MIMS_VERSION 全局安装完成" -ForegroundColor Green
Write-Host ""
Write-Host "安装位置："
Write-Host "  ~/.claude/skills/mims/     ← Skill + 知识库"
Write-Host "  ~/.claude/agents/          ← 子代理"
Write-Host "  ~/.agents/                 ← Codex 兼容"
Write-Host ""
Write-Host "使用方式："
Write-Host "  进入任意项目目录 → 输入 " -NoNewline
Write-Host "/mims" -ForegroundColor Green -NoNewline
Write-Host " 开始"
Write-Host ""
