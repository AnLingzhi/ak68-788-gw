#!/usr/bin/env bash
set -euo pipefail
PKG_NAME=websocket-at-gateway
VERSION=${VERSION:-0.1.0}
RELEASE=${RELEASE:-1}
ARCH=${ARCH:-aarch64}
BIN=${BIN:-}
OUTDIR=${OUTDIR:-dist}
if [ -z "$BIN" ]; then
  echo "BIN 未指定"
  exit 1
fi
if [ ! -f "$BIN" ]; then
  echo "二进制不存在"
  exit 1
fi
WORKDIR=$(mktemp -d)
mkdir -p "$WORKDIR/pkg/usr/bin"
mkdir -p "$WORKDIR/pkg/etc/init.d"
mkdir -p "$WORKDIR/pkg/CONTROL"
cp "$BIN" "$WORKDIR/pkg/usr/bin/$PKG_NAME"
chmod +x "$WORKDIR/pkg/usr/bin/$PKG_NAME"
cp "$(dirname "$0")/../init.d/$PKG_NAME" "$WORKDIR/pkg/etc/init.d/$PKG_NAME"
chmod +x "$WORKDIR/pkg/etc/init.d/$PKG_NAME"
cat > "$WORKDIR/pkg/CONTROL/control" <<EOF
Package: $PKG_NAME
Version: $VERSION-$RELEASE
Depends: libc
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: ak68-788-gw
Description: WebSocket AT Gateway
EOF
cat > "$WORKDIR/pkg/CONTROL/postinst" <<'EOF'
#!/bin/sh
[ -x /etc/init.d/websocket-at-gateway ] && /etc/init.d/websocket-at-gateway enable || true
exit 0
EOF
chmod +x "$WORKDIR/pkg/CONTROL/postinst"
cat > "$WORKDIR/pkg/CONTROL/prerm" <<'EOF'
#!/bin/sh
[ -x /etc/init.d/websocket-at-gateway ] && /etc/init.d/websocket-at-gateway stop || true
exit 0
EOF
chmod +x "$WORKDIR/pkg/CONTROL/prerm"
mkdir -p "$OUTDIR"
pushd "$WORKDIR/pkg" >/dev/null
tar -czf control.tar.gz CONTROL
tar -czf data.tar.gz etc usr
echo -n "2.0\n" > debian-binary
IPK_NAME="${PKG_NAME}_${VERSION}-${RELEASE}_${ARCH}.ipk"
ar -r "$IPK_NAME" control.tar.gz data.tar.gz debian-binary
popd >/dev/null
mv "$WORKDIR/pkg/$IPK_NAME" "$OUTDIR/"
echo "$OUTDIR/$IPK_NAME"
rm -rf "$WORKDIR"