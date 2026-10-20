import AppKit
import SwiftUI

@MainActor
final class ConversionOverlayController {
    private let model: ReplicaModel
    private var panel: NSPanel?

    init(model: ReplicaModel) {
        self.model = model
    }

    func show(at point: NSPoint) {
        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 620),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentViewController = NSHostingController(
                rootView: ConversionOverlayView(model: model)
            )
            self.panel = panel
        }

        guard let panel else { return }
        panel.orderFrontRegardless()
        reposition(panel: panel, near: point)
    }

    func update(at point: NSPoint) {
        guard let panel, panel.isVisible else { return }
        reposition(panel: panel, near: point)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func reposition(panel: NSPanel, near point: NSPoint) {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let size = panel.frame.size
        let margin: CGFloat = 12
        let x = min(max(point.x - size.width / 2, visibleFrame.minX + margin), visibleFrame.maxX - size.width - margin)
        let y = min(max(point.y - size.height / 2, visibleFrame.minY + margin), visibleFrame.maxY - size.height - margin)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct ConversionOverlayView: View {
    @ObservedObject var model: ReplicaModel
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(
                    model.activeWheel?.title ?? "Conversion wheel",
                    systemImage: model.activeWheel?.symbolName ?? "arrow.triangle.2.circlepath"
                )
                .font(.headline)
                Spacer()
                Text("Tap Shift · Command · Control")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FanView(model: model, isDropTargeted: $isDropTargeted)
                .frame(width: 520, height: 440)

            if !model.selectedFiles.isEmpty {
                Text(model.selectedFileSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(model.fanTheme.accent.opacity(0.35), lineWidth: 1)
        }
    }
}
