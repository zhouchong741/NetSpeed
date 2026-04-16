# NetSpeed

一个基于 `SwiftPM + AppKit` 的 macOS 状态栏网速工具，面向 Apple Silicon 机器，实时显示下行和上行速度。

## 功能

- 状态栏用两行纵向显示 `↓下载` / `↑上传` 速度，尽量节省横向宽度。
- 点击状态栏后，菜单只保留当前活动网卡简要信息和退出按钮。
- 不依赖完整 Xcode，当前命令行工具链即可编译。

## 环境要求

- Apple Silicon Mac
- macOS 14+
- 已安装 Command Line Tools，且可用 `swift`

## 运行

直接运行开发版：

```bash
swift run
```

启动后会在状态栏出现两行纵向堆叠的实时速率文本，例如：

```text
↓1.5M
↑256K
```

## 打包 `.app`

执行：

```bash
./scripts/build_app.sh
```

产物会生成到：

```text
dist/NetSpeed.app
```

可以直接双击启动，或者：

```bash
open dist/NetSpeed.app
```

## 实现说明

- 通过 `getifaddrs` 读取 `AF_LINK` 接口字节计数。
- 默认统计所有处于 `up/running` 状态的非回环接口，避免 `lo0` 本地 IPC 干扰速率显示。
- 菜单中的网卡信息会做简化展示：0 个显示“未检测到”，1–2 个直接列出，超过 2 个显示“en0 等 5 个”。
- 采样周期默认是 1 秒，兼顾实时性和状态栏刷新稳定性。
