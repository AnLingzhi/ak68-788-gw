#!/bin/bash

# WebSocket AT Gateway 通用编译脚本
# 支持多种架构和优化选项

set -e

# 显示帮助信息
show_help() {
    echo "WebSocket AT Gateway 编译脚本"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -a, --arch <架构>    目标架构 (x86_64, aarch64, armv7, all)"
    echo "  -o, --optimize       启用额外优化 (UPX压缩等)"
    echo "  -h, --help           显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                    # 编译当前平台版本"
    echo "  $0 -a aarch64        # 编译aarch64版本"
    echo "  $0 -a all            # 编译所有架构"
    echo "  $0 -a x86_64 -o      # 编译并优化x86_64版本"
}

# 默认参数
ARCH="native"
OPTIMIZE=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -o|--optimize)
            OPTIMIZE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "=== WebSocket AT Gateway 编译脚本 ==="
echo

# 清理之前的构建
echo "清理之前的构建..."
cargo clean

# 编译当前平台版本
if [ "$ARCH" = "native" ] || [ "$ARCH" = "all" ]; then
    echo "编译当前平台版本..."
    cargo build --release
    
    echo "当前平台版本编译完成!"
    ls -lh target/release/websocket-at-gateway
    echo
fi

# 编译x86_64 musl版本
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "all" ]; then
    echo "编译x86_64 musl版本..."
    
    if [ "$OPTIMIZE" = true ]; then
        RUSTFLAGS="-C opt-level=z -C lto=fat -C codegen-units=1 -C panic=abort -C strip=symbols" \
        cargo build --release --target x86_64-unknown-linux-musl
        
        # 进一步strip
        strip -s target/x86_64-unknown-linux-musl/release/websocket-at-gateway
        
        # UPX压缩（如果可用）
        if command -v upx &> /dev/null; then
            echo "使用UPX压缩..."
            upx --best --lzma target/x86_64-unknown-linux-musl/release/websocket-at-gateway
        fi
    else
        cargo build --release --target x86_64-unknown-linux-musl
    fi
    
    echo "x86_64版本编译完成!"
    ls -lh target/x86_64-unknown-linux-musl/release/websocket-at-gateway
    echo
fi

# 编译aarch64版本
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "all" ]; then
    echo "编译aarch64版本..."
    
    # 检查是否安装了交叉编译工具
    if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
        echo "警告: 未安装aarch64交叉编译工具"
        echo "请运行: sudo apt-get install gcc-aarch64-linux-gnu libc6-dev-arm64-cross"
        echo "跳过aarch64编译"
    else
        rustup target add aarch64-unknown-linux-gnu 2>/dev/null || true
        
        export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
        export CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc
        export AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar
        
        cargo build --release --target aarch64-unknown-linux-gnu
        
        echo "aarch64版本编译完成!"
        ls -lh target/aarch64-unknown-linux-gnu/release/websocket-at-gateway
        file target/aarch64-unknown-linux-gnu/release/websocket-at-gateway
        echo
    fi
fi

# 编译armv7版本
if [ "$ARCH" = "armv7" ] || [ "$ARCH" = "all" ]; then
    echo "编译armv7版本..."
    
    # 检查是否安装了交叉编译工具
    if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
        echo "警告: 未安装armv7交叉编译工具"
        echo "请运行: sudo apt-get install gcc-arm-linux-gnueabihf libc6-dev-armhf-cross"
        echo "跳过armv7编译"
    else
        rustup target add armv7-unknown-linux-gnueabihf 2>/dev/null || true
        
        export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
        export CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
        export AR_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-ar
        
        cargo build --release --target armv7-unknown-linux-gnueabihf
        
        echo "armv7版本编译完成!"
        ls -lh target/armv7-unknown-linux-gnueabihf/release/websocket-at-gateway
        echo
    fi
fi

echo "=== 编译完成 ==="
echo

# 显示所有可用的二进制文件
echo "可用的二进制文件:"
find target -name "websocket-at-gateway" -type f -executable | while read -r file; do
    echo "  $file ($(ls -lh "$file" | awk '{print $5}'))"
done