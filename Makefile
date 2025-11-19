# WebSocket AT Gateway 交叉编译Makefile

# 目标架构
TARGETS = aarch64-unknown-linux-musl aarch64-unknown-linux-gnu armv7-unknown-linux-gnueabihf x86_64-unknown-linux-gnu

# 默认目标
.PHONY: all clean help

all: $(TARGETS)

help:
	@echo "WebSocket AT Gateway 交叉编译"
	@echo "=========================="
	@echo "可用目标:"
	@echo "  make musl        - 编译aarch64 musl版本 (OpenWRT推荐)"
	@echo "  make aarch64     - 编译aarch64版本 (适合大多数OpenWrt)"
	@echo "  make armv7       - 编译ARMv7版本"
	@echo "  make x86_64      - 编译x86_64版本"
	@echo "  make all         - 编译所有架构"
	@echo "  make clean       - 清理编译结果"
	@echo "  make github      - 使用GitHub Actions编译"
	@echo ""
	@echo "OpenWrt架构选择:"
	@echo "  musl:    OpenWRT专用静态链接版本 (推荐)"
	@echo "  aarch64: 新ARM64设备 (如Raspberry Pi 4, 大多数现代路由器)"
	@echo "  armv7:   老ARM设备 (如Raspberry Pi 2/3)"
	@echo "  x86_64:  x86设备 (如PC, 虚拟机)"

# 单独架构编译
musl:
	@echo "编译 aarch64-unknown-linux-musl (OpenWRT静态链接版)..."
	cargo build --release --target aarch64-unknown-linux-musl

aarch64:
	@echo "编译 aarch64-unknown-linux-gnu..."
	./build.sh -a aarch64

armv7:
	@echo "编译 armv7-unknown-linux-gnueabihf..."
	./build.sh -a armv7

x86_64:
	@echo "编译 x86_64-unknown-linux-gnu..."
	./build.sh -a x86_64

# 编译所有架构
all:
	@echo "编译所有架构..."
	./build.sh -a all

# 清理
clean:
	cargo clean
	rm -rf target/

# GitHub Actions编译
github:
	@echo "推送到GitHub将自动触发交叉编译..."
	@echo "请在GitHub Actions页面查看编译进度和下载结果"

# 安装到OpenWrt (需要设备IP)
install:
	@if [ -z "$(IP)" ]; then \
		echo "用法: make install IP=192.168.1.1"; \
		echo "可选参数: ARCH=aarch64|armv7|x86_64 (默认: aarch64)"; \
		exit 1; \
	fi
	@if [ -z "$(ARCH)" ]; then \
		echo "默认使用aarch64架构，如需其他架构请设置ARCH变量"; \
		ARCH=aarch64; \
	fi
	@echo "安装到OpenWrt设备 $(IP) (架构: $(ARCH))..."
	scp target/$(ARCH)-unknown-linux-gnu/release/websocket-at-gateway root@$(IP):/tmp/
	ssh root@$(IP) "chmod +x /tmp/websocket-at-gateway && mv /tmp/websocket-at-gateway /usr/bin/"
	@echo "安装完成！"

# 测试
.PHONY: test
test:
	cargo test
	@echo "运行本地测试..."

# 检查代码
check:
	cargo check --all-targets
	@echo "代码检查完成"