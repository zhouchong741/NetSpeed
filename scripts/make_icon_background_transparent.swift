import AppKit
import Foundation

struct Pixel {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    fputs("Usage: swift make_icon_background_transparent.swift <input> [output] [tolerance]\n", stderr)
    exit(1)
}

let inputPath = arguments[1]
let outputPath = arguments.count >= 3 ? arguments[2] : inputPath
let tolerance: Int = arguments.count >= 4 ? (Int(arguments[3]) ?? 14) : 14

let inputURL = URL(fileURLWithPath: inputPath)
guard
    let image = NSImage(contentsOf: inputURL),
    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("Failed to load image at \(inputPath)\n", stderr)
    exit(1)
}

let width = cgImage.width
let height = cgImage.height
let bytesPerPixel = 4
let bytesPerRow = width * bytesPerPixel
var data = [UInt8](repeating: 0, count: bytesPerRow * height)

guard
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
    let context = CGContext(
        data: &data,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
else {
    fputs("Failed to create RGBA context\n", stderr)
    exit(1)
}
context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

func index(_ x: Int, _ y: Int) -> Int {
    y * bytesPerRow + x * bytesPerPixel
}

func pixelAt(_ x: Int, _ y: Int) -> Pixel {
    let i = index(x, y)
    return Pixel(r: data[i], g: data[i + 1], b: data[i + 2], a: data[i + 3])
}

func distance(_ a: Pixel, _ b: Pixel) -> Int {
    abs(Int(a.r) - Int(b.r)) +
    abs(Int(a.g) - Int(b.g)) +
    abs(Int(a.b) - Int(b.b))
}

let cornerSampleSize = min(20, min(width, height) / 8)
var sr = 0
var sg = 0
var sb = 0
var count = 0

for y in 0..<cornerSampleSize {
    for x in 0..<cornerSampleSize {
        let p1 = pixelAt(x, y)
        let p2 = pixelAt(width - 1 - x, y)
        let p3 = pixelAt(x, height - 1 - y)
        let p4 = pixelAt(width - 1 - x, height - 1 - y)
        for p in [p1, p2, p3, p4] {
            sr += Int(p.r)
            sg += Int(p.g)
            sb += Int(p.b)
            count += 1
        }
    }
}

let bg = Pixel(
    r: UInt8(sr / max(1, count)),
    g: UInt8(sg / max(1, count)),
    b: UInt8(sb / max(1, count)),
    a: 255
)

var visited = Array(repeating: false, count: width * height)
func visitedIndex(_ x: Int, _ y: Int) -> Int { y * width + x }
var queue: [(Int, Int)] = []
queue.reserveCapacity(width * 2 + height * 2)

func enqueueIfMatch(_ x: Int, _ y: Int) {
    let vi = visitedIndex(x, y)
    if visited[vi] { return }
    visited[vi] = true
    let p = pixelAt(x, y)
    if distance(p, bg) <= tolerance {
        queue.append((x, y))
    }
}

for x in 0..<width {
    enqueueIfMatch(x, 0)
    enqueueIfMatch(x, height - 1)
}
for y in 0..<height {
    enqueueIfMatch(0, y)
    enqueueIfMatch(width - 1, y)
}

var head = 0
while head < queue.count {
    let (x, y) = queue[head]
    head += 1

    let i = index(x, y)
    data[i + 3] = 0

    if x > 0 {
        let nx = x - 1
        let vi = visitedIndex(nx, y)
        if !visited[vi] {
            visited[vi] = true
            if distance(pixelAt(nx, y), bg) <= tolerance {
                queue.append((nx, y))
            }
        }
    }
    if x + 1 < width {
        let nx = x + 1
        let vi = visitedIndex(nx, y)
        if !visited[vi] {
            visited[vi] = true
            if distance(pixelAt(nx, y), bg) <= tolerance {
                queue.append((nx, y))
            }
        }
    }
    if y > 0 {
        let ny = y - 1
        let vi = visitedIndex(x, ny)
        if !visited[vi] {
            visited[vi] = true
            if distance(pixelAt(x, ny), bg) <= tolerance {
                queue.append((x, ny))
            }
        }
    }
    if y + 1 < height {
        let ny = y + 1
        let vi = visitedIndex(x, ny)
        if !visited[vi] {
            visited[vi] = true
            if distance(pixelAt(x, ny), bg) <= tolerance {
                queue.append((x, ny))
            }
        }
    }
}

guard
    let outCGImage = context.makeImage(),
    let outBitmap = NSBitmapImageRep(cgImage: outCGImage).representation(using: .png, properties: [:])
else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: URL(fileURLWithPath: outputPath).deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try outBitmap.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
