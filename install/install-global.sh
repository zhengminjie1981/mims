#!/bin/bash
# MIMS 全局安装脚本 (Linux/macOS)
#
# 安装迷悟师 Skill + Agents 到 ~/.claude/ 和 ~/.agents/
# 安装一次，所有项目可用 /mims
#
# 用法：
#   curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash
#
#   非交互模式（AI 代理适用）：
#   curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash -s -- --silent

set -e

SILENT_MODE=false
LOCAL_SOURCE=""
INSTALL_SOURCE="github"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --silent) SILENT_MODE=true; shift ;;
        --source) LOCAL_SOURCE="$2"; INSTALL_SOURCE="local"; shift 2 ;;
        *) shift ;;
    esac
done

MIMS_VERSION="1.4"
GITHUB_ZIP="https://github.com/zhengminjie1981/mims/archive/refs/tags/v${MIMS_VERSION}.zip"
GITLAB_ZIP="https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/v${MIMS_VERSION}/MIMS-v${MIMS_VERSION}.zip"
GITHUB_MAIN_ZIP="https://github.com/zhengminjie1981/mims/archive/refs/heads/main.zip"
GITLAB_MAIN_ZIP="https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/main/MIMS-main.zip"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$HOME/.agents"
MIMS_HOME="$HOME/.mims"
STATE_FILE="$MIMS_HOME/install-state.json"

get_mims_version() {
    local skill_path="$1"
    local version_file
    version_file="$(dirname "$(dirname "$skill_path")")/.mims-version"
    if [ -f "$version_file" ]; then
        tr -d '\r\n' < "$version_file"
    elif [ -f "$skill_path" ]; then
        grep -E 'version:[[:space:]]*"[^\"]+"' "$skill_path" | head -1 | sed -E 's/.*version:[[:space:]]*"([^"]+)".*/\1/'
    else
        echo "none"
    fi
}

list_skill_dirs() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    find "$dir" -maxdepth 1 -type d -name 'mims*' ! -name 'mims' -exec basename {} \; | sort
}

list_file_names() {
    local dir="$1"
    local pattern="$2"
    [ -d "$dir" ] || return 0
    find "$dir" -maxdepth 1 -type f -name "$pattern" -exec basename {} \; | sort
}

array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

add_preflight_issue() {
    PREFLIGHT_ISSUES+=("$1")
}

scan_mims_preflight() {
    local package_dir="$1"
    PREFLIGHT_ISSUES=()

    PACKAGE_AGENTS=()
    while IFS= read -r item; do
        [ -n "$item" ] && PACKAGE_AGENTS+=("$item")
    done < <(list_file_names "$package_dir/.claude/agents" "mims-*.md")

    PACKAGE_REFERENCES=()
    while IFS= read -r item; do
        [ -n "$item" ] && PACKAGE_REFERENCES+=("$item")
    done < <(list_file_names "$package_dir/.claude/skills/mims/references" "*")

    if [ "$EXISTING_CLAUDE_VERSION" != "none" ] && [ "$EXISTING_CODEX_VERSION" != "none" ] && [ "$EXISTING_CLAUDE_VERSION" != "$EXISTING_CODEX_VERSION" ]; then
        add_preflight_issue "Claude Code 全局版本 ($EXISTING_CLAUDE_VERSION) 与 Codex 全局版本 ($EXISTING_CODEX_VERSION) 不一致。"
    fi
    if { [ "$EXISTING_CLAUDE_VERSION" = "none" ] && [ "$EXISTING_CODEX_VERSION" != "none" ]; } || { [ "$EXISTING_CLAUDE_VERSION" != "none" ] && [ "$EXISTING_CODEX_VERSION" = "none" ]; }; then
        add_preflight_issue "检测到 Claude Code / Codex 仅一端存在 MIMS，全局安装可能不完整。"
    fi

    if [ "$EXISTING_CLAUDE_VERSION" != "none" ] || [ "$EXISTING_CODEX_VERSION" != "none" ]; then
        local required
        for required in \
            "$CLAUDE_DIR/skills/mims/SKILL.md" \
            "$CLAUDE_DIR/skills/mims/references/schema-contract.md" \
            "$CLAUDE_DIR/skills/mims/references/schema.md" \
            "$CLAUDE_DIR/agents/mims-validator.md" \
            "$AGENTS_DIR/skills/mims/SKILL.md" \
            "$AGENTS_DIR/skills/mims/references/schema-contract.md" \
            "$AGENTS_DIR/skills/mims/references/schema.md" \
            "$AGENTS_DIR/agents/mims-validator.md"
        do
            [ -f "$required" ] || add_preflight_issue "缺少全局安装文件：$required"
        done
    fi

    local skill_root skill_name agent_dir agent_name ref_dir ref_name
    for skill_root in "$CLAUDE_DIR/skills" "$AGENTS_DIR/skills"; do
        while IFS= read -r skill_name; do
            [ -n "$skill_name" ] || continue
            add_preflight_issue "发现重复全局 Skill：$skill_root/$skill_name"
        done < <(list_skill_dirs "$skill_root")
    done

    for agent_dir in "$CLAUDE_DIR/agents" "$AGENTS_DIR/agents"; do
        while IFS= read -r agent_name; do
            [ -n "$agent_name" ] || continue
            if ! array_contains "$agent_name" "${PACKAGE_AGENTS[@]}"; then
                add_preflight_issue "发现废弃全局 Agent：$agent_dir/$agent_name"
            fi
        done < <(list_file_names "$agent_dir" "mims-*.md")
    done

    for ref_dir in "$CLAUDE_DIR/skills/mims/references" "$AGENTS_DIR/skills/mims/references"; do
        while IFS= read -r ref_name; do
            [ -n "$ref_name" ] || continue
            if ! array_contains "$ref_name" "${PACKAGE_REFERENCES[@]}"; then
                add_preflight_issue "发现废弃全局 Reference：$ref_dir/$ref_name"
            fi
        done < <(list_file_names "$ref_dir" "*")
    done

    if [ "${#PROJECT_MARKERS[@]}" -gt 0 ]; then
        add_preflight_issue "当前项目存在 MIMS 配置：${PROJECT_MARKERS[*]}；本脚本只提示，不会自动修改项目文件。"
    fi
}

show_mims_preflight_report() {
    [ "${#PREFLIGHT_ISSUES[@]}" -gt 0 ] || return 0
    echo ""
    warn "更新前检查发现以下情况："
    local issue
    for issue in "${PREFLIGHT_ISSUES[@]}"; do
        warn "  - $issue"
    done
    echo ""
    warn "可清理范围仅限全局 MIMS 受管路径，不会删除项目内 CLAUDE.md / AGENTS.md / .claude / .agents。"
}

resolve_mims_update_action() {
    if [ "${#PREFLIGHT_ISSUES[@]}" -eq 0 ]; then
        PREFLIGHT_ACTION="overwrite"
        return 0
    fi
    if [ "$SILENT_MODE" = true ]; then
        warn "Silent 模式：发现更新前检查提示，默认继续覆盖更新，不自动清理。"
        PREFLIGHT_ACTION="overwrite"
        return 0
    fi

    echo "请选择更新方式："
    echo "  1) 继续覆盖更新"
    echo "  2) 清理全局 MIMS 后更新"
    echo "  3) 退出"
    local choice
    while true; do
        read -r -p "请输入 1/2/3: " choice
        case "$choice" in
            1|"") PREFLIGHT_ACTION="overwrite"; return 0 ;;
            2) PREFLIGHT_ACTION="cleanup"; return 0 ;;
            3) PREFLIGHT_ACTION="exit"; return 0 ;;
            *) warn "请输入 1、2 或 3。" ;;
        esac
    done
}

cleanup_mims_managed_paths() {
    info "清理全局 MIMS 受管路径..."
    rm -rf "$CLAUDE_DIR/skills/mims"
    rm -rf "$AGENTS_DIR/skills/mims"
    rm -f "$AGENTS_DIR/AGENTS.md"
    rm -f "$MIMS_HOME/update.ps1" "$MIMS_HOME/update.sh" "$MIMS_HOME/install-state.json"

    if [ -d "$CLAUDE_DIR/skills" ]; then
        find "$CLAUDE_DIR/skills" -maxdepth 1 -type d -name 'mims*' ! -name 'mims' -exec rm -rf {} +
    fi
    if [ -d "$AGENTS_DIR/skills" ]; then
        find "$AGENTS_DIR/skills" -maxdepth 1 -type d -name 'mims*' ! -name 'mims' -exec rm -rf {} +
    fi

    if [ -d "$CLAUDE_DIR/agents" ]; then
        find "$CLAUDE_DIR/agents" -maxdepth 1 -type f -name 'mims-*.md' -delete
    fi
    if [ -d "$AGENTS_DIR/agents" ]; then
        find "$AGENTS_DIR/agents" -maxdepth 1 -type f -name 'mims-*.md' -delete
    fi
    success "全局 MIMS 受管路径已清理"
}

json_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/}
    printf '%s' "$value"
}

json_array() {
    if command -v python3 >/dev/null 2>&1 && python3 -c 'import json' >/dev/null 2>&1; then
        python3 -c 'import json,sys; print(json.dumps(sys.argv[1:], ensure_ascii=False))' "$@"
        return 0
    fi

    printf '['
    local first=true
    local item
    for item in "$@"; do
        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi
        printf '"%s"' "$(json_escape "$item")"
    done
    printf ']'
}

EXISTING_CLAUDE_VERSION="none"
EXISTING_CODEX_VERSION="none"
[ -f "$CLAUDE_DIR/skills/mims/SKILL.md" ] && EXISTING_CLAUDE_VERSION="$(get_mims_version "$CLAUDE_DIR/skills/mims/SKILL.md")"
[ -f "$AGENTS_DIR/skills/mims/SKILL.md" ] && EXISTING_CODEX_VERSION="$(get_mims_version "$AGENTS_DIR/skills/mims/SKILL.md")"

PROJECT_MARKERS=()
if [ -f "CLAUDE.md" ] && grep -Eq '<!--[[:space:]]*MIMS-START([[:space:]]|>|--)' "CLAUDE.md"; then PROJECT_MARKERS+=("CLAUDE.md"); fi
if [ -f "AGENTS.md" ] && grep -Eq '<!--[[:space:]]*MIMS-START([[:space:]]|>|--)' "AGENTS.md"; then PROJECT_MARKERS+=("AGENTS.md"); fi
if [ -f ".claude/skills/mims/SKILL.md" ]; then PROJECT_MARKERS+=(".claude/skills/mims"); fi
if [ -f ".agents/skills/mims/SKILL.md" ]; then PROJECT_MARKERS+=(".agents/skills/mims"); fi

echo ""
echo -e "${CYAN}MIMS v${MIMS_VERSION} 全局安装/更新${NC}"
echo -e "迷悟师 — ${GREEN}Make Idea Make Sense${NC}"
echo ""
echo -e "${CYAN}当前安装状态：${NC}"
echo "  Claude Code 全局：$EXISTING_CLAUDE_VERSION"
echo "  Codex 全局：$EXISTING_CODEX_VERSION"
if [ "${#PROJECT_MARKERS[@]}" -gt 0 ]; then
    warn "当前项目 MIMS 配置：${PROJECT_MARKERS[*]}"
    warn "本次只更新全局 MIMS，不会自动修改项目级配置。"
else
    echo "  当前项目 MIMS 配置：未检测到"
fi
echo ""

TEMP_DIR=""

if [ -n "$LOCAL_SOURCE" ]; then
    SOURCE_DIR="$LOCAL_SOURCE"
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "错误：目录不存在：$SOURCE_DIR" >&2; exit 1
    fi
    info "从本地安装：$SOURCE_DIR"
else
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    ZIP_FILE="$TEMP_DIR/mims.zip"

    info "下载 MIMS v${MIMS_VERSION}..."
    if command -v curl &>/dev/null; then
        if curl -fSL "$GITHUB_ZIP" -o "$ZIP_FILE" 2>/dev/null; then
            INSTALL_SOURCE="github"
        elif curl -fSL "$GITLAB_ZIP" -o "$ZIP_FILE" 2>/dev/null; then
            INSTALL_SOURCE="gitlab"
        else
            info "未找到 v${MIMS_VERSION} 发布包，尝试下载 main 分支..."
            if curl -fSL "$GITHUB_MAIN_ZIP" -o "$ZIP_FILE" 2>/dev/null; then
                INSTALL_SOURCE="github"
            else
                curl -fSL "$GITLAB_MAIN_ZIP" -o "$ZIP_FILE" 2>/dev/null
                INSTALL_SOURCE="gitlab"
            fi
        fi
    elif command -v wget &>/dev/null; then
        if wget -qO "$ZIP_FILE" "$GITHUB_ZIP"; then
            INSTALL_SOURCE="github"
        elif wget -qO "$ZIP_FILE" "$GITLAB_ZIP"; then
            INSTALL_SOURCE="gitlab"
        else
            info "未找到 v${MIMS_VERSION} 发布包，尝试下载 main 分支..."
            if wget -qO "$ZIP_FILE" "$GITHUB_MAIN_ZIP"; then
                INSTALL_SOURCE="github"
            else
                wget -qO "$ZIP_FILE" "$GITLAB_MAIN_ZIP"
                INSTALL_SOURCE="gitlab"
            fi
        fi
    else
        echo "错误：需要 curl 或 wget" >&2; exit 1
    fi
    success "下载完成（来源：$INSTALL_SOURCE）"

    cd "$TEMP_DIR"
    unzip -q "$ZIP_FILE" 2>/dev/null || python3 -m zipfile -e "$ZIP_FILE" . 2>/dev/null
    SOURCE_DIR=$(find . -maxdepth 1 -type d \( -name "MIMS-*" -o -name "mims-*" \) | head -1)
    if [ -z "$SOURCE_DIR" ]; then
        echo "错误：无法识别发布包结构" >&2; exit 1
    fi
fi

if [ -f "$SOURCE_DIR/mims-release/.claude/skills/mims/SKILL.md" ]; then
    PACKAGE_DIR="$SOURCE_DIR/mims-release"
elif [ -f "$SOURCE_DIR/.claude/skills/mims/SKILL.md" ]; then
    PACKAGE_DIR="$SOURCE_DIR"
elif [ -f "$SOURCE_DIR/impl/.claude/skills/mims/SKILL.md" ]; then
    PACKAGE_DIR="$SOURCE_DIR/impl"
    info "检测到旧版 impl 目录，按兼容模式安装"
else
    echo "错误：找不到 MIMS 发布包。请确认存在 mims-release/.claude 或 .claude 目录。" >&2; exit 1
fi

if [ ! -f "$PACKAGE_DIR/AGENTS.md" ]; then
    warn "找不到 AGENTS.md，将只安装全局 Codex Skill/Agents"
fi

scan_mims_preflight "$PACKAGE_DIR"
show_mims_preflight_report
resolve_mims_update_action
if [ "$PREFLIGHT_ACTION" = "exit" ]; then
    warn "已退出，未修改任何全局安装文件。"
    exit 0
fi
CLEANUP_PERFORMED=false
if [ "$PREFLIGHT_ACTION" = "cleanup" ]; then
    cleanup_mims_managed_paths
    CLEANUP_PERFORMED=true
fi

info "安装 Skill → $CLAUDE_DIR/skills/mims/"
mkdir -p "$CLAUDE_DIR/skills/mims/references"
cp "$PACKAGE_DIR/.claude/skills/mims/SKILL.md" "$CLAUDE_DIR/skills/mims/SKILL.md"
cp -r "$PACKAGE_DIR/.claude/skills/mims/references/"* "$CLAUDE_DIR/skills/mims/references/"
success "Skill 已安装"

info "安装 Agents → $CLAUDE_DIR/agents/"
mkdir -p "$CLAUDE_DIR/agents"
for agent in "$PACKAGE_DIR/.claude/agents/"mims-*.md; do
    [ -f "$agent" ] && cp "$agent" "$CLAUDE_DIR/agents/"
done
success "Agents 已安装"

info "安装 Codex 兼容 → $AGENTS_DIR/"
mkdir -p "$AGENTS_DIR/skills/mims/references"
mkdir -p "$AGENTS_DIR/agents"
cp "$CLAUDE_DIR/skills/mims/SKILL.md" "$AGENTS_DIR/skills/mims/SKILL.md"
cp -r "$CLAUDE_DIR/skills/mims/references/"* "$AGENTS_DIR/skills/mims/references/"
for agent in "$CLAUDE_DIR/agents/"mims-*.md; do
    [ -f "$agent" ] && cp "$agent" "$AGENTS_DIR/agents/"
done
if [ -f "$PACKAGE_DIR/AGENTS.md" ]; then
    cp "$PACKAGE_DIR/AGENTS.md" "$AGENTS_DIR/AGENTS.md"
fi
success "Codex 兼容已安装"

mkdir -p "$MIMS_HOME"
cat > "$MIMS_HOME/update.ps1" << 'EOF'
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
EOF
cat > "$MIMS_HOME/update.sh" << 'EOF'
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
EOF
chmod +x "$MIMS_HOME/update.sh"
SOURCE_KIND="$INSTALL_SOURCE"
PROJECT_MARKERS_JSON="$(json_array "${PROJECT_MARKERS[@]}")"
PREFLIGHT_ISSUES_JSON="$(json_array "${PREFLIGHT_ISSUES[@]}")"
cat > "$STATE_FILE" << EOF
{
  "version": "$MIMS_VERSION",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "$SOURCE_KIND",
  "claude_global": $([ -f "$CLAUDE_DIR/skills/mims/SKILL.md" ] && echo true || echo false),
  "codex_global": $([ -f "$AGENTS_DIR/skills/mims/SKILL.md" ] && echo true || echo false),
  "previous_claude_version": "$EXISTING_CLAUDE_VERSION",
  "previous_codex_version": "$EXISTING_CODEX_VERSION",
  "project_markers": $PROJECT_MARKERS_JSON,
  "preflight_action": "$PREFLIGHT_ACTION",
  "cleanup_performed": $CLEANUP_PERFORMED,
  "detected_residue": $PREFLIGHT_ISSUES_JSON
}
EOF
success "本地更新器已写入：$MIMS_HOME/update.ps1 / update.sh"
success "安装状态已写入：$STATE_FILE"

MISSING=0
for required in \
    "$CLAUDE_DIR/skills/mims/SKILL.md" \
    "$CLAUDE_DIR/skills/mims/references/schema-contract.md" \
    "$CLAUDE_DIR/skills/mims/references/schema.md" \
    "$CLAUDE_DIR/agents/mims-validator.md" \
    "$AGENTS_DIR/skills/mims/SKILL.md" \
    "$AGENTS_DIR/skills/mims/references/schema-contract.md" \
    "$AGENTS_DIR/skills/mims/references/schema.md" \
    "$AGENTS_DIR/agents/mims-validator.md"
do
    if [ ! -f "$required" ]; then
        warn "缺失：$required"
        MISSING=1
    fi
done
if [ "$MISSING" -eq 0 ]; then
    success "安装自检通过"
fi

echo ""
echo -e "${GREEN}✓ MIMS v${MIMS_VERSION} 全局安装/更新完成${NC}"
echo ""
echo "安装位置："
echo "  Claude Code: ~/.claude/skills/mims/ + ~/.claude/agents/"
echo "  Codex:       ~/.agents/skills/mims/ + ~/.agents/agents/"
echo ""
echo "使用方式："
echo -e "  进入任意项目目录 → 输入 ${GREEN}/mims${NC} 开始"
echo "  Codex 中也可以直接说：请用 MIMS 帮我开始需求建模"
echo ""
