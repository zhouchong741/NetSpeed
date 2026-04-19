import Darwin
import Testing

struct ProjectCompatibilityTests {
    private enum FileReadError: Error {
        case openFailed(String)
        case statFailed(String)
        case readFailed(String)
    }

    private var packageRoot: String {
        let filePath = String(#filePath)
        guard let testsRange = filePath.range(of: "/Tests/") else {
            return filePath
        }

        return String(filePath[..<testsRange.lowerBound])
    }

    @Test
    func packageDeclaresMacOS13Compatibility() throws {
        let packageContents = try readUTF8File(at: packageRoot + "/Package.swift")
        #expect(packageContents.contains(".macOS(.v13)"))
    }

    @Test
    func infoPlistMinimumSystemVersionIsMacOS13() throws {
        let plistContents = try readUTF8File(at: packageRoot + "/Support/Info.plist")
        #expect(plistContents.contains("<key>LSMinimumSystemVersion</key>"))
        #expect(plistContents.contains("<string>13.0</string>"))
    }

    @Test
    func iconMasterArtworkExistsAt1024Pixels() throws {
        let pngBytes = try readFile(at: packageRoot + "/macos/AppIconMaster.png")
        #expect(pngBytes.count > 24)
        #expect(Array(pngBytes.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10])
        #expect(String(decoding: pngBytes[12..<16], as: UTF8.self) == "IHDR")
        #expect(readBigEndianUInt32(from: pngBytes, start: 16) == 1024)
        #expect(readBigEndianUInt32(from: pngBytes, start: 20) == 1024)
    }

    private func readUTF8File(at path: String) throws -> String {
        String(decoding: try readFile(at: path), as: UTF8.self)
    }

    private func readFile(at path: String) throws -> [UInt8] {
        let descriptor = open(path, O_RDONLY)
        guard descriptor >= 0 else {
            throw FileReadError.openFailed(path)
        }

        defer {
            close(descriptor)
        }

        var fileStatus = stat()
        guard fstat(descriptor, &fileStatus) == 0 else {
            throw FileReadError.statFailed(path)
        }

        let byteCount = Int(fileStatus.st_size)
        var buffer = [UInt8](repeating: 0, count: byteCount)
        let readCount = buffer.withUnsafeMutableBytes { mutableBytes in
            read(descriptor, mutableBytes.baseAddress, byteCount)
        }

        guard readCount == byteCount else {
            throw FileReadError.readFailed(path)
        }

        return buffer
    }

    private func readBigEndianUInt32(from bytes: [UInt8], start: Int) -> UInt32 {
        bytes[start..<(start + 4)].reduce(0) { partialResult, byte in
            (partialResult << 8) | UInt32(byte)
        }
    }
}
