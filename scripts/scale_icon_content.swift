import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else {
    fputs("Usage: swift scale_icon_content.swift <input> [output] [targetRatio]\n", stderr)
    exit(1)
}

let inputPath = args[1]
let outputPath = args.count >= 3 ? args[2] : inputPath
let targetRatio = args.count >= 4 ? (Double(args[3]) ?? 0.86) : 0.86

guard targetRatio > 0.0, targetRatio <= 0.98 else {
    fputs("targetRatio must be between 0 and 0.98\n", stderr)
    exit(1)
}

guard
    let image = NSImage(contentsOfFile: inputPath),
    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("Failed to load image: \(inputPath)\n", stderr)
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
    fputs("Failed to create context\n", stderr)
    exit(1)
}

context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

var minX = width
var minY = height
var maxX = 0
var maxY = 0
var hasContent = false

for y in 0..<height {
    for x in 0..<width {
        let alpha = data[y * bytesPerRow + x * 4 + 3]
        if alpha > 2 {
            hasContent = true
            if x < minX { minX = x }
            if y < minY { minY = y }
            if x > maxX { maxX = x }
            if y > maxY { maxY = y }
        }
    }
}

guard hasContent else {
    fputs("No visible content found\n", stderr)
    exit(1)
}

let contentWidth = maxX - minX + 1
let contentHeight = maxY - minY + 1
let currentMax = Double(max(contentWidth, contentHeight))
let canvasMax = Double(max(width, height))
let desiredMax = canvasMax * targetRatio
let scale = desiredMax / currentMax

let cropRect = CGRect(x: minX, y: minY, width: contentWidth, height: contentHeight)
guard let cropped = cgImage.cropping(to: cropRect) else {
    fputs("Failed to crop content\n", stderr)
    exit(1)
}

let scaledWidth = Double(contentWidth) * scale
let scaledHeight = Double(contentHeight) * scale
let drawRect = CGRect(
    x: (Double(width) - scaledWidth) / 2.0,
    y: (Double(height) - scaledHeight) / 2.0,
    width: scaledWidth,
    height: scaledHeight
)

var outData = [UInt8](repeating: 0, count: bytesPerRow * height)
guard
    let outContext = CGContext(
        data: &outData,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
else {
    fputs("Failed to create output context\n", stderr)
    exit(1)
}

outContext.interpolationQuality = .high
outContext.clear(CGRect(x: 0, y: 0, width: width, height: height))
outContext.draw(cropped, in: drawRect)

guard
    let outCGImage = outContext.makeImage(),
    let pngData = NSBitmapImageRep(cgImage: outCGImage).representation(using: .png, properties: [:])
else {
    fputs("Failed to encode output PNG\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL)

print("Wrote \(outputPath)")
print("Scaled visible content ratio to \(String(format: "%.3f", targetRatio))")
