#!/bin/bash

set -e

APP_NAME="NetworkSpeedMonitor"
SRC_DIR="Sources"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RES_DIR="${CONTENTS_DIR}/Resources"

# 清理旧包
rm -rf "${APP_DIR}"

# 创建目录结构
mkdir -p "${MACOS_DIR}"
mkdir -p "${RES_DIR}"

# 编译主程序（用 SwiftPM，自动包含所有源文件）
swift build -c release

# 拷贝可执行文件
cp .build/release/network_speed_monitor_mac_native "${MACOS_DIR}/${APP_NAME}"

# 拷贝资源文件
cp "Sources/Resources/netspeed.icns" "${RES_DIR}/"
cp "Sources/Resources/netspeed_menu.png" "${RES_DIR}/"

# 拷贝 Info.plist
cp "Sources/Info.plist" "${CONTENTS_DIR}/"

echo "✅ 打包完成：${APP_DIR}"
echo "你可以用 cp -R ${APP_DIR} /Applications/ 进行安装" 