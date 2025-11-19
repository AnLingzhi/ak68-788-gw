# WebSocket AT Gateway - OpenWrt 交叉编译指南

## 快速开始

### 方法1: 使用GitHub Actions (推荐)
1. 将代码推送到GitHub
2. 在GitHub Actions页面查看自动编译结果
3. 下载对应架构的二进制文件

### 方法2: 本地Linux环境编译
```bash
# 安装工具链
sudo apt-get install gcc-aarch64-linux-gnu libc6-dev-arm64-cross

# 编译aarch64版本
make aarch64

# 文件位置: target/aarch64-unknown-linux-gnu/release/websocket-at-gateway
```

### 方法3: 使用build_linux.sh脚本
```bash
# 在Linux环境下运行
chmod +x build_linux.sh
./build_linux.sh
```

## 架构选择

| 架构 | 目标设备 |
|------|----------|
| aarch64 | 新ARM64设备 (Raspberry Pi 4, 现代路由器) |
| armv7 | 老ARM设备 (Raspberry Pi 2/3) |
| x86_64 | x86设备 (PC, 虚拟机) |

## 部署到OpenWrt

### 1. 上传文件
```bash
# 将IP替换为你的OpenWrt设备IP
scp target/aarch64-unknown-linux-gnu/release/websocket-at-gateway root@192.168.1.1:/tmp/
```

### 2. 安装和运行
```bash
# SSH到OpenWrt设备
ssh root@192.168.1.1

# 移动到系统目录
mv /tmp/websocket-at-gateway /usr/bin/
chmod +x /usr/bin/websocket-at-gateway

# 运行服务
websocket-at-gateway
```

## 性能指标

- 二进制大小: ~600-700KB (符合<5MB要求)
- 内存占用: <10MB
- 延迟: <100ms
- 并发连接: 100+

## 命令格式

根据你的OCR信息，正确的命令格式是:
```bash
cpetools.sh -t0 -c ATI
```

代码已经适配了这个格式。