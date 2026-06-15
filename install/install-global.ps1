# MIMS 全局安装脚本 (Windows PowerShell) — 加固版
#
# 安装迷悟师 Skill + Agents 到 ~/.claude/ 和 ~/.agents/
#
# 用法：
#   首次安装（公网 GitHub）：
#   iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
#
#   内网 GitLab（私有库需 token）：
#   $env:MIMS_TOKEN="xxxxx"; iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/api/v4/projects/antwork%2FCloudServer%2Fit%2FMIMS/repository/files/install%2Finstall-global.ps1/raw?ref=main'))
#
#   升级（本地更新器）：
#   & "$HOME\.mims\update.ps1"                 # 默认跟最新 release tag
#   & "$HOME\.mims\update.ps1" -Check          # 只检查
#   & "$HOME\.mims\update.ps1" -Edge           # 拉 main HEAD
#
#   非交互：-Silent

param(
    [switch]$Silent,
    [string]$Source = "",              # 本地源码目录（local 安装）
    [ValidateSet("github", "gitlab", "auto", "")]
    [string]$SourceKind = "auto",      # 远程来源覆盖
    [switch]$Check,
    [switch]$Edge
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# 常量
# ---------------------------------------------------------------------------
$MIMS_VERSION = "1.5.2"
$ProjEnc = "antwork%2FCloudServer%2Fit%2FMIMS"
$GithubRaw = "https://raw.githubusercontent.com/zhengminjie1981/mims"
$GithubApi = "https://api.github.com/repos/zhengminjie1981/mims"
$GithubArchive = "https://github.com/zhengminjie1981/mims/archive"
$GitlabHost = "https://gitlab.xyitech.com"
$GitlabApi = "$GitlabHost/api/v4/projects/$ProjEnc"
$CommitFileApiPath = "mims-release%2F.mims-commit"

$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$AGENTS_DIR = "$env:USERPROFILE\.agents"
$MIMS_HOME = "$env:USERPROFILE\.mims"
$STATE_FILE = "$MIMS_HOME\install-state.json"
$CONFIG_FILE = "$MIMS_HOME\config"
$LAST_INSTALL_DIR = "$MIMS_HOME\last-install"
$SNAPSHOT_DIR = "$MIMS_HOME\snapshots"
$SNAPSHOT_KEEP = 5

function Info-Msg($m) { Write-Host "ℹ $m" -ForegroundColor Blue }
function Success-Msg($m) { Write-Host "✓ $m" -ForegroundColor Green }
function Warn-Msg($m) { Write-Host "⚠ $m" -ForegroundColor Yellow }
function Die-Msg($m) { Write-Host "✗ $m" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# 配置读取：env > config > saved state > 默认
# ---------------------------------------------------------------------------
function Read-Config {
    param([string]$Key)
    if (Test-Path $CONFIG_FILE) {
        foreach ($line in Get-Content $CONFIG_FILE) {
            if ($line -match "^\s*$Key\s*=\s*(.*)$") { return $matches[1].Trim() }
        }
    }
    return $null
}
function Resolve-Source {
    $s = ""
    if ($env:MIMS_SOURCE) { $s = $env:MIMS_SOURCE }
    if ($SourceKind -and ($SourceKind -ne "auto")) { $s = $SourceKind }
    if (-not $s) { $s = Read-Config "source" }
    if ((-not $s) -and (Test-Path $STATE_FILE)) {
        try { $st = Get-Content $STATE_FILE -Raw | ConvertFrom-Json; if ($st.source) { $s = $st.source } } catch {}
    }
    if (-not $s) { $s = "github" }
    if ($s -ne "gitlab" -and $s -ne "github") { $s = "github" }
    return $s
}
function Resolve-Token {
    if ($env:MIMS_TOKEN) { return $env:MIMS_TOKEN }
    return Read-Config "gitlab_token"
}

# ---------------------------------------------------------------------------
# 网络工具（token 经 hashtable 注入，不进 argv）
# ---------------------------------------------------------------------------
function Invoke-GitlabRequest {
    param([string]$Uri, [string]$OutFile = "")
    $token = Resolve-Token
    $headers = @{}
    if ($token) { $headers["PRIVATE-TOKEN"] = $token }
    try {
        if ($OutFile) {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -Headers $headers
        } else {
            return (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers $headers).Content
        }
    } catch { return $null }
}
function Invoke-GithubRequest {
    param([string]$Uri, [string]$OutFile = "")
    try {
        if ($OutFile) {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
        } else {
            return (Invoke-WebRequest -Uri $Uri -UseBasicParsing).Content
        }
    } catch { return $null }
}

function Resolve-LatestTag {
    $t = ""
    $j = Invoke-GithubRequest "$GithubApi/releases/latest"
    if ($j) { try { $t = ($j | ConvertFrom-Json).tag_name } catch {} }
    if (-not $t) {
        $j = Invoke-GitlabRequest "$GitlabApi/releases"
        if ($j) { try { $t = (($j | ConvertFrom-Json)[0]).tag_name } catch {} }
    }
    if (-not $t) { $t = "v$MIMS_VERSION" }
    return ($t -replace '^v', '')
}
function Get-RemoteCommit {
    $c = ""
    $raw = Invoke-GithubRequest "$GithubRaw/mims-release/.mims-commit"
    if ($raw) { $c = ($raw -replace '\s', '') }
    if (-not $c -or $c -eq "dev") {
        if ((Resolve-Source) -eq "gitlab") {
            $raw = Invoke-GitlabRequest "$GitlabApi/repository/files/$CommitFileApiPath/raw?ref=main"
            if ($raw) { $c = ($raw -replace '\s', '') }
        }
    }
    if ($c -eq "dev") { $c = "" }
    return $c
}
function Get-LocalCommit {
    if (-not (Test-Path $STATE_FILE)) { return "" }
    try { return (Get-Content $STATE_FILE -Raw | ConvertFrom-Json).commit } catch { return "" }
}

if ($Check) {
    $lc = Get-LocalCommit
    $rc = Get-RemoteCommit
    Write-Host "本地：$(if ($lc) { $lc } else { '未知' })"
    Write-Host "远端：$(if ($rc) { $rc } else { '未知' })"
    if (-not $lc) { Warn-Msg "本地 commit 未知：当前可能是 edge/源码包安装（无 .mims-commit）。--check 需要 release tag 安装才能比对。" }
    if ($rc -and ($lc -eq $rc)) { Success-Msg "已是最新（$lc）" }
    else { Warn-Msg "有更新可用（本地 $(if($lc){$lc}else{'未知'}) → 远端 $(if($rc){$rc}else{'未知'})）"; Warn-Msg "运行 mims update 升级，或 mims update -Edge 跟随 main" }
    exit 0
}

# ---------------------------------------------------------------------------
# 既有预检/清理辅助
# ---------------------------------------------------------------------------
function Get-MimsInstalledVersion {
    param([string]$SkillPath)
    $versionFile = Join-Path (Split-Path (Split-Path $SkillPath -Parent) -Parent) ".mims-version"
    if (Test-Path $versionFile) { return (Get-Content $versionFile -Raw).Trim() }
    if (Test-Path $SkillPath) {
        $content = Get-Content $SkillPath -Raw
        if ($content -match 'version:\s*"([^"]+)"') { return $matches[1] }
    }
    return "unknown"
}
function Get-ExistingMimsSkillDirs { param([string]$SkillsPath); if (-not (Test-Path $SkillsPath)) { return @() }; return @(Get-ChildItem -Path $SkillsPath -Directory -Filter "mims*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "mims" }) }
function Get-ExistingMimsAgents { param([string]$AgentsPath); if (-not (Test-Path $AgentsPath)) { return @() }; return @(Get-ChildItem -Path $AgentsPath -Filter "mims-*.md" -File -ErrorAction SilentlyContinue) }
function Get-ExistingMimsReferences { param([string]$ReferencesPath); if (-not (Test-Path $ReferencesPath)) { return @() }; return @(Get-ChildItem -Path $ReferencesPath -File -ErrorAction SilentlyContinue) }
function Get-PackageFileNames { param([string]$Path, [string]$Filter); if (-not (Test-Path $Path)) { return @() }; return @(Get-ChildItem -Path $Path -Filter $Filter -File -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) }
function Add-MimsIssue { param([System.Collections.ArrayList]$Issues, [string]$Message); [void]$Issues.Add($Message) }

function Get-MimsPreflightState {
    param([string]$PackageDir, [string]$ExistingClaudeVersion, [string]$ExistingCodexVersion, [string[]]$ProjectMarkers)
    $issues = New-Object System.Collections.ArrayList
    $packageAgents = Get-PackageFileNames -Path (Join-Path $PackageDir ".claude\agents") -Filter "mims-*.md"
    $packageReferences = Get-PackageFileNames -Path (Join-Path $PackageDir ".claude\skills\mims\references") -Filter "*"
    if ($ExistingClaudeVersion -ne "none" -and $ExistingCodexVersion -ne "none" -and $ExistingClaudeVersion -ne $ExistingCodexVersion) { Add-MimsIssue $issues "Claude Code 全局版本 ($ExistingClaudeVersion) 与 Codex 全局版本 ($ExistingCodexVersion) 不一致。" }
    if (($ExistingClaudeVersion -eq "none" -and $ExistingCodexVersion -ne "none") -or ($ExistingClaudeVersion -ne "none" -and $ExistingCodexVersion -eq "none")) { Add-MimsIssue $issues "检测到 Claude Code / Codex 仅一端存在 MIMS，全局安装可能不完整。" }
    $requiredChecks = @("$CLAUDE_DIR\skills\mims\SKILL.md","$CLAUDE_DIR\skills\mims\references\schema-contract.md","$CLAUDE_DIR\skills\mims\references\schema.md","$CLAUDE_DIR\agents\mims-validator.md","$AGENTS_DIR\skills\mims\SKILL.md","$AGENTS_DIR\skills\mims\references\schema-contract.md","$AGENTS_DIR\skills\mims\references\schema.md","$AGENTS_DIR\agents\mims-validator.md")
    if ($ExistingClaudeVersion -ne "none" -or $ExistingCodexVersion -ne "none") {
        foreach ($c in $requiredChecks) { if (-not (Test-Path $c)) { Add-MimsIssue $issues "缺少全局安装文件：$c" } }
    }
    foreach ($skillDir in @($CLAUDE_DIR, $AGENTS_DIR)) { foreach ($dup in (Get-ExistingMimsSkillDirs (Join-Path $skillDir "skills"))) { Add-MimsIssue $issues "发现重复全局 Skill：$($dup.FullName)" } }
    foreach ($agentDir in @("$CLAUDE_DIR\agents", "$AGENTS_DIR\agents")) { foreach ($a in (Get-ExistingMimsAgents $agentDir)) { if ($packageAgents -notcontains $a.Name) { Add-MimsIssue $issues "发现废弃全局 Agent：$($a.FullName)" } } }
    foreach ($refDir in @("$CLAUDE_DIR\skills\mims\references", "$AGENTS_DIR\skills\mims\references")) { foreach ($r in (Get-ExistingMimsReferences $refDir)) { if ($packageReferences -notcontains $r.Name) { Add-MimsIssue $issues "发现废弃全局 Reference：$($r.FullName)" } } }
    if ($ProjectMarkers.Count -gt 0) { Add-MimsIssue $issues "当前项目存在 MIMS 配置：$($ProjectMarkers -join ', ')；本脚本只提示，不会自动修改项目文件。" }
    return @($issues)
}
function Show-MimsPreflightReport { param([object[]]$Issues); if ($Issues.Count -eq 0) { return }; Write-Host ""; Write-Host "更新前检查发现以下情况：" -ForegroundColor Yellow; foreach ($i in $Issues) { Write-Host "  - $i" -ForegroundColor Yellow }; Write-Host ""; Write-Host "可清理范围仅限全局 MIMS 受管路径，不会删除项目内 CLAUDE.md / AGENTS.md / .claude / .agents。" -ForegroundColor Yellow }
function Resolve-MimsUpdateAction {
    param([object[]]$Issues)
    if ($Issues.Count -eq 0) { return "overwrite" }
    if ($Silent) { Write-Host "Silent 模式：发现更新前检查提示，默认继续覆盖更新，不自动清理。" -ForegroundColor Yellow; return "overwrite" }
    Write-Host "请选择更新方式："; Write-Host "  1) 继续覆盖更新"; Write-Host "  2) 清理全局 MIMS 后更新"; Write-Host "  3) 退出"
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
    $paths = @("$CLAUDE_DIR\skills\mims","$AGENTS_DIR\skills\mims","$AGENTS_DIR\AGENTS.md","$MIMS_HOME\update.ps1","$MIMS_HOME\update.sh","$MIMS_HOME\install-state.json")
    foreach ($p in $paths) { if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force } }
    foreach ($d in (Get-ExistingMimsSkillDirs "$CLAUDE_DIR\skills")) { Remove-Item -Path $d.FullName -Recurse -Force }
    foreach ($d in (Get-ExistingMimsSkillDirs "$AGENTS_DIR\skills")) { Remove-Item -Path $d.FullName -Recurse -Force }
    foreach ($a in (Get-ExistingMimsAgents "$CLAUDE_DIR\agents")) { Remove-Item -Path $a.FullName -Force }
    foreach ($a in (Get-ExistingMimsAgents "$AGENTS_DIR\agents")) { Remove-Item -Path $a.FullName -Force }
    Write-Host "✓ 全局 MIMS 受管路径已清理" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 快照 / 回滚 / 完整性 / 本地改动保护
# ---------------------------------------------------------------------------
function Snapshot-Current {
    if (-not ((Test-Path "$CLAUDE_DIR\skills\mims") -or (Test-Path "$AGENTS_DIR\skills\mims"))) { return }
    New-Item -ItemType Directory -Path $SNAPSHOT_DIR -Force | Out-Null
    $ts = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    $snap = Join-Path $SNAPSHOT_DIR $ts
    if (Test-Path $snap) { Remove-Item $snap -Recurse -Force }
    New-Item -ItemType Directory -Path "$snap\claude-agents" -Force | Out-Null
    New-Item -ItemType Directory -Path "$snap\agents-agents" -Force | Out-Null
    if (Test-Path "$CLAUDE_DIR\skills\mims") { Copy-Item "$CLAUDE_DIR\skills\mims" "$snap\claude-skills-mims" -Recurse -Force }
    if (Test-Path "$AGENTS_DIR\skills\mims") { Copy-Item "$AGENTS_DIR\skills\mims" "$snap\agents-skills-mims" -Recurse -Force }
    foreach ($f in (Get-ChildItem "$CLAUDE_DIR\agents\mims-*.md" -ErrorAction SilentlyContinue)) { Copy-Item $f.FullName "$snap\claude-agents\" -Force }
    foreach ($f in (Get-ChildItem "$AGENTS_DIR\agents\mims-*.md" -ErrorAction SilentlyContinue)) { Copy-Item $f.FullName "$snap\agents-agents\" -Force }
    if (Test-Path "$AGENTS_DIR\AGENTS.md") { Copy-Item "$AGENTS_DIR\AGENTS.md" "$snap\AGENTS.md" -Force }
    if (Test-Path $STATE_FILE) { Copy-Item $STATE_FILE "$snap\install-state.json" -Force }
    Info-Msg "已快照当前安装 → $snap"
    $n = 0
    foreach ($d in (Get-ChildItem $SNAPSHOT_DIR -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        $n++; if ($n -gt $SNAPSHOT_KEEP) { Remove-Item $d.FullName -Recurse -Force }
    }
}
function Cleanup-LegacyBackups {
    # 1.4 时代用 ~/.mims/backup-<ts>，新版用 ~/.mims/snapshots/<ts>。清理孤儿目录。
    $found = @(Get-ChildItem $MIMS_HOME -Directory -Filter "backup-*" -ErrorAction SilentlyContinue)
    if ($found.Count -eq 0) { return }
    Warn-Msg "发现 1.4 时代 legacy 备份目录（新版已改用 ~/.mims/snapshots/），清理："
    foreach ($d in $found) { Warn-Msg "  - $($d.FullName)"; Remove-Item $d.FullName -Recurse -Force }
    Info-Msg "已清理 $($found.Count) 个 legacy backup 目录"
}
function Install-LifecycleScript {
    # 安装生命周期脚本到 ~/.mims/mims-lifecycle.py（/mims pause|persist|status|detach 调用）
    $src = Join-Path $packageDir "mims-lifecycle.py"
    if (-not (Test-Path $src)) {
        $devSrc = Join-Path $packageDir "..\scripts\mims-lifecycle.py"   # dev 本地源码布局
        if (Test-Path $devSrc) { $src = $devSrc } else { return }
    }
    Copy-Item $src "$MIMS_HOME\mims-lifecycle.py" -Force
    Success-Msg "生命周期脚本已写入：$MIMS_HOME\mims-lifecycle.py（/mims pause|persist|status|detach）"
}
function Verify-Integrity {
    param([string]$PackageDir)
    $sums = Join-Path $PackageDir "SHA256SUMS"
    if (-not (Test-Path $sums)) { Warn-Msg "发布包未含 SHA256SUMS，跳过完整性校验"; Warn-Msg "（edge/源码包构建不带 SHA256SUMS；如需完整性校验请用 release tag 安装）"; return }
    $bad = $false
    foreach ($line in (Get-Content $sums)) {
        if ($line -notmatch '^\s*([0-9a-fA-F]{64})\s+\*?(.+)$') { continue }
        $expected = $matches[1].ToLower(); $rel = $matches[2].Trim()
        $target = Join-Path $PackageDir $rel
        if (-not (Test-Path $target)) { $bad = $true; break }
        $actual = (Get-FileHash $target -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expected) { $bad = $true; break }
    }
    if ($bad) { Die-Msg "完整性校验失败：文件哈希不匹配，疑似下载损坏或被篡改。已中止安装。" }
    Success-Msg "完整性校验通过（SHA256SUMS）"
}
function Get-BaselineOf {
    param([string]$Dest)
    if ($Dest -like "$CLAUDE_DIR\*") { return Join-Path $LAST_INSTALL_DIR ("claude\" + $Dest.Substring($CLAUDE_DIR.Length + 1)) }
    if ($Dest -like "$AGENTS_DIR\*") { return Join-Path $LAST_INSTALL_DIR ("agents\" + $Dest.Substring($AGENTS_DIR.Length + 1)) }
    return ""
}
function Copy-Protected {  # src, dest —— 本地改动保留为 .local
    param([string]$Src, [string]$Dest)
    if (Test-Path $Dest) {
        $base = Get-BaselineOf $Dest
        if ($base -and (Test-Path $base)) {
            $destHash = (Get-FileHash $Dest -Algorithm SHA256).Hash
            $baseHash = (Get-FileHash $base -Algorithm SHA256).Hash
            $srcHash = (Get-FileHash $Src -Algorithm SHA256).Hash
            if ($destHash -ne $baseHash -and $destHash -ne $srcHash) {
                Warn-Msg "检测到本地修改，保留副本：$Dest.local"
                Copy-Item $Dest "$Dest.local" -Force
            }
        }
    }
    New-Item -ItemType Directory -Path (Split-Path $Dest -Parent) -Force | Out-Null
    Copy-Item $Src $Dest -Force
}
function Refresh-LastInstall {
    if (Test-Path $LAST_INSTALL_DIR) { Remove-Item $LAST_INSTALL_DIR -Recurse -Force }
    New-Item -ItemType Directory -Path "$LAST_INSTALL_DIR\claude\skills\mims\references" -Force | Out-Null
    New-Item -ItemType Directory -Path "$LAST_INSTALL_DIR\claude\agents" -Force | Out-Null
    New-Item -ItemType Directory -Path "$LAST_INSTALL_DIR\agents\skills\mims\references" -Force | Out-Null
    New-Item -ItemType Directory -Path "$LAST_INSTALL_DIR\agents\agents" -Force | Out-Null
    if (Test-Path "$CLAUDE_DIR\skills\mims") { Copy-Item "$CLAUDE_DIR\skills\mims\*" "$LAST_INSTALL_DIR\claude\skills\mims\" -Recurse -Force }
    if (Test-Path "$AGENTS_DIR\skills\mims") { Copy-Item "$AGENTS_DIR\skills\mims\*" "$LAST_INSTALL_DIR\agents\skills\mims\" -Recurse -Force }
    foreach ($f in (Get-ChildItem "$CLAUDE_DIR\agents\mims-*.md" -ErrorAction SilentlyContinue)) { Copy-Item $f.FullName "$LAST_INSTALL_DIR\claude\agents\" -Force }
    foreach ($f in (Get-ChildItem "$AGENTS_DIR\agents\mims-*.md" -ErrorAction SilentlyContinue)) { Copy-Item $f.FullName "$LAST_INSTALL_DIR\agents\agents\" -Force }
    if (Test-Path "$AGENTS_DIR\AGENTS.md") { Copy-Item "$AGENTS_DIR\AGENTS.md" "$LAST_INSTALL_DIR\agents\AGENTS.md" -Force }
}
function Write-RollbackScript {
    New-Item -ItemType Directory -Path $MIMS_HOME -Force | Out-Null
    $rb = @'
# MIMS 回滚脚本 —— 把指定快照（默认最近）拷回全局安装位置
param([string]$Timestamp = "")
$ErrorActionPreference = "Stop"
$ClaudeDir = "$env:USERPROFILE\.claude"; $AgentsDir = "$env:USERPROFILE\.agents"
$SnapDir = "$env:USERPROFILE\.mims\snapshots"
if (-not $Timestamp) {
    $latest = Get-ChildItem $SnapDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) { Write-Host "没有可回滚的快照"; exit 1 }
    $Timestamp = $latest.Name
}
$snap = Join-Path $SnapDir $Timestamp
if (-not (Test-Path $snap)) { Write-Host "快照不存在：$snap"; exit 1 }
Write-Host "回滚自快照：$snap"
if (Test-Path "$ClaudeDir\skills\mims") { Remove-Item "$ClaudeDir\skills\mims" -Recurse -Force }
if (Test-Path "$AgentsDir\skills\mims") { Remove-Item "$AgentsDir\skills\mims" -Recurse -Force }
if (Test-Path "$snap\claude-skills-mims") { New-Item -ItemType Directory -Path "$ClaudeDir\skills" -Force | Out-Null; Copy-Item "$snap\claude-skills-mims" "$ClaudeDir\skills\mims" -Recurse -Force }
if (Test-Path "$snap\agents-skills-mims") { New-Item -ItemType Directory -Path "$AgentsDir\skills" -Force | Out-Null; Copy-Item "$snap\agents-skills-mims" "$AgentsDir\skills\mims" -Recurse -Force }
foreach ($f in (Get-ChildItem "$snap\claude-agents\mims-*.md" -ErrorAction SilentlyContinue)) { New-Item -ItemType Directory -Path "$ClaudeDir\agents" -Force | Out-Null; Copy-Item $f.FullName "$ClaudeDir\agents\" -Force }
foreach ($f in (Get-ChildItem "$snap\agents-agents\mims-*.md" -ErrorAction SilentlyContinue)) { New-Item -ItemType Directory -Path "$AgentsDir\agents" -Force | Out-Null; Copy-Item $f.FullName "$AgentsDir\agents\" -Force }
if (Test-Path "$snap\AGENTS.md") { Copy-Item "$snap\AGENTS.md" "$AgentsDir\AGENTS.md" -Force }
if (Test-Path "$snap\install-state.json") { Copy-Item "$snap\install-state.json" "$env:USERPROFILE\.mims\install-state.json" -Force }
Write-Host "✓ 已回滚到 $Timestamp"
'@
    Set-Content -Path "$MIMS_HOME\rollback.ps1" -Value $rb -Encoding utf8
}

# ===========================================================================
# 主流程
# ===========================================================================
$existingClaudeSkill = "$CLAUDE_DIR\skills\mims\SKILL.md"
$existingCodexSkill = "$AGENTS_DIR\skills\mims\SKILL.md"
$existingClaudeVersion = if (Test-Path $existingClaudeSkill) { Get-MimsInstalledVersion $existingClaudeSkill } else { "none" }
$existingCodexVersion = if (Test-Path $existingCodexSkill) { Get-MimsInstalledVersion $existingCodexSkill } else { "none" }

$projectMarkers = @()
if (Test-Path "CLAUDE.md") { if ((Get-Content "CLAUDE.md" -Raw) -match "<!--\s*MIMS-START(\s|>|--)") { $projectMarkers += "CLAUDE.md" } }
if (Test-Path "AGENTS.md") { if ((Get-Content "AGENTS.md" -Raw) -match "<!--\s*MIMS-START(\s|>|--)") { $projectMarkers += "AGENTS.md" } }
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
Write-Host "  本地内容提交：$(Get-LocalCommit)"
if ($projectMarkers.Count -gt 0) {
    Write-Host "  当前项目 MIMS 配置：$($projectMarkers -join ', ')" -ForegroundColor Yellow
    Write-Host "  本次只更新全局 MIMS，不会自动修改项目级配置。" -ForegroundColor Yellow
} else { Write-Host "  当前项目 MIMS 配置：未检测到" }
Write-Host ""

# 短路：本地已是最新且非 edge/check
if (-not $Source -and -not $Edge) {
    $lc = Get-LocalCommit; $rc = Get-RemoteCommit
    if ($lc -and $rc -and ($lc -eq $rc)) { Success-Msg "已是最新内容（$lc）。如需重装，加 -Edge 或重跑安装。" }
}

if ($Source -ne "") {
    Info-Msg "从本地安装：$Source"
} else {
    $tempDir = Join-Path $env:TEMP "mims-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $zipFile = Join-Path $tempDir "mims.zip"
    if ($Edge) { $ref = "main"; Info-Msg "拉取 main HEAD（-Edge）..."; Warn-Msg "edge 构建通常不带 SHA256SUMS/.mims-commit；完整性校验与 -Check 可能不可用。如需校验请用 release tag（去掉 -Edge）。" }
    else { $tag = Resolve-LatestTag; $ref = "v$tag"; Info-Msg "目标版本：$ref（最新 release tag）" }
    $installSource = Resolve-Source
    Info-Msg "下载来源：$installSource"
    try {
        if ($installSource -eq "gitlab") {
            $ok = Invoke-GitlabRequest "$GitlabApi/repository/archive.zip?sha=$ref" -OutFile $zipFile
            if (-not $ok -or -not (Test-Path $zipFile)) { throw "gitlab" }
        } else {
            Invoke-WebRequest -Uri "$GithubArchive/$ref.zip" -OutFile $zipFile -UseBasicParsing
        }
    } catch {
        Info-Msg "首选源不可用，尝试另一源..."
        try {
            Invoke-WebRequest -Uri "$GithubArchive/$ref.zip" -OutFile $zipFile -UseBasicParsing; $installSource = "github"
        } catch {
            $ok = Invoke-GitlabRequest "$GitlabApi/repository/archive.zip?sha=$ref" -OutFile $zipFile
            if (-not $ok) { Die-Msg "下载失败：GitHub 与 GitLab 均不可用。私有库请确认 MIMS_TOKEN / ~/.mims/config。" }
            $installSource = "gitlab"
        }
    }
    Success-Msg "下载完成（来源：$installSource）"
    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
    $extracted = Get-ChildItem -Path $tempDir -Directory -Filter "mims-*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $extracted) { $extracted = Get-ChildItem -Path $tempDir -Directory -Filter "MIMS-*" | Select-Object -First 1 }
    $Source = $extracted.FullName
}

$releaseDir = Join-Path $Source "mims-release"
$legacyImplDir = Join-Path $Source "impl"
if (Test-Path (Join-Path $releaseDir ".claude\skills\mims\SKILL.md")) { $packageDir = $releaseDir }
elseif (Test-Path (Join-Path $Source ".claude\skills\mims\SKILL.md")) { $packageDir = $Source }
elseif (Test-Path (Join-Path $legacyImplDir ".claude\skills\mims\SKILL.md")) { $packageDir = $legacyImplDir; Info-Msg "检测到旧版 impl 目录，按兼容模式安装" }
else { Die-Msg "找不到 MIMS 发布包。请确认存在 mims-release/.claude 或 .claude 目录。" }
if (-not (Test-Path (Join-Path $packageDir "AGENTS.md"))) { Warn-Msg "找不到 AGENTS.md，将只安装全局 Codex Skill/Agents" }

Verify-Integrity $packageDir

$packageCommit = ""
$commitFile = Join-Path $packageDir ".mims-commit"
if (Test-Path $commitFile) { $packageCommit = ((Get-Content $commitFile -Raw) -replace '\s', ''); if ($packageCommit -eq "dev") { $packageCommit = "" } }

$preflightIssues = Get-MimsPreflightState -PackageDir $packageDir -ExistingClaudeVersion $existingClaudeVersion -ExistingCodexVersion $existingCodexVersion -ProjectMarkers $projectMarkers
Show-MimsPreflightReport -Issues $preflightIssues
$preflightAction = Resolve-MimsUpdateAction -Issues $preflightIssues
if ($preflightAction -eq "exit") { Write-Host "已退出，未修改任何全局安装文件。" -ForegroundColor Yellow; exit 0 }
$cleanupPerformed = $false
if ($preflightAction -eq "cleanup") { Invoke-MimsManagedCleanup; $cleanupPerformed = $true }

Snapshot-Current
Cleanup-LegacyBackups
Write-RollbackScript
Install-LifecycleScript

$skillTarget = "$CLAUDE_DIR\skills\mims"
Info-Msg "安装 Skill → $skillTarget"
New-Item -ItemType Directory -Path "$skillTarget\references" -Force | Out-Null
Copy-Protected -Src (Join-Path $packageDir ".claude\skills\mims\SKILL.md") -Dest "$skillTarget\SKILL.md"
foreach ($ref in (Get-ChildItem (Join-Path $packageDir ".claude\skills\mims\references\*") -ErrorAction SilentlyContinue)) { Copy-Protected -Src $ref.FullName -Dest "$skillTarget\references\$($ref.Name)" }
Success-Msg "Skill 已安装"

$agentsTarget = "$CLAUDE_DIR\agents"
Info-Msg "安装 Agents → $agentsTarget"
New-Item -ItemType Directory -Path $agentsTarget -Force | Out-Null
foreach ($a in (Get-ChildItem (Join-Path $packageDir ".claude\agents\mims-*.md") -ErrorAction SilentlyContinue)) { Copy-Protected -Src $a.FullName -Dest "$agentsTarget\$($a.Name)" }
Success-Msg "Agents 已安装"

$codexSkillTarget = "$AGENTS_DIR\skills\mims"; $codexAgentsTarget = "$AGENTS_DIR\agents"
Info-Msg "安装 Codex 兼容 → $AGENTS_DIR"
New-Item -ItemType Directory -Path "$codexSkillTarget\references" -Force | Out-Null
New-Item -ItemType Directory -Path $codexAgentsTarget -Force | Out-Null
Copy-Protected -Src "$skillTarget\SKILL.md" -Dest "$codexSkillTarget\SKILL.md"
foreach ($ref in (Get-ChildItem "$skillTarget\references\*" -ErrorAction SilentlyContinue)) { Copy-Protected -Src $ref.FullName -Dest "$codexSkillTarget\references\$($ref.Name)" }
foreach ($a in (Get-ChildItem "$agentsTarget\mims-*.md" -ErrorAction SilentlyContinue)) { Copy-Protected -Src $a.FullName -Dest "$codexAgentsTarget\$($a.Name)" }
if (Test-Path (Join-Path $packageDir "AGENTS.md")) { Copy-Protected -Src (Join-Path $packageDir "AGENTS.md") -Dest "$AGENTS_DIR\AGENTS.md" }
Success-Msg "Codex 兼容已安装"

New-Item -ItemType Directory -Path $MIMS_HOME -Force | Out-Null
$updateSh = @'
#!/bin/bash
# MIMS updater (Linux/macOS) — 加固版（由 PowerShell 安装器写入，供 WSL/Git Bash 使用）
set -euo pipefail
STATE_FILE="$HOME/.mims/install-state.json"; CONFIG_FILE="$HOME/.mims/config"
GITHUB_RAW="https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh"
GITLAB_API="https://gitlab.xyitech.com/api/v4/projects/antwork%2FCloudServer%2Fit%2FMIMS"
GITLAB_INSTALLER_RAW="${GITLAB_API}/repository/files/install%2Finstall-global.sh/raw?ref=main"
FORWARD=(); FORCE_SOURCE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from) FORCE_SOURCE="$2"; FORWARD+=(--from "$2"); shift 2 ;;
        --check|--edge|--silent) FORWARD+=("$1"); shift ;;
        github|gitlab|auto) FORCE_SOURCE="$1"; shift ;;
        *) FORWARD+=("$1"); shift ;;
    esac
done
resolve_source() { local s=""; [ -n "${MIMS_SOURCE:-}" ] && s="$MIMS_SOURCE"; [ -n "$FORCE_SOURCE" ] && s="$FORCE_SOURCE"; if [ -z "$s" ] || [ "$s" = "auto" ]; then [ -f "$CONFIG_FILE" ] && s=$(grep -E '^source=' "$CONFIG_FILE" | head -1 | cut -d= -f2 | sed 's/[[:space:]]//g'); fi; [ -z "$s" ] && s="github"; case "$s" in github|gitlab) echo "$s" ;; *) echo "github" ;; esac; }
SOURCE="$(resolve_source)"; echo "MIMS updater source: $SOURCE"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
if [ "$SOURCE" = "gitlab" ]; then
    TOK="${MIMS_TOKEN:-}"; [ -z "$TOK" ] && [ -f "$CONFIG_FILE" ] && TOK=$(grep -E '^gitlab_token=' "$CONFIG_FILE" | head -1 | cut -d= -f2- | sed 's/[[:space:]]//g')
    if [ -n "$TOK" ]; then CFG="$(mktemp)"; chmod 600 "$CFG"; printf 'header = "PRIVATE-TOKEN: %s"\nconnect-timeout="10"\nmax-time="120"\n' "$TOK" > "$CFG"; curl -fsSL --config "$CFG" "$GITLAB_INSTALLER_RAW" -o "$TMP" || { rm -f "$CFG"; echo "下载失败（GitLab）" >&2; exit 1; }; rm -f "$CFG"; else curl -fsSL --connect-timeout 10 --max-time 120 "$GITLAB_INSTALLER_RAW" -o "$TMP" || { echo "GitLab 私有库需要 MIMS_TOKEN" >&2; exit 1; }; fi
else
    curl -fsSL --connect-timeout 10 --max-time 120 "$GITHUB_RAW" -o "$TMP" || { echo "下载失败（GitHub）" >&2; exit 1; }
fi
case "$(head -c2 "$TMP")" in \#!) ;; *) echo "下载内容不是脚本" >&2; exit 1 ;; esac
bash "$TMP" "${FORWARD[@]}"
'@
Set-Content -Path "$MIMS_HOME\update.sh" -Value $updateSh -Encoding utf8

$updatePs1 = @'
# MIMS updater (Windows PowerShell) — 加固版
param(
    [ValidateSet("github","gitlab","auto")][string]$SourceKind = "auto",
    [switch]$Check, [switch]$Edge, [switch]$Silent
)
$ErrorActionPreference = "Stop"
$StateFile = Join-Path $HOME ".mims\install-state.json"; $ConfigFile = Join-Path $HOME ".mims\config"
$ProjEnc = "antwork%2FCloudServer%2Fit%2FMIMS"
$GithubRaw = "https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1"
$GitlabInstaller = "https://gitlab.xyitech.com/api/v4/projects/$ProjEnc/repository/files/install%2Finstall-global.ps1/raw?ref=main"
function Read-Config($Key) { if (Test-Path $ConfigFile) { foreach ($line in Get-Content $ConfigFile) { if ($line -match "^\s*$Key\s*=\s*(.*)$") { return $matches[1].Trim() } } }; return $null }
if ($SourceKind -eq "auto" -or $SourceKind -eq "local") {
    if ($env:MIMS_SOURCE) { $SourceKind = $env:MIMS_SOURCE } elseif ($s = Read-Config "source") { $SourceKind = $s }
    elseif (Test-Path $StateFile) { try { $st = Get-Content $StateFile -Raw | ConvertFrom-Json; if ($st.source) { $SourceKind = $st.source } } catch {} }
    if ($SourceKind -eq "auto" -or $SourceKind -eq "local") { $SourceKind = "github" }
}
Write-Host "MIMS updater source: $SourceKind"
$tmp = Join-Path $env:TEMP "mims-install-$(Get-Random).ps1"
try {
    if ($SourceKind -eq "gitlab") {
        $token = if ($env:MIMS_TOKEN) { $env:MIMS_TOKEN } else { Read-Config "gitlab_token" }
        $headers = @{}; if ($token) { $headers["PRIVATE-TOKEN"] = $token }
        Invoke-WebRequest -Uri $GitlabInstaller -OutFile $tmp -UseBasicParsing -Headers $headers
    } else { Invoke-WebRequest -Uri $GithubRaw -OutFile $tmp -UseBasicParsing }
    $head = (Get-Content $tmp -TotalCount 1 -ErrorAction SilentlyContinue)
    if ($head -notmatch "^#|^param\(") { throw "下载的内容不是脚本（可能为错误页）" }
    $fwd = @(); if ($Check) { $fwd += "-Check" }; if ($Edge) { $fwd += "-Edge" }; if ($Silent) { $fwd += "-Silent" }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tmp -SourceKind $SourceKind @fwd
} finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
'@
Set-Content -Path "$MIMS_HOME\update.ps1" -Value $updatePs1 -Encoding utf8

$commitForState = if ($packageCommit) { $packageCommit } else { Get-RemoteCommit }
$state = [ordered]@{
    version = $MIMS_VERSION
    commit = $commitForState
    installed_at = (Get-Date).ToString("o")
    source = $installSource
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
Success-Msg "本地更新器已写入：$MIMS_HOME\update.ps1 / update.sh"
Success-Msg "回滚脚本已写入：$MIMS_HOME\rollback.ps1"
Success-Msg "安装状态已写入：$STATE_FILE"

Refresh-LastInstall

$changelog = Join-Path $packageDir "CHANGELOG.md"
if (Test-Path $changelog) {
    Write-Host ""
    Write-Host "本次升级变更（CHANGELOG）：" -ForegroundColor Cyan
    Get-Content $changelog -TotalCount 40
}

$checks = @("$CLAUDE_DIR\skills\mims\SKILL.md","$CLAUDE_DIR\skills\mims\references\schema-contract.md","$CLAUDE_DIR\skills\mims\references\schema.md","$CLAUDE_DIR\agents\mims-validator.md","$AGENTS_DIR\skills\mims\SKILL.md","$AGENTS_DIR\skills\mims\references\schema-contract.md","$AGENTS_DIR\skills\mims\references\schema.md","$AGENTS_DIR\agents\mims-validator.md")
$missing = @(); foreach ($c in $checks) { if (-not (Test-Path $c)) { $missing += $c } }
if ($missing.Count -gt 0) { foreach ($m in $missing) { Warn-Msg "缺失：$m" } } else { Success-Msg "安装自检通过" }

if (($env:MIMS_TOKEN -or $env:MIMS_SOURCE -or ($SourceKind -and $SourceKind -ne "auto")) -and -not (Test-Path $CONFIG_FILE)) {
    New-Item -ItemType Directory -Path $MIMS_HOME -Force | Out-Null
    $cfg = @()
    $cfg += "source=$installSource"
    if ($env:MIMS_TOKEN) { $cfg += "gitlab_token=$($env:MIMS_TOKEN)" }
    $cfg | Set-Content -Path $CONFIG_FILE -Encoding utf8
    Success-Msg "已写入配置：$CONFIG_FILE"
}

Write-Host ""
Write-Host "✓ MIMS v$MIMS_VERSION 全局安装/更新完成" -ForegroundColor Green
Write-Host ""
Write-Host "安装位置："
Write-Host "  Claude Code: ~/.claude/skills/mims/ + ~/.claude/agents/"
Write-Host "  Codex:       ~/.agents/skills/mims/ + ~/.agents/agents/"
Write-Host ""
Write-Host "使用方式："
Write-Host "  进入任意项目目录 → 输入 " -NoNewline; Write-Host "/mims" -ForegroundColor Green -NoNewline; Write-Host " 开始"
Write-Host "  Codex 中也可以直接说：请用 MIMS 帮我开始需求建模"
Write-Host ""
