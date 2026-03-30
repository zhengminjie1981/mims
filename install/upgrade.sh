#!/bin/bash
# MIMS 升级脚本
# 用法：./upgrade.sh [--version 1.1.0]

set -e

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

PROJECT_DIR=$(pwd)
VERSION_FILE="$PROJECT_DIR/.mims-version"

# 检查是否已安装
if [ ! -f "$VERSION_FILE" ]; then
    echo -e "${RED}✗${NC} 未检测到 MIMS 安装"
    echo "请先运行安装脚本："
    echo "  GitHub: curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/impl/install-github.sh | bash"
    echo "  GitLab: curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/impl/install-gitlab.sh | bash"
    exit 1
fi

# 读取当前版本和来源
CURRENT_VERSION=$(head -1 "$VERSION_FILE")
SOURCE=$(grep "^source:" "$VERSION_FILE" | cut -d: -f2- | xargs || echo "github")

# 根据来源选择安装脚本
case "$SOURCE" in
    gitlab-enterprise)
        INSTALL_SCRIPT="https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/impl/install-gitlab.sh"
        REPO_NAME="GitLab"
        ;;
    *)
        INSTALL_SCRIPT="https://raw.githubusercontent.com/zhengminjie1981/mims/main/impl/install-github.sh"
        REPO_NAME="GitHub"
        ;;
esac

echo ""
echo "当前版本：v$CURRENT_VERSION"
echo "来源：$REPO_NAME ($SOURCE)"
echo ""

info "使用 $REPO_NAME 安装脚本升级..."
curl -sSL "$INSTALL_SCRIPT" | bash -s -- "$PROJECT_DIR"
