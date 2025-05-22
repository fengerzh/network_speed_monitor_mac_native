# NetworkSpeedMonitor

一个简洁的 macOS 菜单栏网络速度与CPU监控工具。

## 功能
- 实时显示当前电脑的网络下载速度、上传速度（自适应单位：B/s、KB/s、MB/s）
- 实时显示全系统CPU占用率（百分比，差分算法，动态刷新）
- 显示本地时间（时:分）
- 界面纵向排列，深色半透明圆角背景，窗口可拖动、置顶
- 菜单栏图标，支持深色模式
- 菜单栏菜单：关于、退出
- 网络异常时显示"--"

## 安装与使用
1. 编译并打包为 .app 应用（见 main.swift 注释或本项目 issue 区）
2. 将 `NetworkSpeedMonitor.app` 复制到 `/Applications/`
3. 双击启动，或在 Launchpad/应用程序中启动

## 关于
- 软件名称：NetworkSpeedMonitor
- 版本号：1.0.2
- 作者：zhangjing

## 开源协议
MIT 