import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let model: ReplicaModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(model: ReplicaModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "circle.lefthalf.filled",
                accessibilityDescription: "Tangerine"
            )
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.toolTip = "Tangerine"
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        let hostingController = NSHostingController(rootView: MenuBarStatusView(model: model))
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 520, height: 680)
        popover.behavior = .transient
        popover.animates = true
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
