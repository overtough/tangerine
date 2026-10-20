import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @ObservedObject var model: ReplicaModel
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(model: model)

            ScrollView {
                VStack(spacing: 18) {
                    ModifierMenuBanner(model: model)

                    FanView(model: model, isDropTargeted: $isDropTargeted)

                    SelectionSummary(model: model)

                    if let notice = model.notice {
                        NoticeView(notice: notice)
                    }

                    HStack(spacing: 10) {
                        Button {
                            model.chooseFiles()
                        } label: {
                            Label("Choose files", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            model.runSelectedAction()
                        } label: {
                            Label(model.isWorking ? "Working…" : "Run selected action", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isWorking || model.selectedAction == nil || model.selectedFiles.isEmpty)

                        Button("Clear") {
                            model.resetSelection()
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isWorking || (model.selectedFiles.isEmpty && model.notice == nil))
                    }

                    Text("Drop only local, accessible files. Conversion backends are intentionally separate from this clean-room UI reconstruction.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }
                .padding(24)
            }
        }
        .frame(minWidth: 520, minHeight: 680)
        .background(.regularMaterial)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            model.importProviders(providers)
        }
    }
}

struct HeaderView: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.fanTheme.accent.gradient)
                Image(systemName: "circle.grid.cross")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tangerine")
                    .font(.headline)
                Text(model.isWorking ? "Tangerine is working…" : model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.notice = nil
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.plain)
            .help("More options")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.bar)
    }
}

struct SelectionSummary: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Selected files", systemImage: "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(model.selectedFileSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if model.isWorking {
                ProgressView(value: model.progress)
                    .tint(model.fanTheme.accent)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ModifierMenuBanner: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let wheel = model.activeWheel {
                Label(wheel.title, systemImage: wheel.symbolName)
                    .font(.subheadline.weight(.semibold))
                Text("Tap the chosen modifier combination while dragging files.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(model.activeMenuActions) { action in
                            Button {
                                model.select(action)
                            } label: {
                                Label(action.title, systemImage: action.symbolName)
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.bordered)
                            .tint(model.selectedAction?.id == action.id ? model.fanTheme.accent : nil)
                        }
                    }
                }
            } else {
                Label("Three drag menus", systemImage: "command.square")
                    .font(.subheadline.weight(.semibold))
                Text("Drag files anywhere, then tap Shift, Command, or Control.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct NoticeView: View {
    let notice: OperationNotice

    private var tint: Color {
        switch notice.level {
        case .success: return .green
        case .warning: return .orange
        case .failure: return .red
        }
    }

    private var symbol: String {
        switch notice.level {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failure: return "xmark.octagon.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(notice.title)
                    .font(.subheadline.weight(.semibold))
                Text(notice.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        }
    }
}

struct FanView: View {
    @ObservedObject var model: ReplicaModel
    @Binding var isDropTargeted: Bool

    private var actions: [ConversionAction] {
        model.activeWheel.map { model.actions(for: $0) } ?? ConversionAction.catalog
    }

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = min(proxy.size.width, proxy.size.height) * 0.28

            ZStack {
                Circle()
                    .fill(model.fanTheme.accent.opacity(isDropTargeted ? 0.20 : 0.08))
                    .frame(width: min(proxy.size.width, proxy.size.height) * 0.82)
                    .blur(radius: isDropTargeted ? 2 : 18)

                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    let angle = (Double(index) / Double(actions.count)) * (Double.pi * 2) - (Double.pi / 2)
                    FanPetal(
                        action: action,
                        isSelected: model.selectedAction?.id == action.id,
                        accent: model.fanTheme.accent
                    ) {
                        model.select(action)
                    }
                    .position(
                        x: center.x + CGFloat(cos(angle)) * radius,
                        y: center.y + CGFloat(sin(angle)) * radius
                    )
                }

                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 138, height: 138)
                    .overlay {
                        Circle()
                            .stroke(model.fanTheme.accent.opacity(isDropTargeted ? 0.75 : 0.35), lineWidth: isDropTargeted ? 3 : 1)
                    }
                    .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
                    .overlay {
                        VStack(spacing: 7) {
                             Image(systemName: isDropTargeted ? "arrow.down.circle.fill" : "command.square")
                                 .font(.title2)
                                 .foregroundStyle(model.fanTheme.accent)
                             Text(model.activeWheel?.title ?? "Drag files")
                                 .font(.headline)
                             Text(model.activeWheel == nil ? "tap a modifier key" : "choose an option")
                                 .font(.caption)
                                 .foregroundStyle(.secondary)
                        }
                    }
                    .position(center)
                    .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
                        model.importProviders(providers)
                    }
            }
        }
        .frame(height: 390)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Conversion fan")
    }
}

struct FanPetal: View {
    let action: ConversionAction
    let isSelected: Bool
    let accent: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 5) {
                Image(systemName: action.symbolName)
                    .font(.title3.weight(.semibold))
                Text(action.title)
                    .font(.caption.weight(.semibold))
                Text(action.modifier)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 118, height: 78)
            .background(isSelected ? accent.opacity(0.18) : Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? accent : Color.primary.opacity(0.10), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .help("\(action.title) — \(action.subtitle)")
    }
}
