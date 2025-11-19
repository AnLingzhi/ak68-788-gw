# 交叉编译WebSocket AT Gateway到aarch64 OpenWrt

## 方案1: 使用GitHub Actions (推荐)

创建一个 `.github/workflows/cross-compile.yml` 文件：

```yaml
name: Cross Compile for OpenWrt

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Rust
      uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
        target: aarch64-unknown-linux-gnu
        override: true
    
    - name: Install cross
      run: cargo install cross
    
    - name: Build for aarch64
      run: cross build --release --target aarch64-unknown-linux-gnu
    
    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: websocket-at-gateway-aarch64
        path: target/aarch64-unknown-linux-gnu/release/websocket-at-gateway
```

## 方案2: 使用Linux虚拟机

### 步骤1: 安装交叉编译工具链
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gcc-aarch64-linux-gnu libc6-dev-arm64-cross

# CentOS/RHEL
sudo yum install -y gcc-aarch64-linux-gnu glibc-devel-aarch64
```

### 步骤2: 安装Rust和目标
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup target add aarch64-unknown-linux-gnu
```

### 步骤3: 配置和编译
```bash
# 克隆代码
git clone <your-repo>
cd websocket-at-gateway

# 设置环境变量
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
export CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc
export AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar

# 编译
cargo build --release --target aarch64-unknown-linux-gnu

# 检查文件
file target/aarch64-unknown-linux-gnu/release/websocket-at-gateway
```

## 方案3: 在OpenWrt设备上直接编译

如果你的OpenWrt设备有足够的资源（内存>1GB，存储>2GB）：

```bash
# 在OpenWrt设备上安装Rust
wget -O - https://sh.rustup.rs | sh
source ~/.profile

# 克隆并编译
git clone <your-repo>
cd websocket-at-gateway
cargo build --release

# 生成的文件可以直接使用
```

## 验证编译结果

编译完成后，验证文件格式：

```bash
$ file websocket-at-gateway
websocket-at-gateway: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped

$ ls -lh websocket-at-gateway
-rwxr-xr-x 1 user user 641K Nov 19 15:00 websocket-at-gateway
```

## 部署到OpenWrt

1. 将编译好的文件复制到OpenWrt设备：
```bash
scp websocket-at-gateway root@your-openwrt-ip:/tmp/
```

2. 在OpenWrt设备上设置权限：
```bash
ssh root@your-openwrt-ip
chmod +x /tmp/websocket-at-gateway
/tmp/websocket-at-gateway
```

## 注意事项

- 静态链接的二进制文件会比较大，但兼容性更好
- 确保目标OpenWrt设备的CPU架构确实是aarch64
- 如果设备资源有限，建议使用交叉编译而不是在设备上编译
- 二进制文件大小约为600-700KB，符合<5MB的要求