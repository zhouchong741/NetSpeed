# NetSpeed

一个基于 `SwiftPM + AppKit` 的 macOS 状态栏网速工具，支持 Intel 与 Apple Silicon 机器，实时显示下行和上行速度。

## 功能

- 状态栏用两行纵向显示 `↓下载` / `↑上传` 速度，尽量节省横向宽度。
- 点击状态栏后，菜单只保留当前活动网卡简要信息和退出按钮。
- 不依赖完整 Xcode，当前命令行工具链即可编译。

## 环境要求

- Intel Mac 或 Apple Silicon Mac
- macOS 13+
- 已安装 Command Line Tools，且可用 `swift`

## 运行

直接运行开发版：

```bash
swift run
```

当前仓库已经在 `x86_64` 环境完成过构建验证，打包后的 `.app` 为 Intel 可执行文件。

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

如需检查当前仓库的兼容性声明与图标主资源是否齐全，可执行：

```bash
swift scripts/check_compatibility.swift
```

## 自动发布 Releases

仓库已配置 GitHub Actions：当你推送版本标签（`v*`）时，会自动完成以下动作：

- 在 `macos-13`（Intel）环境编译 `NetSpeed.app`
- 校验可执行文件包含 `x86_64`
- 生成发布资产 `NetSpeed-vX.Y.Z-macos-intel.zip`
- 生成 `checksums.txt`
- 自动创建 GitHub Release，并自动生成版本说明（Release Notes）

发布命令示例：

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 实现说明

- 通过 `getifaddrs` 读取 `AF_LINK` 接口字节计数。
- 默认统计所有处于 `up/running` 状态的非回环接口，避免 `lo0` 本地 IPC 干扰速率显示。
- 菜单中的网卡信息会做简化展示：0 个显示“未检测到”，1–2 个直接列出，超过 2 个显示“en0 等 5 个”。
- 采样周期默认是 1 秒，兼顾实时性和状态栏刷新稳定性。
- 图标资源由 `macos/AppIconMaster.png` 统一生成，生成脚本在 `scripts/render_app_icon.sh`。
