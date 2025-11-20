# WebSocket AT Gateway 交叉编译Makefile

# 目标架构
TARGETS = aarch64-unknown-linux-musl

# 默认目标
.PHONY: all clean help

all: $(TARGETS)

help:
	@echo "WebSocket AT Gateway 交叉编译"
	@echo "=========================="
	@echo "可用目标:"
	@echo "  make musl        - 编译aarch64 musl版本"
	@echo "  make clean       - 清理编译结果"
	@echo "  make github      - 使用GitHub Actions编译"
	@echo ""
	@echo "OpenWrt架构选择:"
	@echo "  musl:    aarch64-unknown-linux-musl 静态链接版本"

# 单独架构编译
musl:
	@echo "编译 aarch64-unknown-linux-musl (OpenWRT静态链接版)..."
	cargo build --release --target aarch64-unknown-linux-musl

# 仅保留 MUSL 版本

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
		echo "可选参数: ARCH=aarch64 (默认: aarch64)"; \
		exit 1; \
	fi
	@if [ -n "$(ARCH)" ] && [ "$(ARCH)" != "aarch64" ]; then \
		echo "仅支持 aarch64 (musl) 架构"; \
		exit 1; \
	fi
	@echo "安装到OpenWrt设备 $(IP) (架构: aarch64-musl)..."
	scp target/aarch64-unknown-linux-musl/release/websocket-at-gateway root@$(IP):/tmp/
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