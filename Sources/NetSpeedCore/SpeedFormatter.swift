import Foundation

package enum SpeedFormatter {
    private static let compactUnits = [
        "B",
        "K",
        "M",
        "G",
        "T",
    ]

    package static func compactDownloadText(_ download: Double) -> String {
        "↓" + format(download, units: compactUnits, separator: "")
    }

    package static func compactUploadText(_ upload: Double) -> String {
        "↑" + format(upload, units: compactUnits, separator: "")
    }

    package static func compactInterfacesText(_ interfaces: [String]) -> String {
        switch interfaces.count {
        case 0:
            return "未检测到"
        case 1...2:
            return interfaces.joined(separator: ", ")
        default:
            return "\(interfaces[0]) 等 \(interfaces.count) 个"
        }
    }

    private static func format(_ bytesPerSecond: Double, units: [String], separator: String) -> String {
        let safeValue = max(bytesPerSecond, 0)
        var value = safeValue
        var unitIndex = 0

        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        let precision = unitIndex == 0 || value >= 10 ? 0 : 1
        if precision == 1, value == value.rounded() {
            return String(Int(value)) + separator + units[unitIndex]
        }

        return String(format: "%.\(precision)f", value) + separator + units[unitIndex]
    }
}
