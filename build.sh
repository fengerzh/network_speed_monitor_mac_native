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

# 编译主程序
swiftc "${SRC_DIR}/main.swift" -o "${MACOS_DIR}/${APP_NAME}" -framework Cocoa

# 拷贝资源文件
cp "${SRC_DIR}/netspeed.icns" "${RES_DIR}/"
cp "${SRC_DIR}/netspeed_menu.png" "${RES_DIR}/"

# 拷贝 Info.plist
cp "${SRC_DIR}/Info.plist" "${CONTENTS_DIR}/"

echo "✅ 打包完成：${APP_DIR}"
echo "你可以用 cp -R ${APP_DIR} /Applications/ 进行安装" 