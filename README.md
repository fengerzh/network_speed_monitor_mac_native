# NetworkSpeedMonitor

![软件界面预览](demo.png)

一个简洁美观的 macOS 菜单栏网络、CPU、内存、电池电量监控工具，支持窗口穿透、咖啡防睡眠与全局快捷键。

## 功能
- 实时显示当前电脑的网络速度，下载/上传合并为一行，格式为"⬇️12.3M/2.1M⬆️"，单位只显示G/M/K
- 实时显示全系统CPU占用率（百分比，差分算法，动态刷新）
- 实时显示已用物理内存（GB，单位自动缩小字号）
- 实时显示电池电量百分比（如无电池则显示--）
- 显示本地时间（时:分），时间与咖啡模式图标居中显示
- 界面纵向排列，深色高透明圆角背景，窗口可拖动、置顶
- 菜单栏图标，支持深色模式
- 菜单栏菜单：穿透（可切换窗口是否鼠标穿透）、咖啡（防止电脑睡眠和屏保）、关于、退出
- 支持全局快捷键：
  - Control+Option+Command+T 随时显示/隐藏窗口，无论焦点在哪个应用
  - Control+Option+Command+K 一键开启/关闭咖啡模式（防止电脑睡眠和屏保），悬浮窗有咖啡图标提示
- 网络异常时显示"--"
- 所有监控指标单位美化，数值与单位分字号显示
- 代码结构清晰，易于维护和扩展

## 安装与使用

1. **推荐方式：** 直接前往 [Releases 页面](https://github.com/fengerzh/network_speed_monitor_mac_native/releases) 下载最新版 DMG 安装包，双击挂载后将 NetworkSpeedMonitor 拖入 Applications 即可。

2. **开发者方式：** 如需自行编译，可参考下列步骤：
   - 编译并打包为 .app 应用（见 main.swift 注释或本项目 issue 区）
   - 将 `NetworkSpeedMonitor.app` 复制到 `/Applications/`
   - 双击启动，或在 Launchpad/应用程序中启动
   - 可通过菜单栏"穿透"切换窗口是否响应鼠标，或用全局快捷键随时显示/隐藏窗口
   - 可通过菜单栏或快捷键一键开启/关闭咖啡模式，防止电脑进入睡眠和屏保，悬浮窗有提示
   - 电池电量会在悬浮窗最下方自动显示，无需额外设置

## 关于
- 软件名称：NetworkSpeedMonitor
- 作者：zhangjing

## 开源协议
MIT 