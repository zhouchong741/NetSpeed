import Testing
@testable import NetSpeedCore

struct NetSpeedTests {
    @Test
    func byteCounterDeltaHandlesNormalIncrease() {
        #expect(ByteCounterDelta.delta(current: 2_000, previous: 1_000) == 1_000)
    }

    @Test
    func byteCounterDeltaHandlesNoChange() {
        #expect(ByteCounterDelta.delta(current: 1_000, previous: 1_000) == 0)
    }

    @Test
    func byteCounterDeltaHandlesWrapAround() {
        let previous = UInt64(UInt32.max) - 100
        #expect(ByteCounterDelta.delta(current: 100, previous: previous) == 201)
    }

    @Test
    func byteCounterDeltaTreatsResetAsZero() {
        #expect(ByteCounterDelta.delta(current: 10, previous: 2_000) == 0)
    }

    @Test
    func compactDownloadTextFormatsZero() {
        let text = SpeedFormatter.compactDownloadText(0)
        #expect(text.hasPrefix("↓"))
        #expect(text.contains("0B"))
    }

    @Test
    func compactDownloadTextFormatsBytesWithoutUnitJump() {
        #expect(SpeedFormatter.compactDownloadText(512).contains("512B"))
    }

    @Test
    func compactDownloadTextPreservesSingleDecimalForMegabytes() {
        let rate = 1.5 * 1024 * 1024
        #expect(SpeedFormatter.compactDownloadText(rate).contains("1.5M"))
    }

    @Test
    func compactDownloadTextDropsDecimalForLargeMegabytes() {
        let rate = 100.0 * 1024 * 1024
        #expect(SpeedFormatter.compactDownloadText(rate).contains("100M"))
    }

    @Test
    func compactInterfacesTextFormatsShortListsDirectly() {
        #expect(SpeedFormatter.compactInterfacesText(["en0"]) == "en0")
        #expect(SpeedFormatter.compactInterfacesText(["en0", "en1"]) == "en0, en1")
    }

    @Test
    func compactInterfacesTextFormatsLongListsCompactly() {
        #expect(SpeedFormatter.compactInterfacesText([]) == "未检测到")
        #expect(SpeedFormatter.compactInterfacesText(["en0", "en1", "utun0"]) == "en0 等 3 个")
    }

    @Test
    func interfaceClassifierExcludesOverlappingVirtualInterfaces() {
        #expect(InterfaceClassifier.shouldCountTraffic(name: "en0"))
        #expect(!InterfaceClassifier.shouldCountTraffic(name: "utun4"))
        #expect(!InterfaceClassifier.shouldCountTraffic(name: "bridge0"))
        #expect(!InterfaceClassifier.shouldCountTraffic(name: "awdl0"))
        #expect(!InterfaceClassifier.shouldCountTraffic(name: "llw0"))
    }

    @Test
    func interfaceClassifierPrefersInterfacesWithTrafficForDisplay() {
        let activeInterfaces = InterfaceClassifier.activeInterfaces(
            from: ["en7", "en0", "anpi0"],
            primaryInterfaces: ["en0"],
            trafficInterfaces: ["en7"]
        )

        #expect(activeInterfaces == ["en7"])
    }

    @Test
    func interfaceClassifierFallsBackToPrimaryInterfaceForDisplay() {
        let activeInterfaces = InterfaceClassifier.activeInterfaces(
            from: ["en7", "en0", "anpi0"],
            primaryInterfaces: ["en0"],
            trafficInterfaces: []
        )

        #expect(activeInterfaces == ["en0"])
    }

    @Test
    func networkSnapshotExcludesLoopbackInterface() {
        let snapshot = NetworkSnapshot.capture()
        #expect(!snapshot.counters.keys.contains("lo0"))
    }
}
