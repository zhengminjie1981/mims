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

$MIMS_VERSION = "1.4"
$GITHUB_ZIP = "https://github.com/zhengminjie1981/mims/archive/refs/tags/v$MIMS_VERSION.zip"
$GITLAB_ZIP = "https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/v$MIMS_VERSION/MIMS-v$MIMS_VERSION.zip"
$GITHUB_MAIN_ZIP = "https://github.com/zhengminjie1981/mims/archive/refs/heads/main.zip"
$GITLAB_MAIN_ZIP = "https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/main/MIMS-main.zip"

$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$AGENTS_DIR = "$env:USERPROFILE\.agents"
$MIMS_HOME = "$env:USERPROFILE\.mims"
$STATE_FILE = "$MIMS_HOME\install-state.json"

function Get-MimsInstalledVersion {
    param([string]$SkillPath)
    $versionFile = Join-Path (Split-Path (Split-Path $SkillPath -Parent) -Parent) ".mims-version"
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    if (Test-Path $SkillPath) {
        $content = Get-Content $SkillPath -Raw
        if ($content -match 'version:\s*"([^"]+)"') { return $matches[1] }
    }
    return "unknown"
}

function Get-ExistingMimsSkillDirs {
    param([string]$SkillsPath)
    if (-not (Test-Path $SkillsPath)) { return @() }
    return @(Get-ChildItem -Path $SkillsPath -Directory -Filter "mims*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "mims" })
}

function Get-ExistingMimsAgents {
    param([string]$AgentsPath)
    if (-not (Test-Path $AgentsPath)) { return @() }
    return @(Get-ChildItem -Path $AgentsPath -Filter "mims-*.md" -File -ErrorAction SilentlyContinue)
}

function Get-ExistingMimsReferences {
    param([string]$ReferencesPath)
    if (-not (Test-Path $ReferencesPath)) { return @() }
    return @(Get-ChildItem -Path $ReferencesPath -File -ErrorAction SilentlyContinue)
}

function Get-PackageFileNames {
    param(
        [string]$Path,
        [string]$Filter
    )
    if (-not (Test-Path $Path)) { return @() }
    return @(Get-ChildItem -Path $Path -Filter $Filter -File -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
}

function Add-MimsIssue {
    param(
        [System.Collections.ArrayList]$Issues,
        [string]$Message
    )
    [void]$Issues.Add($Message)
}

function Get-MimsPreflightState {
    param(
        [string]$PackageDir,
        [string]$ExistingClaudeVersion,
        [string]$ExistingCodexVersion,
        [string[]]$ProjectMarkers
    )

    $issues = New-Object System.Collections.ArrayList
    $packageAgents = Get-PackageFileNames -Path (Join-Path $PackageDir ".claude\agents") -Filter "mims-*.md"
    $packageReferences = Get-PackageFileNames -Path (Join-Path $PackageDir ".claude\skills\mims\references") -Filter "*"

    if ($ExistingClaudeVersion -ne "none" -and $ExistingCodexVersion -ne "none" -and $ExistingClaudeVersion -ne $ExistingCodexVersion) {
        Add-MimsIssue $issues "Claude Code 全局版本 ($ExistingClaudeVersion) 与 Codex 全局版本 ($ExistingCodexVersion) 不一致。"
    }
    if (($ExistingClaudeVersion -eq "none" -and $ExistingCodexVersion -ne "none") -or ($ExistingClaudeVersion -ne "none" -and $ExistingCodexVersion -eq "none")) {
        Add-MimsIssue $issues "检测到 Claude Code / Codex 仅一端存在 MIMS，全局安装可能不完整。"
    }

    $requiredChecks = @(
        "$CLAUDE_DIR\skills\mims\SKILL.md",
        "$CLAUDE_DIR\skills\mims\references\schema-contract.md",
        "$CLAUDE_DIR\skills\mims\references\schema.md",
        "$CLAUDE_DIR\agents\mims-validator.md",
        "$AGENTS_DIR\skills\mims\SKILL.md",
        "$AGENTS_DIR\skills\mims\references\schema-contract.md",
        "$AGENTS_DIR\skills\mims\references\schema.md",
        "$AGENTS_DIR\agents\mims-validator.md"
    )
    $hasExistingInstall = ($ExistingClaudeVersion -ne "none" -or $ExistingCodexVersion -ne "none")
    if ($hasExistingInstall) {
        foreach ($check in $requiredChecks) {
            if (-not (Test-Path $check)) { Add-MimsIssue $issues "缺少全局安装文件：$check" }
        }
    }

    foreach ($skillDir in @($CLAUDE_DIR, $AGENTS_DIR)) {
        foreach ($duplicateSkill in (Get-ExistingMimsSkillDirs (Join-Path $skillDir "skills"))) {
            Add-MimsIssue $issues "发现重复全局 Skill：$($duplicateSkill.FullName)"
        }
    }

    foreach ($agentDir in @("$CLAUDE_DIR\agents", "$AGENTS_DIR\agents")) {
        foreach ($agent in (Get-ExistingMimsAgents $agentDir)) {
            if ($packageAgents -notcontains $agent.Name) {
                Add-MimsIssue $issues "发现废弃全局 Agent：$($agent.FullName)"
            }
        }
    }

    foreach ($refDir in @("$CLAUDE_DIR\skills\mims\references", "$AGENTS_DIR\skills\mims\references")) {
        foreach ($reference in (Get-ExistingMimsReferences $refDir)) {
            if ($packageReferences -notcontains $reference.Name) {
                Add-MimsIssue $issues "发现废弃全局 Reference：$($reference.FullName)"
            }
        }
    }

    if ($ProjectMarkers.Count -gt 0) {
        Add-MimsIssue $issues "当前项目存在 MIMS 配置：$($ProjectMarkers -join ', ')；本脚本只提示，不会自动修改项目文件。"
    }

    return @($issues)
}

function Show-MimsPreflightReport {
    param([object[]]$Issues)
    if ($Issues.Count -eq 0) { return }

    Write-Host ""
    Write-Host "更新前检查发现以下情况：" -ForegroundColor Yellow
    foreach ($issue in $Issues) { Write-Host "  - $issue" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "可清理范围仅限全局 MIMS 受管路径，不会删除项目内 CLAUDE.md / AGENTS.md / .claude / .agents。" -ForegroundColor Yellow
}

function Resolve-MimsUpdateAction {
    param([object[]]$Issues)
    if ($Issues.Count -eq 0) { return "overwrite" }
    if ($Silent) {
        Write-Host "Silent 模式：发现更新前检查提示，默认继续覆盖更新，不自动清理。" -ForegroundColor Yellow
        return "overwrite"
    }

    Write-Host "请选择更新方式："
    Write-Host "  1) 继续覆盖更新"
    Write-Host "  2) 清理全局 MIMS 后更新"
    Write-Host "  3) 退出"
    while ($true) {
        $choice = Read-Host "请输入 1/2/3"
        if ($choice -eq "1" -or $choice -eq "") { return "overwrite" }
        if ($choice -eq "2") { return "cleanup" }
        if ($choice -eq "3") { return "exit" }
        Write-Host "请输入 1、2 或 3。" -ForegroundColor Yellow
    }
}

function Invoke-MimsManagedCleanup {
    Write-Host "ℹ 清理全局 MIMS 受管路径..." -ForegroundColor Blue

    $paths = @(
        "$CLAUDE_DIR\skills\mims",
        "$AGENTS_DIR\skills\mims",
        "$AGENTS_DIR\AGENTS.md",
        "$MIMS_HOME\update.ps1",
        "$MIMS_HOME\update.sh",
        "$MIMS_HOME\install-state.json"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force }
    }

    foreach ($duplicateSkill in (Get-ExistingMimsSkillDirs "$CLAUDE_DIR\skills")) { Remove-Item -Path $duplicateSkill.FullName -Recurse -Force }
    foreach ($duplicateSkill in (Get-ExistingMimsSkillDirs "$AGENTS_DIR\skills")) { Remove-Item -Path $duplicateSkill.FullName -Recurse -Force }
    foreach ($agent in (Get-ExistingMimsAgents "$CLAUDE_DIR\agents")) { Remove-Item -Path $agent.FullName -Force }
    foreach ($agent in (Get-ExistingMimsAgents "$AGENTS_DIR\agents")) { Remove-Item -Path $agent.FullName -Force }

    Write-Host "✓ 全局 MIMS 受管路径已清理" -ForegroundColor Green
}

$existingClaudeSkill = "$CLAUDE_DIR\skills\mims\SKILL.md"
$existingCodexSkill = "$AGENTS_DIR\skills\mims\SKILL.md"
$existingClaudeVersion = if (Test-Path $existingClaudeSkill) { Get-MimsInstalledVersion $existingClaudeSkill } else { "none" }
$existingCodexVersion = if (Test-Path $existingCodexSkill) { Get-MimsInstalledVersion $existingCodexSkill } else { "none" }

$projectMarkers = @()
if (Test-Path "CLAUDE.md") {
    $claudeContent = Get-Content "CLAUDE.md" -Raw
    if ($claudeContent -match "<!--\s*MIMS-START(\s|>|--)") { $projectMarkers += "CLAUDE.md" }
}
if (Test-Path "AGENTS.md") {
    $agentsContent = Get-Content "AGENTS.md" -Raw
    if ($agentsContent -match "<!--\s*MIMS-START(\s|>|--)") { $projectMarkers += "AGENTS.md" }
}
if (Test-Path ".claude\skills\mims\SKILL.md") { $projectMarkers += ".claude\skills\mims" }
if (Test-Path ".agents\skills\mims\SKILL.md") { $projectMarkers += ".agents\skills\mims" }

$installSource = if ($Source -ne "") { "local" } else { "github" }

Write-Host ""
Write-Host "MIMS v$MIMS_VERSION 全局安装/更新" -ForegroundColor Cyan
Write-Host "迷悟师 - Make Idea Make Sense" -ForegroundColor Green
Write-Host ""
Write-Host "当前安装状态：" -ForegroundColor Cyan
Write-Host "  Claude Code 全局：$existingClaudeVersion"
Write-Host "  Codex 全局：$existingCodexVersion"
if ($projectMarkers.Count -gt 0) {
    Write-Host "  当前项目 MIMS 配置：$($projectMarkers -join ', ')" -ForegroundColor Yellow
    Write-Host "  本次只更新全局 MIMS，不会自动修改项目级配置。" -ForegroundColor Yellow
} else {
    Write-Host "  当前项目 MIMS 配置：未检测到"
}
Write-Host ""

if ($Source -ne "") {
    Write-Host "ℹ 从本地安装：$Source" -ForegroundColor Blue
} else {
    $tempDir = Join-Path $env:TEMP "mims-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    Write-Host "ℹ 下载 MIMS v$MIMS_VERSION..." -ForegroundColor Blue
    $zipFile = Join-Path $tempDir "mims.zip"
    try {
        Invoke-WebRequest -Uri $GITHUB_ZIP -OutFile $zipFile -UseBasicParsing
        $installSource = "github"
    } catch {
        try {
            Invoke-WebRequest -Uri $GITLAB_ZIP -OutFile $zipFile -UseBasicParsing
            $installSource = "gitlab"
        } catch {
            Write-Host "ℹ 未找到 v$MIMS_VERSION 发布包，尝试下载 main 分支..." -ForegroundColor Blue
            try {
                Invoke-WebRequest -Uri $GITHUB_MAIN_ZIP -OutFile $zipFile -UseBasicParsing
                $installSource = "github"
            } catch {
                try {
                    Invoke-WebRequest -Uri $GITLAB_MAIN_ZIP -OutFile $zipFile -UseBasicParsing
                    $installSource = "gitlab"
                } catch {
                    Write-Host "错误：下载失败" -ForegroundColor Red; exit 1
                }
            }
        }
    }
    Write-Host "✓ 下载完成（来源：$installSource）" -ForegroundColor Green

    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
    $extractedDir = Get-ChildItem -Path $tempDir -Directory -Filter "mims-*" | Select-Object -First 1
    if (-not $extractedDir) {
        $extractedDir = Get-ChildItem -Path $tempDir -Directory -Filter "MIMS-*" | Select-Object -First 1
    }
    $Source = $extractedDir.FullName
}

$releaseDir = Join-Path $Source "mims-release"
$legacyImplDir = Join-Path $Source "impl"
if (Test-Path (Join-Path $releaseDir ".claude\skills\mims\SKILL.md")) {
    $packageDir = $releaseDir
} elseif (Test-Path (Join-Path $Source ".claude\skills\mims\SKILL.md")) {
    $packageDir = $Source
} elseif (Test-Path (Join-Path $legacyImplDir ".claude\skills\mims\SKILL.md")) {
    $packageDir = $legacyImplDir
    Write-Host "ℹ 检测到旧版 impl 目录，按兼容模式安装" -ForegroundColor Blue
} else {
    Write-Host "错误：找不到 MIMS 发布包。请确认存在 mims-release/.claude 或 .claude 目录。" -ForegroundColor Red; exit 1
}

if (-not (Test-Path (Join-Path $packageDir "AGENTS.md"))) {
    Write-Host "警告：找不到 AGENTS.md，将只安装全局 Codex Skill/Agents" -ForegroundColor Yellow
}

$preflightIssues = Get-MimsPreflightState -PackageDir $packageDir -ExistingClaudeVersion $existingClaudeVersion -ExistingCodexVersion $existingCodexVersion -ProjectMarkers $projectMarkers
Show-MimsPreflightReport -Issues $preflightIssues
$preflightAction = Resolve-MimsUpdateAction -Issues $preflightIssues
if ($preflightAction -eq "exit") {
    Write-Host "已退出，未修改任何全局安装文件。" -ForegroundColor Yellow
    exit 0
}
$cleanupPerformed = $false
if ($preflightAction -eq "cleanup") {
    Invoke-MimsManagedCleanup
    $cleanupPerformed = $true
}

$skillTarget = "$CLAUDE_DIR\skills\mims"
Write-Host "ℹ 安装 Skill → $skillTarget" -ForegroundColor Blue
New-Item -ItemType Directory -Path "$skillTarget\references" -Force | Out-Null
Copy-Item "$packageDir\.claude\skills\mims\SKILL.md" "$skillTarget\SKILL.md" -Force
Copy-Item "$packageDir\.claude\skills\mims\references\*" "$skillTarget\references\" -Force
Write-Host "✓ Skill 已安装" -ForegroundColor Green

$agentsTarget = "$CLAUDE_DIR\agents"
Write-Host "ℹ 安装 Agents → $agentsTarget" -ForegroundColor Blue
New-Item -ItemType Directory -Path $agentsTarget -Force | Out-Null
Get-ChildItem "$packageDir\.claude\agents\mims-*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName $agentsTarget -Force
}
Write-Host "✓ Agents 已安装" -ForegroundColor Green

$codexSkillTarget = "$AGENTS_DIR\skills\mims"
$codexAgentsTarget = "$AGENTS_DIR\agents"
Write-Host "ℹ 安装 Codex 兼容 → $AGENTS_DIR" -ForegroundColor Blue
New-Item -ItemType Directory -Path "$codexSkillTarget\references" -Force | Out-Null
New-Item -ItemType Directory -Path $codexAgentsTarget -Force | Out-Null
Copy-Item "$skillTarget\SKILL.md" "$codexSkillTarget\SKILL.md" -Force
Copy-Item "$skillTarget\references\*" "$codexSkillTarget\references\" -Force
Get-ChildItem "$agentsTarget\mims-*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName $codexAgentsTarget -Force
}
if (Test-Path (Join-Path $packageDir "AGENTS.md")) {
    Copy-Item "$packageDir\AGENTS.md" "$AGENTS_DIR\AGENTS.md" -Force
}
Write-Host "✓ Codex 兼容已安装" -ForegroundColor Green

New-Item -ItemType Directory -Path $MIMS_HOME -Force | Out-Null
$sourceKind = $installSource
$updatePs1 = @'
# MIMS updater (Windows PowerShell)
param(
    [ValidateSet("github", "gitlab", "auto")]
    [string]$Source = "auto"
)

$stateFile = Join-Path $HOME ".mims\install-state.json"
if ($Source -eq "auto" -and (Test-Path $stateFile)) {
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($state.source -eq "gitlab" -or $state.source -eq "github") { $Source = $state.source }
    } catch {}
}
if ($Source -eq "auto" -or $Source -eq "local") { $Source = "github" }

Write-Host "MIMS updater source: $Source"
if ($Source -eq "gitlab") {
    iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.ps1'))
} else {
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
}
'@
$updateSh = @'
#!/bin/bash
# MIMS updater (Linux/macOS)
set -e
SOURCE="${1:-auto}"
STATE_FILE="$HOME/.mims/install-state.json"

if [ "$SOURCE" = "auto" ] && [ -f "$STATE_FILE" ]; then
    SAVED_SOURCE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("source", "github"))' "$STATE_FILE" 2>/dev/null || echo "github")
    if [ "$SAVED_SOURCE" = "gitlab" ] || [ "$SAVED_SOURCE" = "github" ]; then
        SOURCE="$SAVED_SOURCE"
    fi
fi
if [ "$SOURCE" = "auto" ] || [ "$SOURCE" = "local" ]; then
    SOURCE="github"
fi

echo "MIMS updater source: $SOURCE"
if [ "$SOURCE" = "gitlab" ]; then
    curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.sh | bash
else
    curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash
fi
'@
Set-Content -Path "$MIMS_HOME\update.ps1" -Value $updatePs1 -Encoding utf8
Set-Content -Path "$MIMS_HOME\update.sh" -Value $updateSh -Encoding utf8
$state = [ordered]@{
    version = $MIMS_VERSION
    installed_at = (Get-Date).ToString("o")
    source = $sourceKind
    claude_global = (Test-Path "$CLAUDE_DIR\skills\mims\SKILL.md")
    codex_global = (Test-Path "$AGENTS_DIR\skills\mims\SKILL.md")
    previous_claude_version = $existingClaudeVersion
    previous_codex_version = $existingCodexVersion
    project_markers = $projectMarkers
    preflight_action = $preflightAction
    cleanup_performed = $cleanupPerformed
    detected_residue = @($preflightIssues)
}
$state | ConvertTo-Json -Depth 4 | Set-Content -Path $STATE_FILE -Encoding utf8
Write-Host "✓ 本地更新器已写入：$MIMS_HOME\update.ps1 / update.sh" -ForegroundColor Green
Write-Host "✓ 安装状态已写入：$STATE_FILE" -ForegroundColor Green

$checks = @(
    "$CLAUDE_DIR\skills\mims\SKILL.md",
    "$CLAUDE_DIR\skills\mims\references\schema-contract.md",
    "$CLAUDE_DIR\skills\mims\references\schema.md",
    "$CLAUDE_DIR\agents\mims-validator.md",
    "$AGENTS_DIR\skills\mims\SKILL.md",
    "$AGENTS_DIR\skills\mims\references\schema-contract.md",
    "$AGENTS_DIR\skills\mims\references\schema.md",
    "$AGENTS_DIR\agents\mims-validator.md"
)
$missing = @()
foreach ($check in $checks) {
    if (-not (Test-Path $check)) { $missing += $check }
}
if ($missing.Count -gt 0) {
    Write-Host "警告：安装自检发现缺失文件：" -ForegroundColor Yellow
    foreach ($item in $missing) { Write-Host "  $item" -ForegroundColor Yellow }
} else {
    Write-Host "✓ 安装自检通过" -ForegroundColor Green
}

Write-Host ""
Write-Host "✓ MIMS v$MIMS_VERSION 全局安装/更新完成" -ForegroundColor Green
Write-Host ""
Write-Host "安装位置："
Write-Host "  Claude Code: ~/.claude/skills/mims/ + ~/.claude/agents/"
Write-Host "  Codex:       ~/.agents/skills/mims/ + ~/.agents/agents/"
Write-Host ""
Write-Host "使用方式："
Write-Host "  进入任意项目目录 → 输入 " -NoNewline
Write-Host "/mims" -ForegroundColor Green -NoNewline
Write-Host " 开始"
Write-Host "  Codex 中也可以直接说：请用 MIMS 帮我开始需求建模"
Write-Host ""
