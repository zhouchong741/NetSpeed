import AppKit
import Foundation
import NetSpeedCore

@MainActor
final class StatusBarController: NSObject {
    var onQuit: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let statusStackView = NSStackView()
    private let downloadLabel = NSTextField(labelWithString: "↓0B")
    private let uploadLabel = NSTextField(labelWithString: "↑0B")
    private let menu = NSMenu()
    private let interfacesItem = NSMenuItem(title: "网卡: 检测中…", action: nil, keyEquivalent: "")
    private lazy var quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")

    private let compactFont = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .semibold)
    private let minimumStatusWidth: CGFloat = 30

    override init() {
        super.init()
        configureStatusItem()
        configureMenu()
        showInitialState()
    }

    func update(with speed: MeasuredSpeed) {
        applyStatusBarLines(
            download: SpeedFormatter.compactDownloadText(speed.downloadBytesPerSecond),
            upload: SpeedFormatter.compactUploadText(speed.uploadBytesPerSecond)
        )
        if speed.interfaces.isEmpty {
            interfacesItem.title = "速率: " + [
                SpeedFormatter.compactDownloadText(speed.downloadBytesPerSecond),
                SpeedFormatter.compactUploadText(speed.uploadBytesPerSecond),
            ].joined(separator: " ")
            return
        }

        interfacesItem.title = "网卡: " + SpeedFormatter.compactInterfacesText(speed.interfaces)
    }

    private func configureStatusItem() {
        statusItem.menu = menu
        statusItem.button?.toolTip = "NetSpeed"
        statusItem.button?.title = ""

        guard let button = statusItem.button else {
            return
        }

        configureLabels()
        configureStackView()
        button.addSubview(statusStackView)
        NSLayoutConstraint.activate([
            statusStackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            statusStackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4),
            statusStackView.topAnchor.constraint(equalTo: button.topAnchor, constant: 1),
            statusStackView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -1),
        ])
    }

    private func configureMenu() {
        interfacesItem.isEnabled = false
        quitItem.target = self

        menu.addItem(interfacesItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
    }

    private func showInitialState() {
        applyStatusBarLines(download: "↓0B", upload: "↑0B")
    }

    private func configureLabels() {
        for label in [downloadLabel, uploadLabel] {
            label.font = compactFont
            label.alignment = .center
            label.lineBreakMode = .byClipping
            label.maximumNumberOfLines = 1
            label.translatesAutoresizingMaskIntoConstraints = false
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.setContentHuggingPriority(.required, for: .horizontal)
        }
    }

    private func configureStackView() {
        statusStackView.orientation = .vertical
        statusStackView.alignment = .centerX
        statusStackView.distribution = .fillEqually
        statusStackView.spacing = -2
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.addArrangedSubview(downloadLabel)
        statusStackView.addArrangedSubview(uploadLabel)
    }

    private func applyStatusBarLines(download: String, upload: String) {
        downloadLabel.stringValue = download
        uploadLabel.stringValue = upload
        updateStatusItemWidth()
    }

    private func updateStatusItemWidth() {
        let measuredWidth = max(
            downloadLabel.intrinsicContentSize.width,
            uploadLabel.intrinsicContentSize.width
        )
        statusItem.length = max(minimumStatusWidth, ceil(measuredWidth) + 10)
    }

    @objc
    private func quitApp() {
        onQuit?()
    }
}
