import AppKit
import SwiftUI

struct MenuBarStatusView: View {
    @ObservedObject var model: ReplicaModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(model.fanTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tangerine")
                        .font(.headline)
                    Text(model.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text("Drag files anywhere")
                .font(.subheadline.weight(.semibold))
            Text("While dragging, tap one modifier key to open its wheel.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(DragModifier.allCases) { modifier in
                Label("\(modifier.title) — \(modifier.wheelKind.title)", systemImage: modifier.symbolName)
            }

            if let wheel = model.activeWheel {
                Divider()
                Label("Last selected: \(wheel.title)", systemImage: wheel.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.fanTheme.accent)
            }

            Divider()

            Button {
                openWindow(id: "main")
            } label: {
                Label("Open Conversion Fan", systemImage: "circle.grid.cross")
            }

            settingsMenuItem

            Button("Quit Tangerine") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    @ViewBuilder
    private var settingsMenuItem: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
        } else {
            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
