import Foundation

struct CompatibilityFailure: Error, CustomStringConvertible {
    let description: String
}

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let packageRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

func readUTF8(_ relativePath: String) throws -> String {
    try String(
        contentsOf: packageRoot.appendingPathComponent(relativePath),
        encoding: .utf8
    )
}

func readPNGSize(_ relativePath: String) throws -> (Int, Int) {
    let data = try Data(contentsOf: packageRoot.appendingPathComponent(relativePath))
    guard data.count > 24 else {
        throw CompatibilityFailure(description: "\(relativePath) 不是有效 PNG")
    }

    let signature = Array(data.prefix(8))
    guard signature == [137, 80, 78, 71, 13, 10, 26, 10] else {
        throw CompatibilityFailure(description: "\(relativePath) PNG 签名错误")
    }

    let widthData = data[16..<20]
    let heightData = data[20..<24]
    let width = widthData.reduce(0) { ($0 << 8) | Int($1) }
    let height = heightData.reduce(0) { ($0 << 8) | Int($1) }
    return (width, height)
}

var failures: [String] = []

do {
    let packageContents = try readUTF8("Package.swift")
    if !packageContents.contains(".macOS(.v13)") {
        failures.append("Package.swift 还没有声明 macOS 13 兼容性")
    }
} catch {
    failures.append("读取 Package.swift 失败: \(error)")
}

do {
    let plistContents = try readUTF8("Support/Info.plist")
    if !plistContents.contains("<key>LSMinimumSystemVersion</key>") ||
        !plistContents.contains("<string>13.0</string>")
    {
        failures.append("Support/Info.plist 的最低系统版本还不是 13.0")
    }
} catch {
    failures.append("读取 Support/Info.plist 失败: \(error)")
}

do {
    let (width, height) = try readPNGSize("macos/AppIconMaster.png")
    if width != 1024 || height != 1024 {
        failures.append("macos/AppIconMaster.png 尺寸不是 1024x1024，而是 \(width)x\(height)")
    }
} catch {
    failures.append("读取 macos/AppIconMaster.png 失败: \(error)")
}

if failures.isEmpty {
    print("Compatibility checks passed.")
    exit(0)
}

for failure in failures {
    fputs("FAIL: \(failure)\n", stderr)
}
exit(1)
