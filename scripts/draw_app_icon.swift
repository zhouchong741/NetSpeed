import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first
    ?? FileManager.default.currentDirectoryPath + "/macos/AppIconMaster.png"
let outputURL = URL(fileURLWithPath: outputPath)

let canvasSize: CGFloat = 1024
let rect = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
let tileRect = NSRect(x: 144, y: 152, width: 736, height: 736)
let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: 156, yRadius: 156)
let innerTilePath = NSBezierPath(
    roundedRect: tileRect.insetBy(dx: 10, dy: 10),
    xRadius: 146,
    yRadius: 146
)

func arrowPath(in rect: NSRect, pointingUp: Bool) -> NSBezierPath {
    let width = rect.width
    let height = rect.height
    let shaftWidth = width * 0.34
    let headHeight = height * 0.42
    let shaftX = rect.midX - shaftWidth / 2
    let path = NSBezierPath()

    if pointingUp {
        let headBaseY = rect.maxY - headHeight
        path.move(to: NSPoint(x: rect.midX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: headBaseY))
        path.line(to: NSPoint(x: shaftX + shaftWidth, y: headBaseY))
        path.line(to: NSPoint(x: shaftX + shaftWidth, y: rect.minY))
        path.line(to: NSPoint(x: shaftX, y: rect.minY))
        path.line(to: NSPoint(x: shaftX, y: headBaseY))
        path.line(to: NSPoint(x: rect.minX, y: headBaseY))
    } else {
        let headBaseY = rect.minY + headHeight
        path.move(to: NSPoint(x: rect.midX, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX, y: headBaseY))
        path.line(to: NSPoint(x: shaftX + shaftWidth, y: headBaseY))
        path.line(to: NSPoint(x: shaftX + shaftWidth, y: rect.maxY))
        path.line(to: NSPoint(x: shaftX, y: rect.maxY))
        path.line(to: NSPoint(x: shaftX, y: headBaseY))
        path.line(to: NSPoint(x: rect.minX, y: headBaseY))
    }

    path.close()
    return path
}

func drawLinearGradient(
    in path: NSBezierPath,
    colors: [NSColor],
    angle: CGFloat
) {
    guard let gradient = NSGradient(colors: colors) else {
        return
    }
    gradient.draw(in: path, angle: angle)
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize),
    pixelsHigh: Int(canvasSize),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Unable to allocate bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

NSColor.clear.setFill()
rect.fill()

// Base glass tile
drawLinearGradient(
    in: tilePath,
    colors: [
        NSColor(calibratedRed: 0.96, green: 0.985, blue: 1.0, alpha: 0.94),
        NSColor(calibratedRed: 0.83, green: 0.90, blue: 0.97, alpha: 0.90),
    ],
    angle: -90
)

// Soft internal tint
NSGraphicsContext.current?.saveGraphicsState()
tilePath.addClip()
NSColor(calibratedRed: 0.20, green: 0.48, blue: 0.96, alpha: 0.12).setFill()
NSBezierPath(ovalIn: NSRect(x: 212, y: 300, width: 264, height: 300)).fill()
NSColor(calibratedRed: 0.05, green: 0.78, blue: 0.82, alpha: 0.12).setFill()
NSBezierPath(ovalIn: NSRect(x: 546, y: 318, width: 244, height: 280)).fill()
NSGraphicsContext.current?.restoreGraphicsState()

// Edge and top highlight
NSColor(calibratedRed: 0.18, green: 0.58, blue: 0.96, alpha: 0.52).setStroke()
tilePath.lineWidth = 7
tilePath.stroke()

NSColor(calibratedWhite: 1.0, alpha: 0.52).setStroke()
innerTilePath.lineWidth = 2.5
innerTilePath.stroke()

let highlightPath = NSBezierPath()
highlightPath.move(to: NSPoint(x: tileRect.minX + 72, y: tileRect.maxY - 92))
highlightPath.curve(
    to: NSPoint(x: tileRect.maxX - 108, y: tileRect.maxY - 118),
    controlPoint1: NSPoint(x: tileRect.minX + 230, y: tileRect.maxY - 34),
    controlPoint2: NSPoint(x: tileRect.maxX - 250, y: tileRect.maxY - 58)
)
NSColor(calibratedWhite: 1.0, alpha: 0.30).setStroke()
highlightPath.lineWidth = 22
highlightPath.lineCapStyle = .round
highlightPath.stroke()

// Arrows
let downArrow = arrowPath(in: NSRect(x: 260, y: 330, width: 220, height: 300), pointingUp: false)
let upArrow = arrowPath(in: NSRect(x: 540, y: 330, width: 220, height: 300), pointingUp: true)

drawLinearGradient(
    in: downArrow,
    colors: [
        NSColor(calibratedRed: 0.26, green: 0.66, blue: 1.0, alpha: 1.0),
        NSColor(calibratedRed: 0.10, green: 0.37, blue: 0.92, alpha: 1.0),
    ],
    angle: -90
)
drawLinearGradient(
    in: upArrow,
    colors: [
        NSColor(calibratedRed: 0.22, green: 0.86, blue: 0.90, alpha: 1.0),
        NSColor(calibratedRed: 0.02, green: 0.62, blue: 0.76, alpha: 1.0),
    ],
    angle: -90
)

NSColor(calibratedWhite: 1.0, alpha: 0.22).setStroke()
downArrow.lineWidth = 3
upArrow.lineWidth = 3
downArrow.stroke()
upArrow.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode PNG")
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL)
print("Wrote \(outputURL.path)")
