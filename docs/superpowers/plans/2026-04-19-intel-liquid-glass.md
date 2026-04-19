# NetSpeed Intel 适配 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不修改业务逻辑的前提下完成 Intel 兼容性收口，并产出一套新的 Liquid Glass 图标资源。

**Architecture:** 兼容性调整集中在包声明、Info.plist、文档和打包资源层。业务逻辑不变，通过测试锁定产品级配置和图标主资源，图标生成交给独立脚本处理。

**Tech Stack:** SwiftPM, AppKit, Swift Testing, zsh, macOS iconutil/sips

---

### Task 1: 锁定兼容性与资源回归测试

**Files:**
- Create: `Tests/NetSpeedTests/ProjectCompatibilityTests.swift`
- Test: `Tests/NetSpeedTests/ProjectCompatibilityTests.swift`

- [ ] Step 1: 写出失败测试，约束最低系统版本与主图标资源存在
- [ ] Step 2: 运行 `swift test`，确认测试先失败
- [ ] Step 3: 修改配置与资源后再运行 `swift test`

### Task 2: 调整 Intel 产品声明

**Files:**
- Modify: `Package.swift`
- Modify: `Support/Info.plist`
- Modify: `README.md`

- [ ] Step 1: 将包平台声明与 app bundle 最低系统版本统一到 `macOS 13`
- [ ] Step 2: 更新 README 中的架构与系统要求说明
- [ ] Step 3: 保持所有业务逻辑文件不变

### Task 3: 建立图标生成流水线

**Files:**
- Create: `scripts/render_app_icon.sh`
- Create: `macos/AppIconMaster.png`
- Modify: `macos/AppIcon16.png`
- Modify: `macos/AppIcon32.png`
- Modify: `macos/AppIcon64.png`
- Modify: `macos/AppIcon128.png`
- Modify: `macos/AppIcon256.png`
- Modify: `macos/AppIcon512.png`
- Modify: `macos/AppIcon1024.png`
- Modify: `macos/AppIcon.icns`

- [ ] Step 1: 保存新的 1024 主图
- [ ] Step 2: 用脚本生成全部缩放位图与 `.icns`
- [ ] Step 3: 确认打包脚本继续消费同一路径的 `AppIcon.icns`

### Task 4: 端到端验证

**Files:**
- Modify: `README.md`

- [ ] Step 1: 运行 `swift test`
- [ ] Step 2: 运行 `./scripts/build_app.sh`
- [ ] Step 3: 用 `file` 确认打包后的可执行文件是 `x86_64`
- [ ] Step 4: 启动 `dist/NetSpeed.app` 并确认进程存在
