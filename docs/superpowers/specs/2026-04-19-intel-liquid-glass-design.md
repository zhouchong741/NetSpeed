# NetSpeed Intel 适配与 Liquid Glass 图标设计

**目标**

在不改动网络统计与状态栏显示逻辑的前提下，让 `NetSpeed` 明确支持 Intel Mac 的构建、打包和运行，并替换为一套符合 Liquid Glass 风格的新图标资源。

**范围**

- 保持 `Sources/NetSpeedCore` 与 `Sources/NetSpeed` 的业务行为不变。
- 将产品级兼容性声明从“Apple Silicon / macOS 14+”调整为适配 Intel 的通用 macOS 版本口径。
- 更新打包资源与说明文档，使 Intel 机器上的构建、打包和验证路径清晰可重复。
- 新增一张高分辨率主图，并生成整套 `png` 与 `icns` 图标资源。

**方案**

1. 兼容性声明落在 `Package.swift` 与 `Support/Info.plist`，把最低系统版本统一到 `macOS 13`。
2. 逻辑代码不做功能变更，只增加针对工程兼容性和资源管线的测试。
3. 图标采用冷色玻璃材质、下载/上传双箭头的中心构图，保留小尺寸下的识别度。
4. 用脚本从一张 1024 主图生成全部 app icon 资源，避免后续手工维护多份位图。

**验证**

- `swift test`
- `./scripts/build_app.sh`
- `file dist/NetSpeed.app/Contents/MacOS/NetSpeed`
- `open -n dist/NetSpeed.app` 后配合 `pgrep -x NetSpeed` 验证应用可启动
