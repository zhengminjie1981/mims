#!/bin/bash
# MIMS 全局安装脚本 (Linux/macOS) — 加固版
#
# 安装迷悟师 Skill + Agents 到 ~/.claude/ 和 ~/.agents/
# 安装一次，所有项目可用 /mims
#
# 用法：
#   首次安装（公网 GitHub）：
#   curl -fsSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh -o /tmp/mims-install.sh && bash /tmp/mims-install.sh
#
#   内网 GitLab（私有库需 token）：
#   export MIMS_TOKEN=xxxxx
#   curl -fsSL -H "PRIVATE-TOKEN: $MIMS_TOKEN" "https://gitlab.xyitech.com/api/v4/projects/antwork%2FCloudServer%2Fit%2FMIMS/repository/files/install%2Finstall-global.sh/raw?ref=main" -o /tmp/mims-install.sh && bash /tmp/mims-install.sh --from gitlab
#
#   升级（本地更新器，自动选源、转 --check/--edge）：
#   bash ~/.mims/update.sh                 # 默认跟最新 release tag
#   bash ~/.mims/update.sh --check         # 只检查是否最新
#   bash ~/.mims/update.sh --edge          # 拉 main HEAD
#
#   非交互（AI 代理）：追加 --silent

set -euo pipefail

# ---------------------------------------------------------------------------
# 常量
# ---------------------------------------------------------------------------
MIMS_VERSION="1.6.0"
MIMS_PROJECT_PATH_ENCODED="antwork%2FCloudServer%2Fit%2FMIMS"
GITHUB_RAW="https://raw.githubusercontent.com/zhengminjie1981/mims"
GITHUB_API="https://api.github.com/repos/zhengminjie1981/mims"
GITHUB_ARCHIVE="https://github.com/zhengminjie1981/mims/archive"
GITLAB_HOST="https://gitlab.xyitech.com"
GITLAB_API="${GITLAB_HOST}/api/v4/projects/${MIMS_PROJECT_PATH_ENCODED}"
COMMIT_FILE_API_PATH="mims-release%2F.mims-commit"

CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$HOME/.agents"
MIMS_HOME="$HOME/.mims"
STATE_FILE="$MIMS_HOME/install-state.json"
CONFIG_FILE="$MIMS_HOME/config"
LAST_INSTALL_DIR="$MIMS_HOME/last-install"
SNAPSHOT_DIR="$MIMS_HOME/snapshots"
SNAPSHOT_KEEP=5

GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
die()     { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 参数
# ---------------------------------------------------------------------------
SILENT_MODE=false
LOCAL_SOURCE=""
FORCE_SOURCE=""      # github | gitlab
DO_CHECK=false
DO_EDGE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --silent) SILENT_MODE=true; shift ;;
        --source) LOCAL_SOURCE="$2"; shift 2 ;;
        --from)   FORCE_SOURCE="$2"; shift 2 ;;
        --check)  DO_CHECK=true; shift ;;
        --edge)   DO_EDGE=true; shift ;;
        *) shift ;;
    esac
done

# ---------------------------------------------------------------------------
# 配置读取：env > config > saved state > 默认
# ---------------------------------------------------------------------------
CFG_SOURCE=""
CFG_TOKEN=""
load_config() {
    [ -f "$CONFIG_FILE" ] || return 0
    local key val
    while IFS='=' read -r key val; do
        key="${key%%#*}"
        [ -z "${key// /}" ] && continue
        key="$(echo -n "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        case "$key" in
            source) CFG_SOURCE="$(echo -n "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ;;
            gitlab_token) CFG_TOKEN="$(echo -n "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ;;
        esac
    done < "$CONFIG_FILE"
}
load_config

resolve_source() {
    local s=""
    [ -n "${MIMS_SOURCE:-}" ] && s="$MIMS_SOURCE"
    [ -n "$FORCE_SOURCE" ] && s="$FORCE_SOURCE"
    [ -z "$s" ] && s="$CFG_SOURCE"
    if [ -z "$s" ] && [ -f "$STATE_FILE" ]; then
        s=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("source",""))' "$STATE_FILE" 2>/dev/null || echo "")
    fi
    [ -z "$s" ] && s="github"
    case "$s" in
        github|gitlab) echo "$s" ;;
        *) echo "github" ;;
    esac
}
resolve_token() {
    if [ -n "${MIMS_TOKEN:-}" ]; then echo "$MIMS_TOKEN"; return 0; fi
    echo "$CFG_TOKEN"
}

# ---------------------------------------------------------------------------
# 网络工具
# ---------------------------------------------------------------------------
# gitlab_fetch <url> [outfile]  —— token 经临时 curl config 注入，不进 argv
gitlab_fetch() {
    local url="$1"; local out="${2:-}"
    local tok; tok="$(resolve_token)"
    if [ -n "$tok" ]; then
        local cfg; cfg="$(mktemp)"; chmod 600 "$cfg"
        printf 'header = "PRIVATE-TOKEN: %s"\nconnect-timeout = "10"\nmax-time = "120"\n' "$tok" > "$cfg"
        if [ -n "$out" ]; then
            curl -fsSL --config "$cfg" "$url" -o "$out" || { rm -f "$cfg"; return 1; }
        else
            curl -fsSL --config "$cfg" "$url" || { rm -f "$cfg"; return 1; }
        fi
        rm -f "$cfg"
    else
        if [ -n "$out" ]; then
            curl -fsSL --connect-timeout 10 --max-time 120 "$url" -o "$out" || return 1
        else
            curl -fsSL --connect-timeout 10 --max-time 120 "$url" || return 1
        fi
    fi
}
http_get() {  # <url> [outfile] —— 公网
    local url="$1"; local out="${2:-}"
    if [ -n "$out" ]; then curl -fsSL --connect-timeout 10 --max-time 120 "$url" -o "$out" || return 1
    else curl -fsSL --connect-timeout 10 --max-time 120 "$url" || return 1; fi
}

_gitlab_latest_tag() {
    # 从 GitLab tags API 取最高语义化版本（不依赖 GitLab release 对象，也不打 GitHub）
    gitlab_fetch "$GITLAB_API/repository/tags?per_page=50" - 2>/dev/null | python3 -c 'import json,sys,re
try:
    d=json.load(sys.stdin)
    tags=[x["name"].lstrip("v") for x in d]
    valid=[x for x in tags if re.match(r"^\d+\.\d+(\.\d+)?$", x)]
    print(max(valid, key=lambda s: tuple(int(n) for n in s.split("."))) if valid else "")
except Exception: print("")' 2>/dev/null || true
}
resolve_latest_tag() {
    local t="" src; src="$(resolve_source)"
    if [ "$src" = "gitlab" ]; then
        # GitLab 用户从 GitLab tags 解析（不依赖 GitHub releases/latest，避免公网波动）
        t=$(_gitlab_latest_tag)
    else
        t=$(http_get "$GITHUB_API/releases/latest" - 2>/dev/null | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tag_name",""))
except Exception: print("")' 2>/dev/null || true)
        [ -z "$t" ] && t=$(_gitlab_latest_tag)
    fi
    [ -z "$t" ] && t="v$MIMS_VERSION"
    echo "${t#v}"
}
remote_commit() {
    local c=""
    c=$(http_get "$GITHUB_RAW/mims-release/.mims-commit" - 2>/dev/null | tr -d '[:space:]' || true)
    if [ -z "$c" ] || [ "$c" = "dev" ]; then
        if [ "$(resolve_source)" = "gitlab" ]; then
            c=$(gitlab_fetch "$GITLAB_API/repository/files/${COMMIT_FILE_API_PATH}/raw?ref=main" - 2>/dev/null | tr -d '[:space:]' || true)
        fi
    fi
    [ "$c" = "dev" ] && c=""
    echo "$c"
}
local_commit() {
    [ -f "$STATE_FILE" ] || { echo ""; return 0; }
    python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("commit",""))
except Exception: print("")' "$STATE_FILE" 2>/dev/null || echo ""
}
do_check() {
    local lc rc
    lc="$(local_commit)"
    rc="$(remote_commit)"
    echo "本地：${lc:-未知}"
    echo "远端：${rc:-未知}"
    if [ -z "$lc" ]; then
        warn "本地 commit 未知：当前可能是 edge/源码包安装（无 .mims-commit）。--check 需要 release tag 安装才能比对。"
    fi
    if [ -n "$rc" ] && [ "$lc" = "$rc" ]; then
        success "已是最新（$lc）"
    else
        warn "有更新可用（本地 ${lc:-未知} → 远端 ${rc:-未知}）"
        warn "运行 mims update 升级，或 mims update --edge 跟随 main"
    fi
    exit 0
}
if [ "$DO_CHECK" = true ]; then do_check; fi

# ---------------------------------------------------------------------------
# 既有的预检/清理辅助
# ---------------------------------------------------------------------------
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
    local dir="$1"; local pattern="$2"
    [ -d "$dir" ] || return 0
    find "$dir" -maxdepth 1 -type f -name "$pattern" -exec basename {} \; | sort
}
array_contains() {
    local needle="$1"; shift
    local item
    for item in "$@"; do [ "$item" = "$needle" ] && return 0; done
    return 1
}

EXISTING_CLAUDE_VERSION="none"
EXISTING_CODEX_VERSION="none"
if [ -f "$CLAUDE_DIR/skills/mims/SKILL.md" ]; then EXISTING_CLAUDE_VERSION="$(get_mims_version "$CLAUDE_DIR/skills/mims/SKILL.md")"; fi
if [ -f "$AGENTS_DIR/skills/mims/SKILL.md" ]; then EXISTING_CODEX_VERSION="$(get_mims_version "$AGENTS_DIR/skills/mims/SKILL.md")"; fi

PROJECT_MARKERS=()
if [ -f "CLAUDE.md" ] && grep -Eq '<!--[[:space:]]*MIMS-START([[:space:]]|>|--)' "CLAUDE.md"; then PROJECT_MARKERS+=("CLAUDE.md"); fi
if [ -f "AGENTS.md" ] && grep -Eq '<!--[[:space:]]*MIMS-START([[:space:]]|>|--)' "AGENTS.md"; then PROJECT_MARKERS+=("AGENTS.md"); fi
if [ -f ".claude/skills/mims/SKILL.md" ]; then PROJECT_MARKERS+=(".claude/skills/mims"); fi
if [ -f ".agents/skills/mims/SKILL.md" ]; then PROJECT_MARKERS+=(".agents/skills/mims"); fi

PREFLIGHT_ISSUES=()
add_preflight_issue() { PREFLIGHT_ISSUES+=("$1"); }
PACKAGE_AGENTS=(); PACKAGE_REFERENCES=()

scan_mims_preflight() {
    local package_dir="$1"
    PREFLIGHT_ISSUES=()
    PACKAGE_AGENTS=()
    while IFS= read -r item; do [ -n "$item" ] && PACKAGE_AGENTS+=("$item"); done < <(list_file_names "$package_dir/.claude/agents" "mims-*.md")
    PACKAGE_REFERENCES=()
    while IFS= read -r item; do [ -n "$item" ] && PACKAGE_REFERENCES+=("$item"); done < <(list_file_names "$package_dir/.claude/skills/mims/references" "*")

    if [ "$EXISTING_CLAUDE_VERSION" != "none" ] && [ "$EXISTING_CODEX_VERSION" != "none" ] && [ "$EXISTING_CLAUDE_VERSION" != "$EXISTING_CODEX_VERSION" ]; then
        add_preflight_issue "Claude Code 全局版本 ($EXISTING_CLAUDE_VERSION) 与 Codex 全局版本 ($EXISTING_CODEX_VERSION) 不一致。"
    fi
    if { [ "$EXISTING_CLAUDE_VERSION" = "none" ] && [ "$EXISTING_CODEX_VERSION" != "none" ]; } || { [ "$EXISTING_CLAUDE_VERSION" != "none" ] && [ "$EXISTING_CODEX_VERSION" = "none" ]; }; then
        add_preflight_issue "检测到 Claude Code / Codex 仅一端存在 MIMS，全局安装可能不完整。"
    fi
    if [ "$EXISTING_CLAUDE_VERSION" != "none" ] || [ "$EXISTING_CODEX_VERSION" != "none" ]; then
        local required
        for required in \
            "$CLAUDE_DIR/skills/mims/SKILL.md" "$CLAUDE_DIR/skills/mims/references/schema-contract.md" \
            "$CLAUDE_DIR/skills/mims/references/schema.md" "$CLAUDE_DIR/agents/mims-validator.md" \
            "$AGENTS_DIR/skills/mims/SKILL.md" "$AGENTS_DIR/skills/mims/references/schema-contract.md" \
            "$AGENTS_DIR/skills/mims/references/schema.md" "$AGENTS_DIR/agents/mims-validator.md"; do
            [ -f "$required" ] || add_preflight_issue "缺少全局安装文件：$required"
        done
    fi
    local skill_root skill_name agent_dir agent_name ref_dir ref_name
    for skill_root in "$CLAUDE_DIR/skills" "$AGENTS_DIR/skills"; do
        while IFS= read -r skill_name; do [ -n "$skill_name" ] && add_preflight_issue "发现重复全局 Skill：$skill_root/$skill_name"; done < <(list_skill_dirs "$skill_root")
    done
    for agent_dir in "$CLAUDE_DIR/agents" "$AGENTS_DIR/agents"; do
        while IFS= read -r agent_name; do
            [ -n "$agent_name" ] || continue
            array_contains "$agent_name" "${PACKAGE_AGENTS[@]}" || add_preflight_issue "发现废弃全局 Agent：$agent_dir/$agent_name"
        done < <(list_file_names "$agent_dir" "mims-*.md")
    done
    for ref_dir in "$CLAUDE_DIR/skills/mims/references" "$AGENTS_DIR/skills/mims/references"; do
        while IFS= read -r ref_name; do
            [ -n "$ref_name" ] || continue
            array_contains "$ref_name" "${PACKAGE_REFERENCES[@]}" || add_preflight_issue "发现废弃全局 Reference：$ref_dir/$ref_name"
        done < <(list_file_names "$ref_dir" "*")
    done
    if [ "${#PROJECT_MARKERS[@]}" -gt 0 ]; then
        add_preflight_issue "当前项目存在 MIMS 配置：${PROJECT_MARKERS[*]}；本脚本只提示，不会自动修改项目文件。"
    fi
}
show_mims_preflight_report() {
    [ "${#PREFLIGHT_ISSUES[@]}" -gt 0 ] || return 0
    echo ""; warn "更新前检查发现以下情况："
    local issue; for issue in "${PREFLIGHT_ISSUES[@]}"; do warn "  - $issue"; done
    echo ""; warn "可清理范围仅限全局 MIMS 受管路径，不会删除项目内 CLAUDE.md / AGENTS.md / .claude / .agents。"
}
resolve_mims_update_action() {
    if [ "${#PREFLIGHT_ISSUES[@]}" -eq 0 ]; then PREFLIGHT_ACTION="overwrite"; return 0; fi
    if [ "$SILENT_MODE" = true ]; then
        warn "Silent 模式：发现更新前检查提示，默认继续覆盖更新，不自动清理。"
        PREFLIGHT_ACTION="overwrite"; return 0
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
    rm -rf "$CLAUDE_DIR/skills/mims" "$AGENTS_DIR/skills/mims"
    rm -f "$AGENTS_DIR/AGENTS.md" "$MIMS_HOME/update.ps1" "$MIMS_HOME/update.sh" "$MIMS_HOME/install-state.json"
    if [ -d "$CLAUDE_DIR/skills" ]; then find "$CLAUDE_DIR/skills" -maxdepth 1 -type d -name 'mims*' ! -name 'mims' -exec rm -rf {} +; fi
    if [ -d "$AGENTS_DIR/skills" ]; then find "$AGENTS_DIR/skills" -maxdepth 1 -type d -name 'mims*' ! -name 'mims' -exec rm -rf {} +; fi
    if [ -d "$CLAUDE_DIR/agents" ]; then find "$CLAUDE_DIR/agents" -maxdepth 1 -type f -name 'mims-*.md' -delete; fi
    if [ -d "$AGENTS_DIR/agents" ]; then find "$AGENTS_DIR/agents" -maxdepth 1 -type f -name 'mims-*.md' -delete; fi
    success "全局 MIMS 受管路径已清理"
}

# ---------------------------------------------------------------------------
# 快照 / 回滚 / 完整性 / 本地改动保护
# ---------------------------------------------------------------------------
snapshot_current() {
    { [ -d "$CLAUDE_DIR/skills/mims" ] || [ -d "$AGENTS_DIR/skills/mims" ]; } || return 0
    mkdir -p "$SNAPSHOT_DIR"
    local ts; ts=$(date -u +%Y%m%d%H%M%S)
    local snap="$SNAPSHOT_DIR/$ts"
    rm -rf "$snap"; mkdir -p "$snap/claude-agents" "$snap/agents-agents"
    if [ -d "$CLAUDE_DIR/skills/mims" ]; then cp -r "$CLAUDE_DIR/skills/mims" "$snap/claude-skills-mims"; fi
    if [ -d "$AGENTS_DIR/skills/mims" ]; then cp -r "$AGENTS_DIR/skills/mims" "$snap/agents-skills-mims"; fi
    local f
    for f in "$CLAUDE_DIR/agents"/mims-*.md; do if [ -f "$f" ]; then cp "$f" "$snap/claude-agents/"; fi; done
    for f in "$AGENTS_DIR/agents"/mims-*.md; do if [ -f "$f" ]; then cp "$f" "$snap/agents-agents/"; fi; done
    if [ -f "$AGENTS_DIR/AGENTS.md" ]; then cp "$AGENTS_DIR/AGENTS.md" "$snap/AGENTS.md"; fi
    if [ -f "$STATE_FILE" ]; then cp "$STATE_FILE" "$snap/install-state.json"; fi
    info "已快照当前安装 → $snap"
    local n=0 d
    for d in $(ls -1 "$SNAPSHOT_DIR" 2>/dev/null | sort -r); do
        n=$((n+1))
        if [ "$n" -gt "$SNAPSHOT_KEEP" ]; then rm -rf "$SNAPSHOT_DIR/$d"; fi
    done
}

install_lifecycle_script() {
    # 安装生命周期脚本到 ~/.mims/mims-lifecycle.py（/mims pause|persist|status|detach 调用）
    local src=""
    if [ -f "$PACKAGE_DIR/mims-lifecycle.py" ]; then
        src="$PACKAGE_DIR/mims-lifecycle.py"
    elif [ -f "$PACKAGE_DIR/../scripts/mims-lifecycle.py" ]; then
        src="$PACKAGE_DIR/../scripts/mims-lifecycle.py"   # dev 本地源码布局
    fi
    if [ -n "$src" ]; then
        cp "$src" "$MIMS_HOME/mims-lifecycle.py"
        chmod +x "$MIMS_HOME/mims-lifecycle.py" 2>/dev/null || true
        success "生命周期脚本已写入：$MIMS_HOME/mims-lifecycle.py（/mims pause|persist|status|detach）"
    fi
}
cleanup_legacy_backups() {    # 1.4 时代用 ~/.mims/backup-<ts>，新版用 ~/.mims/snapshots/<ts>。清理孤儿目录。
    local found=() d
    for d in "$MIMS_HOME"/backup-*; do
        if [ -d "$d" ]; then found+=("$d"); fi
    done
    if [ "${#found[@]}" -eq 0 ]; then return 0; fi
    warn "发现 1.4 时代 legacy 备份目录（新版已改用 ~/.mims/snapshots/），清理："
    for d in "${found[@]}"; do warn "  - $d"; rm -rf "$d"; done
    info "已清理 ${#found[@]} 个 legacy backup 目录"
}
verify_integrity() {  # PACKAGE_DIR
    local pkg="$1"
    local sums="$pkg/SHA256SUMS"
    if [ ! -f "$sums" ]; then
        warn "发布包未含 SHA256SUMS，跳过完整性校验"
        warn "（edge/源码包构建不带 SHA256SUMS；如需完整性校验请用 release tag 安装）"
        return 0
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        ( cd "$pkg" && sha256sum -c SHA256SUMS --quiet ) || die "完整性校验失败：文件哈希不匹配，疑似下载损坏或被篡改。已中止安装。"
    elif command -v shasum >/dev/null 2>&1; then
        ( cd "$pkg" && shasum -a 256 -c SHA256SUMS --quiet ) || die "完整性校验失败：文件哈希不匹配，疑似下载损坏或被篡改。已中止安装。"
    else
        warn "未找到 sha256sum/shasum，跳过完整性校验"
        return 0
    fi
    success "完整性校验通过（SHA256SUMS）"
}

baseline_of() {  # dest -> last-install 对照路径
    case "$1" in
        "$CLAUDE_DIR"/*) echo "$LAST_INSTALL_DIR/claude/${1#"$CLAUDE_DIR/"}" ;;
        "$AGENTS_DIR"/*) echo "$LAST_INSTALL_DIR/agents/${1#"$AGENTS_DIR/"}" ;;
        *) echo "" ;;
    esac
}
cp_protected() {  # <src> <dest> —— 本地改动保留为 .local
    local src="$1" dest="$2"
    if [ -f "$dest" ]; then
        local base; base="$(baseline_of "$dest")"
        if [ -f "$base" ] && ! diff -q "$dest" "$base" >/dev/null 2>&1 && ! diff -q "$dest" "$src" >/dev/null 2>&1; then
            warn "检测到本地修改，保留副本：${dest}.local"
            cp "$dest" "${dest}.local"
        fi
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
}
refresh_last_install() {
    rm -rf "$LAST_INSTALL_DIR"
    mkdir -p "$LAST_INSTALL_DIR/claude/skills/mims/references" "$LAST_INSTALL_DIR/claude/agents" \
             "$LAST_INSTALL_DIR/agents/skills/mims/references" "$LAST_INSTALL_DIR/agents/agents"
    if [ -d "$CLAUDE_DIR/skills/mims" ]; then cp -r "$CLAUDE_DIR/skills/mims/." "$LAST_INSTALL_DIR/claude/skills/mims/"; fi
    if [ -d "$AGENTS_DIR/skills/mims" ]; then cp -r "$AGENTS_DIR/skills/mims/." "$LAST_INSTALL_DIR/agents/skills/mims/"; fi
    local f
    for f in "$CLAUDE_DIR/agents"/mims-*.md; do if [ -f "$f" ]; then cp "$f" "$LAST_INSTALL_DIR/claude/agents/"; fi; done
    for f in "$AGENTS_DIR/agents"/mims-*.md; do if [ -f "$f" ]; then cp "$f" "$LAST_INSTALL_DIR/agents/agents/"; fi; done
    if [ -f "$AGENTS_DIR/AGENTS.md" ]; then cp "$AGENTS_DIR/AGENTS.md" "$LAST_INSTALL_DIR/agents/AGENTS.md"; fi
}
write_rollback_script() {
    mkdir -p "$MIMS_HOME"
    cat > "$MIMS_HOME/rollback.sh" << 'ROLLBACK'
#!/bin/bash
# MIMS 回滚脚本 —— 把指定快照（默认最近）拷回全局安装位置
set -euo pipefail
CLAUDE_DIR="$HOME/.claude"; AGENTS_DIR="$HOME/.agents"; SNAP_DIR="$HOME/.mims/snapshots"
TS="${1:-}"
if [ -z "$TS" ]; then
    TS=$(ls -1 "$SNAP_DIR" 2>/dev/null | sort -r | head -1)
    [ -z "$TS" ] && { echo "没有可回滚的快照"; exit 1; }
fi
SNAP="$SNAP_DIR/$TS"
[ -d "$SNAP" ] || { echo "快照不存在：$SNAP"; exit 1; }
echo "回滚自快照：$SNAP"
rm -rf "$CLAUDE_DIR/skills/mims" "$AGENTS_DIR/skills/mims"
if [ -d "$SNAP/claude-skills-mims" ]; then mkdir -p "$CLAUDE_DIR/skills"; cp -r "$SNAP/claude-skills-mims" "$CLAUDE_DIR/skills/mims"; fi
if [ -d "$SNAP/agents-skills-mims" ]; then mkdir -p "$AGENTS_DIR/skills"; cp -r "$SNAP/agents-skills-mims" "$AGENTS_DIR/skills/mims"; fi
f=""; for f in "$SNAP/claude-agents"/mims-*.md; do if [ -f "$f" ]; then mkdir -p "$CLAUDE_DIR/agents"; cp "$f" "$CLAUDE_DIR/agents/"; fi; done
for f in "$SNAP/agents-agents"/mims-*.md; do if [ -f "$f" ]; then mkdir -p "$AGENTS_DIR/agents"; cp "$f" "$AGENTS_DIR/agents/"; fi; done
if [ -f "$SNAP/AGENTS.md" ]; then cp "$SNAP/AGENTS.md" "$AGENTS_DIR/AGENTS.md"; fi
if [ -f "$SNAP/install-state.json" ]; then cp "$SNAP/install-state.json" "$HOME/.mims/install-state.json"; fi
echo "✓ 已回滚到 $TS"
ROLLBACK
    chmod +x "$MIMS_HOME/rollback.sh"
}

# ---------------------------------------------------------------------------
# JSON 辅助
# ---------------------------------------------------------------------------
json_escape() {
    local value="$1"
    value=${value//\\/\\\\}; value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}; value=${value//$'\r'/}
    printf '%s' "$value"
}
json_array() {
    if command -v python3 >/dev/null 2>&1 && python3 -c 'import json' >/dev/null 2>&1; then
        python3 -c 'import json,sys; print(json.dumps(sys.argv[1:], ensure_ascii=False))' "$@"; return 0
    fi
    printf '['; local first=true item
    for item in "$@"; do if [ "$first" = true ]; then first=false; else printf ','; fi; printf '"%s"' "$(json_escape "$item")"; done
    printf ']'
}

# ===========================================================================
# 主流程
# ===========================================================================
SOURCE_KIND="github"
echo ""
echo -e "${CYAN}MIMS v${MIMS_VERSION} 全局安装/更新${NC}"
echo -e "迷悟师 — ${GREEN}Make Idea Make Sense${NC}"
echo ""
echo -e "${CYAN}当前安装状态：${NC}"
echo "  Claude Code 全局：$EXISTING_CLAUDE_VERSION"
echo "  Codex 全局：$EXISTING_CODEX_VERSION"
echo "  本地内容提交：$(local_commit || echo 未知)"
if [ "${#PROJECT_MARKERS[@]}" -gt 0 ]; then
    warn "当前项目 MIMS 配置：${PROJECT_MARKERS[*]}"
    warn "本次只更新全局 MIMS，不会自动修改项目级配置。"
else
    echo "  当前项目 MIMS 配置：未检测到"
fi
echo ""

if [ -z "$LOCAL_SOURCE" ] && [ "$DO_EDGE" = false ]; then
    lc="$(local_commit || true)"; rc="$(remote_commit || true)"
    if [ -n "$lc" ] && [ -n "$rc" ] && [ "$lc" = "$rc" ]; then
        success "已是最新内容（$lc）。如需重装，加 --edge 或重跑安装。"
    fi
fi

TEMP_DIR=""
if [ -n "$LOCAL_SOURCE" ]; then
    SOURCE_DIR="$LOCAL_SOURCE"
    [ -d "$SOURCE_DIR" ] || die "目录不存在：$SOURCE_DIR"
    info "从本地安装：$SOURCE_DIR"
    SOURCE_KIND="local"
else
    TEMP_DIR=$(mktemp -d); trap 'rm -rf "$TEMP_DIR"' EXIT
    ZIP_FILE="$TEMP_DIR/mims.zip"
    if [ "$DO_EDGE" = true ]; then
        REF="main"; info "拉取 main HEAD（--edge）..."
        warn "edge 构建通常不带 SHA256SUMS/.mims-commit；完整性校验与 --check 可能不可用。如需校验请用 release tag（去掉 --edge）。"
    else
        TAG="$(resolve_latest_tag)"; REF="v${TAG}"
        info "目标版本：$REF（最新 release tag）"
    fi
    SOURCE_KIND="$(resolve_source)"
    info "下载来源：$SOURCE_KIND"
    if [ "$SOURCE_KIND" = "gitlab" ]; then
        GITLAB_ZIP="$GITLAB_API/repository/archive.zip?sha=${REF}"
        gitlab_fetch "$GITLAB_ZIP" "$ZIP_FILE" || die "GitLab 下载失败（ref=$REF）。私有库请确认 MIMS_TOKEN / ~/.mims/config 已配置。"
    else
        GITHUB_ZIP="$GITHUB_ARCHIVE/${REF}.zip"
        if http_get "$GITHUB_ZIP" "$ZIP_FILE" 2>/dev/null; then
            :
        else
            info "GitHub 不可用，尝试 GitLab API..."
            GITLAB_ZIP="$GITLAB_API/repository/archive.zip?sha=${REF}"
            gitlab_fetch "$GITLAB_ZIP" "$ZIP_FILE" || die "下载失败：GitHub 与 GitLab 均不可用。"
            SOURCE_KIND="gitlab"
        fi
    fi
    success "下载完成（来源：$SOURCE_KIND）"
    cd "$TEMP_DIR"
    unzip -q "$ZIP_FILE" 2>/dev/null || python3 -m zipfile -e "$ZIP_FILE" . 2>/dev/null || die "解压失败"
    SOURCE_DIR=$(find . -maxdepth 1 -type d \( -name "MIMS-*" -o -name "mims-*" \) | head -1)
    [ -n "$SOURCE_DIR" ] || die "无法识别发布包结构"
fi

if [ -f "$SOURCE_DIR/mims-release/.claude/skills/mims/SKILL.md" ]; then
    PACKAGE_DIR="$SOURCE_DIR/mims-release"
elif [ -f "$SOURCE_DIR/.claude/skills/mims/SKILL.md" ]; then
    PACKAGE_DIR="$SOURCE_DIR"
elif [ -f "$SOURCE_DIR/impl/.claude/skills/mims/SKILL.md" ]; then
    PACKAGE_DIR="$SOURCE_DIR/impl"; info "检测到旧版 impl 目录，按兼容模式安装"
else
    die "找不到 MIMS 发布包。请确认存在 mims-release/.claude 或 .claude 目录。"
fi
if [ ! -f "$PACKAGE_DIR/AGENTS.md" ]; then warn "找不到 AGENTS.md，将只安装全局 Codex Skill/Agents"; fi

verify_integrity "$PACKAGE_DIR"

PACKAGE_COMMIT=""
if [ -f "$PACKAGE_DIR/.mims-commit" ]; then
    PACKAGE_COMMIT="$(tr -d '\r\n[:space:]' < "$PACKAGE_DIR/.mims-commit")"
    [ "$PACKAGE_COMMIT" = "dev" ] && PACKAGE_COMMIT=""
fi
# 实际安装的版本：从包内 .mims-version 读取（而非 installer 脚本自身的 MIMS_VERSION，避免版本不匹配）
PACKAGE_VERSION="$MIMS_VERSION"
if [ -f "$PACKAGE_DIR/.mims-version" ]; then
    PACKAGE_VERSION="$(tr -d '\r\n[:space:]' < "$PACKAGE_DIR/.mims-version")"
    [ -z "$PACKAGE_VERSION" ] && PACKAGE_VERSION="$MIMS_VERSION"
fi
if [ "$PACKAGE_VERSION" != "$MIMS_VERSION" ]; then
    info "实际安装版本：$PACKAGE_VERSION（installer 自身版本 $MIMS_VERSION，以包内容为准）"
fi

scan_mims_preflight "$PACKAGE_DIR"
show_mims_preflight_report
resolve_mims_update_action
if [ "$PREFLIGHT_ACTION" = "exit" ]; then warn "已退出，未修改任何全局安装文件。"; exit 0; fi
CLEANUP_PERFORMED=false
if [ "$PREFLIGHT_ACTION" = "cleanup" ]; then cleanup_mims_managed_paths; CLEANUP_PERFORMED=true; fi

snapshot_current
cleanup_legacy_backups
write_rollback_script
install_lifecycle_script

info "安装 Skill → $CLAUDE_DIR/skills/mims/"
mkdir -p "$CLAUDE_DIR/skills/mims/references"
cp_protected "$PACKAGE_DIR/.claude/skills/mims/SKILL.md" "$CLAUDE_DIR/skills/mims/SKILL.md"
for ref in "$PACKAGE_DIR/.claude/skills/mims/references/"*; do
    if [ -f "$ref" ]; then cp_protected "$ref" "$CLAUDE_DIR/skills/mims/references/$(basename "$ref")"; fi
done
success "Skill 已安装"

# 安装 .mims-version 到 ~/.claude/skills/ 和 ~/.agents/skills/（get_mims_version 从此处读取版本）
if [ -f "$PACKAGE_DIR/.mims-version" ]; then
    mkdir -p "$CLAUDE_DIR/skills" "$AGENTS_DIR/skills"
    cp "$PACKAGE_DIR/.mims-version" "$CLAUDE_DIR/skills/.mims-version"
    cp "$PACKAGE_DIR/.mims-version" "$AGENTS_DIR/skills/.mims-version"
fi

info "安装 Agents → $CLAUDE_DIR/agents/"
mkdir -p "$CLAUDE_DIR/agents"
for agent in "$PACKAGE_DIR/.claude/agents/"mims-*.md; do
    if [ -f "$agent" ]; then cp_protected "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"; fi
done
success "Agents 已安装"

info "安装 Codex 兼容 → $AGENTS_DIR/"
mkdir -p "$AGENTS_DIR/skills/mims/references" "$AGENTS_DIR/agents"
cp_protected "$CLAUDE_DIR/skills/mims/SKILL.md" "$AGENTS_DIR/skills/mims/SKILL.md"
for ref in "$CLAUDE_DIR/skills/mims/references/"*; do
    if [ -f "$ref" ]; then cp_protected "$ref" "$AGENTS_DIR/skills/mims/references/$(basename "$ref")"; fi
done
for agent in "$CLAUDE_DIR/agents/"mims-*.md; do
    if [ -f "$agent" ]; then cp_protected "$agent" "$AGENTS_DIR/agents/$(basename "$agent")"; fi
done
if [ -f "$PACKAGE_DIR/AGENTS.md" ]; then cp_protected "$PACKAGE_DIR/AGENTS.md" "$AGENTS_DIR/AGENTS.md"; fi
success "Codex 兼容已安装"

mkdir -p "$MIMS_HOME"
cat > "$MIMS_HOME/update.sh.new" << 'UPDATE_EOF'
#!/bin/bash
# MIMS updater (Linux/macOS) — 加固版
set -euo pipefail
STATE_FILE="$HOME/.mims/install-state.json"
CONFIG_FILE="$HOME/.mims/config"
MIMS_PROJECT_PATH_ENCODED="antwork%2FCloudServer%2Fit%2FMIMS"
GITHUB_RAW="https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh"
GITLAB_API="https://gitlab.xyitech.com/api/v4/projects/${MIMS_PROJECT_PATH_ENCODED}"
GITLAB_INSTALLER_RAW="${GITLAB_API}/repository/files/install%2Finstall-global.sh/raw?ref=main"

FORWARD=()
FORCE_SOURCE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from) FORCE_SOURCE="$2"; FORWARD+=(--from "$2"); shift 2 ;;
        --check|--edge|--silent) FORWARD+=("$1"); shift ;;
        github|gitlab|auto) FORCE_SOURCE="$1"; shift ;;
        *) FORWARD+=("$1"); shift ;;
    esac
done
resolve_source() {
    local s=""
    [ -n "${MIMS_SOURCE:-}" ] && s="$MIMS_SOURCE"
    [ -n "$FORCE_SOURCE" ] && s="$FORCE_SOURCE"
    if [ -z "$s" ] || [ "$s" = "auto" ]; then
        if [ -f "$CONFIG_FILE" ]; then s=$(grep -E '^source=' "$CONFIG_FILE" | head -1 | cut -d= -f2 | sed 's/[[:space:]]//g'); fi
    fi
    if { [ -z "$s" ] || [ "$s" = "auto" ]; } && [ -f "$STATE_FILE" ]; then
        s=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("source",""))' "$STATE_FILE" 2>/dev/null || echo "")
    fi
    [ -z "$s" ] && s="github"
    case "$s" in github|gitlab) echo "$s" ;; *) echo "github" ;; esac
}
resolve_token() {
    if [ -n "${MIMS_TOKEN:-}" ]; then echo "$MIMS_TOKEN"; return 0; fi
    if [ -f "$CONFIG_FILE" ]; then grep -E '^gitlab_token=' "$CONFIG_FILE" | head -1 | cut -d= -f2- | sed 's/[[:space:]]//g'; fi
}
SOURCE="$(resolve_source)"
echo "MIMS updater source: $SOURCE"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
if [ "$SOURCE" = "gitlab" ]; then
    TOK="$(resolve_token)"
    if [ -n "$TOK" ]; then
        CFG="$(mktemp)"; chmod 600 "$CFG"; printf 'header = "PRIVATE-TOKEN: %s"\nconnect-timeout = "10"\nmax-time = "120"\n' "$TOK" > "$CFG"
        curl -fsSL --config "$CFG" "$GITLAB_INSTALLER_RAW" -o "$TMP" || { rm -f "$CFG"; echo "下载 install-global.sh 失败（GitLab）。确认 token 与网络。" >&2; exit 1; }
        rm -f "$CFG"
    else
        curl -fsSL --connect-timeout 10 --max-time 120 "$GITLAB_INSTALLER_RAW" -o "$TMP" || { echo "下载失败：GitLab 私有库需要 MIMS_TOKEN / ~/.mims/config" >&2; exit 1; }
    fi
else
    curl -fsSL --connect-timeout 10 --max-time 120 "$GITHUB_RAW" -o "$TMP" || { echo "下载 install-global.sh 失败（GitHub）" >&2; exit 1; }
fi
case "$(head -c2 "$TMP")" in
    \#!) ;;
    *) echo "下载的内容不是脚本（可能为错误页）。已中止。" >&2; head -c 200 "$TMP" >&2; exit 1 ;;
esac
bash "$TMP" "${FORWARD[@]}"
UPDATE_EOF
chmod +x "$MIMS_HOME/update.sh.new"
mv "$MIMS_HOME/update.sh.new" "$MIMS_HOME/update.sh"

cat > "$MIMS_HOME/update.ps1" << 'UPDATEPS1_EOF'
# MIMS updater (Windows PowerShell) — 加固版
param(
    [ValidateSet("github","gitlab","auto")]
    [string]$SourceKind = "auto",
    [switch]$Check,
    [switch]$Edge,
    [switch]$Silent
)
$ErrorActionPreference = "Stop"
$StateFile = Join-Path $HOME ".mims\install-state.json"
$ConfigFile = Join-Path $HOME ".mims\config"
$ProjEnc = "antwork%2FCloudServer%2Fit%2FMIMS"
$GithubRaw = "https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1"
$GitlabInstaller = "https://gitlab.xyitech.com/api/v4/projects/$ProjEnc/repository/files/install%2Finstall-global.ps1/raw?ref=main"
function Read-Config($Key) {
    if (Test-Path $ConfigFile) {
        foreach ($line in Get-Content $ConfigFile) {
            if ($line -match "^\s*$Key\s*=\s*(.*)$") { return $matches[1].Trim() }
        }
    }
    return $null
}
if ($SourceKind -eq "auto" -or $SourceKind -eq "local") {
    if ($env:MIMS_SOURCE) { $SourceKind = $env:MIMS_SOURCE }
    elseif ($s = Read-Config "source") { $SourceKind = $s }
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
    } else {
        Invoke-WebRequest -Uri $GithubRaw -OutFile $tmp -UseBasicParsing
    }
    $head = (Get-Content $tmp -TotalCount 1 -ErrorAction SilentlyContinue)
    if ($head -notmatch "^#|^param\(") { throw "下载的内容不是脚本（可能为错误页）" }
    $fwd = @(); if ($Check) { $fwd += "-Check" }; if ($Edge) { $fwd += "-Edge" }; if ($Silent) { $fwd += "-Silent" }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tmp -SourceKind $SourceKind @fwd
} finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
UPDATEPS1_EOF

SOURCE_KIND_FINAL="$SOURCE_KIND"
PROJECT_MARKERS_JSON="$(json_array "${PROJECT_MARKERS[@]}")"
PREFLIGHT_ISSUES_JSON="$(json_array "${PREFLIGHT_ISSUES[@]}")"
RC_FOR_STATE="$(remote_commit 2>/dev/null | tr -d '[:space:]' || true)"
COMMIT_FOR_STATE="${PACKAGE_COMMIT:-$RC_FOR_STATE}"
cat > "$STATE_FILE" << EOF
{
  "version": "$PACKAGE_VERSION",
  "commit": "$COMMIT_FOR_STATE",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "$SOURCE_KIND_FINAL",
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
success "本地更新器已写入：$MIMS_HOME/update.sh / update.ps1"
success "回滚脚本已写入：$MIMS_HOME/rollback.sh"
success "安装状态已写入：$STATE_FILE"

refresh_last_install

if [ -f "$PACKAGE_DIR/CHANGELOG.md" ]; then
    echo ""
    echo -e "${CYAN}本次升级变更（CHANGELOG）：${NC}"
    sed -n '1,40p' "$PACKAGE_DIR/CHANGELOG.md"
fi

MISSING=0
for required in \
    "$CLAUDE_DIR/skills/mims/SKILL.md" "$CLAUDE_DIR/skills/mims/references/schema-contract.md" \
    "$CLAUDE_DIR/skills/mims/references/schema.md" "$CLAUDE_DIR/agents/mims-validator.md" \
    "$AGENTS_DIR/skills/mims/SKILL.md" "$AGENTS_DIR/skills/mims/references/schema-contract.md" \
    "$AGENTS_DIR/skills/mims/references/schema.md" "$AGENTS_DIR/agents/mims-validator.md"; do
    if [ ! -f "$required" ]; then warn "缺失：$required"; MISSING=1; fi
done
if [ "$MISSING" -eq 0 ]; then success "安装自检通过"; fi

if { [ -n "${MIMS_TOKEN:-}" ] || [ -n "${MIMS_SOURCE:-}" ] || [ -n "$FORCE_SOURCE" ]; } && [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$MIMS_HOME"
    {
        echo "source=$SOURCE_KIND_FINAL"
        if [ -n "${MIMS_TOKEN:-}" ]; then echo "gitlab_token=$MIMS_TOKEN"; fi
    } | (umask 077; cat > "$CONFIG_FILE")
    success "已写入配置：$CONFIG_FILE（权限 0600）"
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
