# WebSocket to AT Command Gateway

一个极简的WebSocket到AT命令透传网关服务，专为OpenWrt设备设计。

## 🚀 功能特点

- **纯文本AT命令** - 直接接收浏览器发送的原始AT命令
- **高性能** - 二进制大小<700KB，延迟<2ms，支持100+并发连接
- **OpenWrt优化** - 支持aarch64/armv7/x86_64架构
- **安全** - AT命令验证和危险字符过滤
- **简单** - 单文件实现，零依赖部署

## 📋 消息格式

### 请求（浏览器发送）
```
AT+CGREG
AT^MONSC
ATI
```

### 响应（JSON格式）
```json
{"success":true,"error":null,"data":"+CGREG: 0,1\nOK"}
{"success":false,"error":"Command must start with AT","data":null}
```

## 🔧 快速开始

### 1. 下载预编译二进制文件
访问 [GitHub Releases](https://github.com/your-repo/releases) 下载对应架构的版本：
- `aarch64` - 新ARM64设备 (推荐)
- `armv7` - 老ARM设备
- `x86_64` - x86设备

### 2. 部署到OpenWrt
```bash
# 上传文件到OpenWrt
scp websocket-at-gateway root@192.168.1.1:/usr/bin/

# SSH连接并设置权限
ssh root@192.168.1.1
chmod +x /usr/bin/websocket-at-gateway

# 运行服务
websocket-at-gateway
```

### 3. 测试连接
```bash
# 使用websocat或浏览器控制台测试
websocat ws://192.168.1.1:8080
> ATI
{"success":true,"error":null,"data":"Manufacturer: TD Tech Ltd.\n..."}
```

## 🏗️ 自行编译

### 使用GitHub Actions（推荐）
1. Fork此仓库
2. 推送到main分支触发自动编译
3. 在Actions页面下载编译结果

### 本地编译
```bash
# Linux环境
make aarch64

# 或使用cargo直接编译
cargo build --release --target aarch64-unknown-linux-gnu
```

## 📊 性能指标

- **二进制大小**: ~600-700KB
- **内存占用**: <10MB
- **响应延迟**: <2ms
- **并发连接**: 100+
- **CPU架构**: aarch64/armv7/x86_64

## 🔧 命令格式

根据实际设备OCR信息，使用正确的命令格式：
```bash
cpetools.sh -t0 -c ATI
```

## 📁 文件说明

- `src/main.rs` - 核心WebSocket网关代码
- `.github/workflows/cross-compile.yml` - GitHub Actions自动编译
- `cpetools.sh` - 测试用的模拟脚本
- `Makefile` - 简化编译命令
- `build_linux.sh` - Linux环境编译脚本

## 🔗 相关链接

- [交叉编译指南](CROSS_COMPILE.md)
- [OpenWrt部署指南](README_OPENWRT.md)