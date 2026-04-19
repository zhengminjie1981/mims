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

# 参数
SILENT_MODE=false
LOCAL_SOURCE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --silent) SILENT_MODE=true; shift ;;
        --source) LOCAL_SOURCE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# 版本
MIMS_VERSION="1.2.0"
GITHUB_ZIP="https://github.com/zhengminjie1981/mims/archive/refs/tags/v${MIMS_VERSION}.zip"
GITLAB_ZIP="https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/v${MIMS_VERSION}/MIMS-v${MIMS_VERSION}.zip"

# 颜色
GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

# 目标目录
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$HOME/.agents"

echo ""
echo -e "${CYAN}MIMS v${MIMS_VERSION} 全局安装${NC}"
echo -e "迷悟师 — ${GREEN}Make Idea Make Sense${NC}"
echo ""

# 获取源文件
TEMP_DIR=""

if [ -n "$LOCAL_SOURCE" ]; then
    # 从本地目录安装
    SOURCE_DIR="$LOCAL_SOURCE"
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "错误：目录不存在：$SOURCE_DIR" >&2; exit 1
    fi
    info "从本地安装：$SOURCE_DIR"
else
    # 下载 zip
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    ZIP_FILE="$TEMP_DIR/mims.zip"

    info "下载 MIMS v${MIMS_VERSION}..."
    if command -v curl &>/dev/null; then
        curl -sSL "$GITHUB_ZIP" -o "$ZIP_FILE" || curl -sSL "$GITLAB_ZIP" -o "$ZIP_FILE"
    elif command -v wget &>/dev/null; then
        wget -qO "$ZIP_FILE" "$GITHUB_ZIP" || wget -qO "$ZIP_FILE" "$GITLAB_ZIP"
    else
        echo "错误：需要 curl 或 wget" >&2; exit 1
    fi
    success "下载完成"

    cd "$TEMP_DIR"
    unzip -q "$ZIP_FILE" 2>/dev/null || python3 -m zipfile -e "$ZIP_FILE" . 2>/dev/null
    SOURCE_DIR=$(find . -maxdepth 1 -type d -name "MIMS-*" -o -name "mims-*" | head -1)
    if [ -z "$SOURCE_DIR" ]; then
        echo "错误：无法识别发布包结构" >&2; exit 1
    fi
fi

# 定位 impl 目录
IMPL_DIR="$SOURCE_DIR/impl"
if [ ! -d "$IMPL_DIR/.claude/skills/mims" ]; then
    echo "错误：找不到 Skill 文件" >&2; exit 1
fi

# 安装 Skill
info "安装 Skill → $CLAUDE_DIR/skills/mims/"
mkdir -p "$CLAUDE_DIR/skills/mims/references"
cp "$IMPL_DIR/.claude/skills/mims/SKILL.md" "$CLAUDE_DIR/skills/mims/SKILL.md"
cp -r "$IMPL_DIR/.claude/skills/mims/references/"* "$CLAUDE_DIR/skills/mims/references/"
success "Skill 已安装"

# 安装 Agents
info "安装 Agents → $CLAUDE_DIR/agents/"
mkdir -p "$CLAUDE_DIR/agents"
for agent in "$IMPL_DIR/.claude/agents/"mims-*.md; do
    [ -f "$agent" ] && cp "$agent" "$CLAUDE_DIR/agents/"
done
success "Agents 已安装"

# Codex 兼容
info "安装 Codex 兼容 → $AGENTS_DIR/"
mkdir -p "$AGENTS_DIR/skills/mims/references"
mkdir -p "$AGENTS_DIR/agents"
cp "$CLAUDE_DIR/skills/mims/SKILL.md" "$AGENTS_DIR/skills/mims/SKILL.md"
cp -r "$CLAUDE_DIR/skills/mims/references/"* "$AGENTS_DIR/skills/mims/references/"
cp "$CLAUDE_DIR/agents/"mims-*.md "$AGENTS_DIR/agents/"
success "Codex 兼容已安装"

# 完成
echo ""
echo -e "${GREEN}✓ MIMS v${MIMS_VERSION} 全局安装完成${NC}"
echo ""
echo "安装位置："
echo "  ~/.claude/skills/mims/     ← Skill + 知识库"
echo "  ~/.claude/agents/          ← 子代理"
echo "  ~/.agents/                 ← Codex 兼容"
echo ""
echo "使用方式："
echo "  进入任意项目目录 → 输入 ${GREEN}/mims${NC} 开始"
echo ""
