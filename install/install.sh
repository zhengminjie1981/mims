#!/bin/bash
# MIMS 一键安装脚本 (Linux/macOS)
#
# 用法：
#   curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash
#
#   或指定安装目录：
#   curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash -s -- /path/to/project

set -e

# 版本配置
MIMS_VERSION="1.1.0"
GITHUB_ZIP="https://github.com/zhengminjie1981/mims/archive/refs/tags/v${MIMS_VERSION}.zip"
GITLAB_ZIP="https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/archive/v${MIMS_VERSION}/MIMS-v${MIMS_VERSION}.zip"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# 欢迎信息
clear
echo ""
echo -e "${CYAN}╔════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     MIMS v${MIMS_VERSION} 安装程序     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════╝${NC}"
echo ""
echo -e "迷悟师 — ${GREEN}Make Idea Make Sense${NC}"
echo "通过对话帮助非技术用户完成软件设计"
echo ""

# 检查 Claude Code
info "检查 Claude Code..."
if ! command -v claude &> /dev/null; then
    echo ""
    warn "未检测到 Claude Code CLI"
    echo ""
    echo "请先安装 Claude Code："
    echo "  https://claude.ai/code" | cat
    echo ""
    exit 1
fi
CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "未知版本")
success "Claude Code 已安装（$CLAUDE_VERSION）"
echo ""

# 确定目标目录
TARGET_DIR="${1:-$(pwd)}"
info "安装目录：$TARGET_DIR"
echo ""

# 检查目标目录
if [ ! -d "$TARGET_DIR" ]; then
    error "目录不存在：$TARGET_DIR"
fi

# 检查是否已安装
VERSION_FILE="$TARGET_DIR/.mims-version"
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(head -1 "$VERSION_FILE")
    warn "检测到已安装 MIMS v$CURRENT_VERSION"
    echo ""
    read -p "是否升级到 v${MIMS_VERSION}？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "开始升级..."
    else
        info "安装已取消"
        exit 0
    fi
    echo ""
fi

# 选择安装方式
echo -e "${CYAN}请选择安装方式：${NC}"
echo ""
echo -e "  ${GREEN}1. 自动下载安装（GitHub，推荐）${NC}"
echo "     • 自动下载 zip 并安装到当前目录"
echo "     • 需要公网访问"
echo ""
echo -e "  ${YELLOW}2. 手动下载安装${NC}"
echo "     • 从 GitLab 或 GitHub 手动下载 zip"
echo "     • 适合内网环境或网络受限场景"
echo ""
read -p "请输入 1 或 2: " choice

if [ "$choice" = "1" ]; then
    # 方式1：自动下载安装
    echo ""
    info "从 GitHub 下载 MIMS v${MIMS_VERSION}..."

    TEMP_DIR=$(mktemp -d)
    ZIP_FILE="$TEMP_DIR/mims.zip"

    trap "rm -rf $TEMP_DIR" EXIT

    if command -v curl &> /dev/null; then
        curl -sSL "$GITHUB_ZIP" -o "$ZIP_FILE"
    elif command -v wget &> /dev/null; then
        wget -qO "$ZIP_FILE" "$GITHUB_ZIP"
    else
        error "需要 curl 或 wget"
    fi

    success "下载完成"
    echo ""

elif [ "$choice" = "2" ]; then
    # 方式2：手动下载安装
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│               手动下载安装指引                       │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${YELLOW}下载链接（任选其一）：${NC}"
    echo ""
    echo -e "  ${GREEN}GitHub（公网，推荐）：${NC}"
    echo "    $GITHUB_ZIP" | cat
    echo ""
    echo -e "  ${YELLOW}GitLab（企业内网）：${NC}"
    echo "    $GITLAB_ZIP" | cat
    echo "    （需要登录 GitLab）"
    echo ""
    echo -e "${YELLOW}步骤：${NC}"
    echo "  1. 点击上面其中一个链接，或在浏览器中复制打开"
    echo "  2. 下载 zip 文件到任意位置"
    echo "  3. 记住下载路径"
    echo "  4. 回到此窗口继续"
    echo ""
    read -p "下载完成后按 Enter 继续: "

    echo ""
    info "请输入 zip 文件的完整路径："
    read -p "路径: " ZIP_PATH

    # 移除引号
    ZIP_PATH=$(echo "$ZIP_PATH" | sed "s/^['\"]//;s/['\"]$//")

    if [ ! -f "$ZIP_PATH" ]; then
        error "文件不存在：$ZIP_PATH"
    fi

    TEMP_DIR=$(mktemp -d)
    ZIP_FILE="$TEMP_DIR/mims.zip"

    trap "rm -rf $TEMP_DIR" EXIT

    cp "$ZIP_PATH" "$ZIP_FILE"
    success "已复制 zip 文件"
    echo ""

else
    error "无效选择：$choice"
fi

# 解压和安装
info "解压文件..."

cd "$TEMP_DIR"

if command -v unzip &> /dev/null; then
    unzip -q "$ZIP_FILE"
elif command -v python3 &> /dev/null; then
    python3 -m zipfile -e "$ZIP_FILE" .
else
    error "需要 unzip 或 python3"
fi

success "解压完成"

# 查找解压后的目录
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "MIMS-*" -o -name "mims-*" | head -1)

if [ -z "$EXTRACTED_DIR" ]; then
    error "发布包格式错误：找不到 MIMS 目录"
fi

# 备份现有配置
BACKUP_DIR=""
CLAUDE_DIR="$TARGET_DIR/.claude"

if [ -d "$CLAUDE_DIR" ]; then
    echo ""
    info "备份现有配置..."
    BACKUP_DIR="$TARGET_DIR/.claude.backup.$(date +%Y%m%d%H%M%S)"
    mv "$CLAUDE_DIR" "$BACKUP_DIR"
    success "已备份到：$BACKUP_DIR"
fi

# 安装文件
echo ""
info "安装文件..."

IMPL_DIR="$EXTRACTED_DIR/impl"
if [ ! -d "$IMPL_DIR" ]; then
    error "发布包格式错误：缺少 impl 目录"
fi

# 复制所有文件到目标目录
cp -r "$IMPL_DIR"/* "$TARGET_DIR/"

success "核心文件已安装"

# 创建版本文件
cat > "$TARGET_DIR/.mims-version" << EOF
$MIMS_VERSION
source: manual
repo: https://github.com/zhengminjie1981/mims
installed: $(date '+%Y-%m-%d %H:%M:%S')
EOF
success "版本标识已创建"

# 完成
echo ""
echo -e "${GREEN}╔════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         ✓ 安装完成！              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════╝${NC}"
echo ""
echo "已安装版本：v$MIMS_VERSION"
echo "安装目录：$TARGET_DIR"
echo ""
echo -e "${CYAN}安装的文件：${NC}"
echo "  ├── CLAUDE.md          # 迷悟师人设（加载到 Claude Code）"
echo "  ├── README.md          # 安装说明"
echo "  ├── USER_GUIDE.md      # 用户手册"
echo "  ├── .mims-version      # 版本标识"
echo "  └── .claude/           # 核心实现"
echo "      ├── agents/        # 子代理"
echo "      └── skills/mims/   # 工作流和知识库"
echo ""
echo -e "${CYAN}下一步：${NC}"
echo "  1. cd $TARGET_DIR"
echo "  2. claude"
echo "  3. 输入 ${GREEN}/mims${NC} 开始使用"
echo ""
echo -e "${CYAN}文档：${NC}"
echo "  • 用户手册：$TARGET_DIR/USER_GUIDE.md"
echo "  • GitHub：https://github.com/zhengminjie1981/mims"
echo ""

# 备份提示
if [ -n "$BACKUP_DIR" ]; then
    warn "备份目录：$BACKUP_DIR"
    echo "  如需恢复自定义配置，请手动合并以下文件："
    echo "  • .claude/agents/ 中的自定义子代理"
    echo "  • .claude/skills/ 中的自定义技能"
    echo ""
fi

echo -e "${GREEN}安装完成！祝您使用愉快！ 🎉${NC}"
echo ""
