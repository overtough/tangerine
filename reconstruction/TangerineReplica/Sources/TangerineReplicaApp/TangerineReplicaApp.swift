import AppKit
import SwiftUI

@main
@MainActor
struct TangerineReplicaApp: App {
    @StateObject private var model: ReplicaModel
    private let statusItemController: StatusItemController
    private let dragGestureMonitor: DragGestureMonitor

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        let model = ReplicaModel()
        let overlay = ConversionOverlayController(model: model)
        _model = StateObject(wrappedValue: model)
        statusItemController = StatusItemController(model: model)
        dragGestureMonitor = DragGestureMonitor(model: model, overlay: overlay)
    }

    var body: some Scene {
        Window("Tangerine", id: "main") {
            RootView(model: model)
        }
        .defaultSize(width: 520, height: 680)

        Settings {
            SettingsView(model: model)
        }
    }
}

struct MenuBarMenu: View {
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
                    Text(model.isWorking ? "Tangerine is working…" : model.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            if let modifier = model.activeModifier {
                Text("\(modifier.menuTitle) · \(model.activeMenuActions.count) options")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.fanTheme.accent)

                ForEach(model.activeMenuActions) { action in
                    Button {
                        model.select(action)
                        model.runSelectedAction()
                    } label: {
                        Label(action.title, systemImage: action.symbolName)
                    }
                }

                Divider()
            }

            Text("Drop a file while holding")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(DragModifier.allCases) { modifier in
                Label("\(modifier.title) → \(modifier.menuTitle)", systemImage: modifier.symbolName)
            }

            Button {
                openWindow(id: "main")
            } label: {
                Label("Open Conversion Fan", systemImage: "circle.grid.cross")
            }

            settingsMenuItem

            Divider()

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
                // The SwiftUI Settings scene exposes this action on macOS 13.
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

struct RootView: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        Group {
            if model.hasCompletedWelcome {
                MainView(model: model)
            } else {
                WelcomeView(model: model)
            }
        }
        .tint(model.fanTheme.accent)
    }
}

struct WelcomeView: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(model.fanTheme.accent.gradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: model.fanTheme.accent.opacity(0.35), radius: 22)
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("Welcome to Tangerine")
                    .font(.largeTitle.bold())
                Text("A conversion fan for local files, tools, and privacy workflows.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 360)
            }

            VStack(alignment: .leading, spacing: 14) {
                WelcomeRow(number: "1", title: "Drop files", detail: "Drag local files onto the fan.")
                 WelcomeRow(number: "2", title: "Choose one of three menus", detail: "Hold Shift, Command, or Control while dragging a file.")
                WelcomeRow(number: "3", title: "Keep results beside originals", detail: "The original app uses security-scoped folder access.")
                WelcomeRow(number: "4", title: "Stay local", detail: "This reconstruction does not upload your files.")
            }
            .padding(20)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))

            Button("Start using Tangerine") {
                model.completeWelcome()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 520, minHeight: 680)
    }
}

struct WelcomeRow: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
