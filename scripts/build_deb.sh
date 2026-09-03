#!/usr/bin/env bash
# 构建 Hopp 的 .deb 安装包（一条命令端到端）。
#
# 用法：
#   ./scripts/build_deb.sh                 # flutter 取 PATH
#   FLUTTER=/path/to/flutter ./scripts/build_deb.sh
#
# 产物：build/deb/hopp_<version>_<arch>.deb
set -euo pipefail

cd "$(dirname "$0")/.."

FLUTTER="${FLUTTER:-flutter}"

# ---- 版本与架构 -------------------------------------------------------------
VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
case "$(uname -m)" in
  aarch64) FLUTTER_ARCH=arm64; DEB_ARCH=arm64 ;;
  x86_64)  FLUTTER_ARCH=x64;   DEB_ARCH=amd64 ;;
  *) echo "不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac

PKG="hopp_${VERSION}_${DEB_ARCH}"
STAGE="build/deb/${PKG}"
DEB="build/deb/${PKG}.deb"

# ---- 构建 release bundle -----------------------------------------------------
"$FLUTTER" build linux --release

BUNDLE="build/linux/${FLUTTER_ARCH}/release/bundle"
[ -x "${BUNDLE}/hopp" ] || { echo "未找到构建产物: ${BUNDLE}" >&2; exit 1; }

# ---- 组装包结构 --------------------------------------------------------------
rm -rf "${STAGE}"
mkdir -p "${STAGE}/DEBIAN" \
         "${STAGE}/usr/bin" \
         "${STAGE}/usr/lib/hopp" \
         "${STAGE}/usr/share/applications" \
         "${STAGE}/usr/share/icons/hicolor/512x512/apps" \
         "${STAGE}/usr/share/icons/hicolor/scalable/apps"

sed -e "s/@VERSION@/${VERSION}/" -e "s/@ARCH@/${DEB_ARCH}/" \
    packaging/linux/control > "${STAGE}/DEBIAN/control"

cp -a "${BUNDLE}/." "${STAGE}/usr/lib/hopp/"
install -m 755 packaging/linux/hopp "${STAGE}/usr/bin/hopp"
install -m 644 packaging/linux/hopp.desktop \
    "${STAGE}/usr/share/applications/hopp.desktop"
install -m 644 assets/images/logo.svg.png \
    "${STAGE}/usr/share/icons/hicolor/512x512/apps/hopp.png"
install -m 644 assets/images/logo.svg \
    "${STAGE}/usr/share/icons/hicolor/scalable/apps/hopp.svg"

# ---- 打包与自检 ---------------------------------------------------------------
dpkg-deb --build --root-owner-group "${STAGE}"
dpkg-deb -I "${DEB}"
desktop-file-validate "${STAGE}/usr/share/applications/hopp.desktop"

echo "==> 产物: ${DEB}"
echo "    安装: sudo dpkg -i ${DEB}    卸载: sudo dpkg -r hopp"
