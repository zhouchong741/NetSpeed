import Darwin
import Foundation
import SystemConfiguration

struct InterfaceCounters: Equatable {
    let received: UInt64
    let sent: UInt64
}

package enum InterfaceClassifier {
    private static let excludedTrafficPrefixes = [
        "awdl",
        "llw",
        "utun",
        "bridge",
        "anpi",
        "ap",
        "p2p",
        "vmnet",
    ]

    package static func shouldCountTraffic(name: String) -> Bool {
        !excludedTrafficPrefixes.contains { name.hasPrefix($0) }
    }

    package static func activeInterfaces(
        from interfaceNames: some Sequence<String>,
        primaryInterfaces: [String],
        trafficInterfaces: [String]
    ) -> [String] {
        let countedInterfaces = Set(interfaceNames)
        let preferredInterfaces = trafficInterfaces.isEmpty ? primaryInterfaces : trafficInterfaces
        let filteredInterfaces = preferredInterfaces.filter { countedInterfaces.contains($0) }.sorted()
        if !filteredInterfaces.isEmpty {
            return filteredInterfaces
        }

        return []
    }
}

private enum PrimaryInterfaceReader {
    private static let globalStateKeys = [
        "State:/Network/Global/IPv4",
        "State:/Network/Global/IPv6",
    ]

    static func primaryInterfaces() -> [String] {
        guard let store = SCDynamicStoreCreate(nil, "NetSpeed" as CFString, nil, nil) else {
            return []
        }

        guard
            let values = SCDynamicStoreCopyMultiple(
                store,
                globalStateKeys as CFArray,
                nil
            ) as? [String: Any]
        else {
            return []
        }

        var interfaces = Set<String>()
        for key in globalStateKeys {
            guard
                let configuration = values[key] as? [String: Any],
                let interfaceName = configuration[kSCDynamicStorePropNetPrimaryInterface as String] as? String
            else {
                continue
            }

            interfaces.insert(interfaceName)
        }

        return interfaces.sorted()
    }
}

package struct NetworkSnapshot: Equatable {
    let counters: [String: InterfaceCounters]
    let activeInterfaces: [String]

    package var interfaces: [String] {
        activeInterfaces
    }

    package static func capture() -> NetworkSnapshot {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let firstAddress = pointer else {
            return NetworkSnapshot(counters: [:], activeInterfaces: [])
        }

        defer {
            freeifaddrs(firstAddress)
        }

        var counters: [String: InterfaceCounters] = [:]
        var currentAddress: UnsafeMutablePointer<ifaddrs>? = firstAddress

        while let interface = currentAddress {
            let entry = interface.pointee
            currentAddress = entry.ifa_next

            guard let namePointer = entry.ifa_name else {
                continue
            }

            let flags = Int32(entry.ifa_flags)
            let isUp = (flags & Int32(IFF_UP)) != 0
            let isRunning = (flags & Int32(IFF_RUNNING)) != 0
            let isLoopback = (flags & Int32(IFF_LOOPBACK)) != 0
            guard isUp, isRunning, !isLoopback else {
                continue
            }

            guard let address = entry.ifa_addr, address.pointee.sa_family == UInt8(AF_LINK) else {
                continue
            }

            guard let data = entry.ifa_data else {
                continue
            }

            let name = String(cString: namePointer)
            guard InterfaceClassifier.shouldCountTraffic(name: name) else {
                continue
            }

            let interfaceData = data.assumingMemoryBound(to: if_data.self).pointee
            counters[name] = InterfaceCounters(
                received: UInt64(interfaceData.ifi_ibytes),
                sent: UInt64(interfaceData.ifi_obytes)
            )
        }

        return NetworkSnapshot(
            counters: counters,
            activeInterfaces: InterfaceClassifier.activeInterfaces(
                from: counters.keys,
                primaryInterfaces: PrimaryInterfaceReader.primaryInterfaces(),
                trafficInterfaces: []
            )
        )
    }
}

package struct MeasuredSpeed: Equatable {
    package let downloadBytesPerSecond: Double
    package let uploadBytesPerSecond: Double
    package let interfaces: [String]
    package let sampledAt: Date
}

package enum ByteCounterDelta {
    package static func delta(
        current: UInt64,
        previous: UInt64,
        maxCounter: UInt64 = UInt64(UInt32.max)
    ) -> UInt64 {
        guard current < previous else {
            return current - previous
        }

        let wrapThreshold = UInt64(Double(maxCounter) * 0.9)
        let lowThreshold = maxCounter - wrapThreshold
        if previous >= wrapThreshold, current <= lowThreshold {
            return (maxCounter - previous) + current + 1
        }

        return 0
    }
}

@MainActor
package final class NetworkSpeedMonitor {
    package var onUpdate: ((MeasuredSpeed) -> Void)?

    private let updateInterval: TimeInterval
    private var timer: Timer?
    private var lastSnapshot: NetworkSnapshot?
    private var lastSampleDate: Date?

    package init(updateInterval: TimeInterval) {
        self.updateInterval = updateInterval
    }

    package func start() {
        lastSnapshot = nil
        lastSampleDate = nil
        timer?.invalidate()
        captureSample()

        let timer = Timer(
            timeInterval: updateInterval,
            target: self,
            selector: #selector(handleTimerFired),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    package func stop() {
        timer?.invalidate()
        timer = nil
        lastSnapshot = nil
        lastSampleDate = nil
    }

    private func captureSample() {
        let snapshot = NetworkSnapshot.capture()
        let now = Date()
        let speed = computeSpeed(currentSnapshot: snapshot, sampledAt: now)
        onUpdate?(speed)
    }

    @objc
    private func handleTimerFired() {
        captureSample()
    }

    package func computeSpeed(currentSnapshot: NetworkSnapshot, sampledAt: Date) -> MeasuredSpeed {
        defer {
            lastSnapshot = currentSnapshot
            lastSampleDate = sampledAt
        }

        guard let lastSnapshot, let lastSampleDate else {
            return MeasuredSpeed(
                downloadBytesPerSecond: 0,
                uploadBytesPerSecond: 0,
                interfaces: currentSnapshot.interfaces,
                sampledAt: sampledAt
            )
        }

        let interval = sampledAt.timeIntervalSince(lastSampleDate)
        guard interval > 0 else {
            return MeasuredSpeed(
                downloadBytesPerSecond: 0,
                uploadBytesPerSecond: 0,
                interfaces: currentSnapshot.interfaces,
                sampledAt: sampledAt
            )
        }

        var totalDownloadDelta: UInt64 = 0
        var totalUploadDelta: UInt64 = 0
        var trafficInterfaces: [String] = []

        for name in currentSnapshot.counters.keys.sorted() {
            guard
                let currentCounters = currentSnapshot.counters[name],
                let previousCounters = lastSnapshot.counters[name]
            else {
                continue
            }

            let downloadDelta = ByteCounterDelta.delta(
                current: currentCounters.received,
                previous: previousCounters.received
            )
            let uploadDelta = ByteCounterDelta.delta(
                current: currentCounters.sent,
                previous: previousCounters.sent
            )

            totalDownloadDelta += downloadDelta
            totalUploadDelta += uploadDelta

            if downloadDelta > 0 || uploadDelta > 0 {
                trafficInterfaces.append(name)
            }
        }

        return MeasuredSpeed(
            downloadBytesPerSecond: Double(totalDownloadDelta) / interval,
            uploadBytesPerSecond: Double(totalUploadDelta) / interval,
            interfaces: InterfaceClassifier.activeInterfaces(
                from: currentSnapshot.counters.keys,
                primaryInterfaces: currentSnapshot.interfaces,
                trafficInterfaces: trafficInterfaces
            ),
            sampledAt: sampledAt
        )
    }
}
