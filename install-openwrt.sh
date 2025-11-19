#!/bin/bash

# WebSocket AT Gateway OpenWRT 安装脚本
# 专为 OpenWRT 系统设计，支持自动检测架构和安装

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "WebSocket AT Gateway OpenWRT 安装脚本"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help           显示帮助信息"
    echo "  -v, --version        指定版本号 (默认: latest)"
    echo "  -a, --arch           指定架构 (自动检测如果未指定)"
    echo "  -u, --url            GitHub 仓库 URL"
    echo "  -t, --test           测试安装但不实际安装"
    echo "  -d, --download-only  只下载不安装"
    echo ""
    echo "支持的架构:"
    echo "  aarch64-musl    - ARM64 OpenWRT (推荐)"
    echo "  aarch64-gnu    - ARM64 标准Linux"
    echo "  armv7          - ARMv7 老设备"
    echo "  x86_64         - x86_64 PC/虚拟机"
    echo ""
    echo "示例:"
    echo "  $0                                    # 自动检测并安装最新版"
    echo "  $0 -a aarch64-musl -v v2              # 安装指定版本"
    echo "  $0 -d                                 # 只下载不安装"
    echo "  $0 -t                                 # 测试模式"
}

# 默认参数
VERSION="latest"
ARCH=""
REPO_URL="https://github.com/AnLingzhi/ak68-788-gw"
TEST_MODE=false
DOWNLOAD_ONLY=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -u|--url)
            REPO_URL="$2"
            shift 2
            ;;
        -t|--test)
            TEST_MODE=true
            shift
            ;;
        -d|--download-only)
            DOWNLOAD_ONLY=true
            shift
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检测系统架构
detect_arch() {
    local machine=$(uname -m)
    local system=$(uname -s)
    
    echo -e "${YELLOW}检测系统信息:${NC}"
    echo "  架构: $machine"
    echo "  系统: $system"
    echo "  内核: $(uname -r)"
    echo ""
    
    case $machine in
        aarch64|arm64)
            # 检测是否是 OpenWRT (通常使用 musl)
            if [[ -f "/lib/libc.so" ]] && grep -q musl /lib/libc.so 2>/dev/null; then
                echo "aarch64-musl"
            elif [[ -f "/lib/ld-musl-aarch64.so.1" ]]; then
                echo "aarch64-musl"
            else
                echo "aarch64-gnu"
            fi
            ;;
        armv7l|armv7)
            echo "armv7"
            ;;
        x86_64)
            echo "x86_64"
            ;;
        *)
            echo -e "${RED}不支持的架构: $machine${NC}"
            exit 1
            ;;
    esac
}

# 获取下载 URL
get_download_url() {
    local arch=$1
    local version=$2
    
    # 映射架构到目标名称
    local target=""
    case $arch in
        aarch64-musl)
            target="aarch64-unknown-linux-musl"
            ;;
        aarch64-gnu)
            target="aarch64-unknown-linux-gnu"
            ;;
        armv7)
            target="armv7-unknown-linux-gnueabihf"
            ;;
        x86_64)
            target="x86_64-unknown-linux-gnu"
            ;;
        *)
            echo -e "${RED}未知的架构映射: $arch${NC}"
            exit 1
            ;;
    esac
    
    if [[ "$version" == "latest" ]]; then
        echo "${REPO_URL}/releases/latest/download/websocket-at-gateway-${target}.tar.gz"
    else
        echo "${REPO_URL}/releases/download/${version}/websocket-at-gateway-${target}.tar.gz"
    fi
}

# 主安装流程
main() {
    echo -e "${GREEN}WebSocket AT Gateway OpenWRT 安装器${NC}"
    echo "=========================================="
    echo ""
    
    # 检测架构（如果未指定）
    if [[ -z "$ARCH" ]]; then
        ARCH=$(detect_arch)
        echo -e "${GREEN}自动检测到架构: $ARCH${NC}"
    else
        echo -e "${GREEN}使用指定架构: $ARCH${NC}"
    fi
    echo ""
    
    # 获取下载 URL
    DOWNLOAD_URL=$(get_download_url "$ARCH" "$VERSION")
    echo -e "${YELLOW}下载地址:${NC}"
    echo "  $DOWNLOAD_URL"
    echo ""
    
    if [[ "$TEST_MODE" == true ]]; then
        echo -e "${YELLOW}测试模式 - 不执行实际安装${NC}"
        echo "将下载: websocket-at-gateway-$ARCH.tar.gz"
        exit 0
    fi
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    echo -e "${YELLOW}下载二进制文件...${NC}"
    if ! wget -q --show-progress "$DOWNLOAD_URL" -O "websocket-at-gateway.tar.gz"; then
        echo -e "${RED}下载失败！请检查网络连接和版本是否存在。${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}解压文件...${NC}"
    tar -xzf "websocket-at-gateway.tar.gz"
    
    if [[ ! -f "websocket-at-gateway" ]]; then
        echo -e "${RED}解压失败！找不到 websocket-at-gateway 文件${NC}"
        exit 1
    fi
    
    # 检查文件类型
    echo -e "${YELLOW}检查文件类型:${NC}"
    file "websocket-at-gateway"
    echo ""
    
    if [[ "$DOWNLOAD_ONLY" == true ]]; then
        echo -e "${GREEN}下载完成！文件保存在: $TEMP_DIR/websocket-at-gateway${NC}"
        echo "你可以手动复制到 OpenWRT 设备"
        exit 0
    fi
    
    # 安装到系统
    echo -e "${YELLOW}安装到系统...${NC}"
    
    # 备份旧版本（如果存在）
    if [[ -f "/usr/bin/websocket-at-gateway" ]]; then
        echo -e "${YELLOW}备份旧版本...${NC}"
        cp "/usr/bin/websocket-at-gateway" "/usr/bin/websocket-at-gateway.bak"
    fi
    
    # 复制新文件
    cp "websocket-at-gateway" "/usr/bin/"
    chmod +x "/usr/bin/websocket-at-gateway"
    
    # 验证安装
    echo -e "${YELLOW}验证安装...${NC}"
    if "/usr/bin/websocket-at-gateway" --version 2>/dev/null; then
        echo -e "${GREEN}安装成功！${NC}"
    else
        # 尝试检查依赖
        echo -e "${YELLOW}检查依赖...${NC}"
        if command -v ldd >/dev/null 2>&1; then
            ldd "/usr/bin/websocket-at-gateway" || true
        fi
        echo -e "${GREEN}安装完成！如果运行有问题，请检查依赖。${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}安装完成！${NC}"
    echo "二进制文件已安装到: /usr/bin/websocket-at-gateway"
    echo ""
    echo "使用方法:"
    echo "  websocket-at-gateway    # 启动服务 (默认端口 8080)"
    echo ""
    echo "如果需要，可以创建启动脚本:"
    echo "  /etc/init.d/websocket-at-gateway start"
    
    # 清理临时文件
    cd /
    rm -rf "$TEMP_DIR"
}

# 运行主函数
main "$@"