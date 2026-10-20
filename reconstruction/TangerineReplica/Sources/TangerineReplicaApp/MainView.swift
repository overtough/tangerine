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

                    if model.selectedAction != nil {
                        OptionInspector(model: model)
                    }

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

                    Text("Drag local files from Finder, then tap Shift, Command, or Control to choose a wheel.")
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

struct OptionInspector: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        if let action = model.selectedAction {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Label(action.title, systemImage: action.symbolName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(action.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Documented options")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.fanTheme.accent)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(Array(action.optionSummary.enumerated()), id: \.offset) { _, option in
                        Label(option, systemImage: "checkmark.circle")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(14)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
        }
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
        model.wheelActions
    }

    private var pageCount: Int {
        model.wheelPageCount
    }

    private var visibleActions: [ConversionAction] {
        model.visibleWheelActions
    }

    private var highlightedID: String? {
        (model.isDraggingFiles ? model.highlightedAction : model.selectedAction)?.id
    }

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let canvas = min(proxy.size.width, proxy.size.height) * 0.92

            ZStack {
                Circle()
                    .fill(model.fanTheme.accent.opacity(isDropTargeted ? 0.20 : 0.08))
                    .frame(width: min(proxy.size.width, proxy.size.height) * 0.82)
                    .blur(radius: isDropTargeted ? 2 : 18)

                ForEach(Array(visibleActions.enumerated()), id: \.element.id) { index, action in
                    let sector = (Double.pi * 2) / Double(max(visibleActions.count, 1))
                    let angle = (Double(index) * sector) - (Double.pi / 2)
                    let startAngle = Angle(radians: angle - sector * 0.5 + 0.045)
                    let endAngle = Angle(radians: angle + sector * 0.5 - 0.045)
                    FanPetal(
                        action: action,
                        isSelected: highlightedID == action.id,
                        accent: model.fanTheme.accent,
                        startAngle: startAngle,
                        endAngle: endAngle
                    ) {
                        model.select(action)
                    }
                    .frame(width: canvas, height: canvas)
                    .position(center)
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
                             if let action = model.isDraggingFiles ? model.highlightedAction : model.selectedAction {
                                 Text(action.title)
                                     .font(.headline)
                                 Text(action.subtitle)
                                     .font(.caption)
                                     .foregroundStyle(.secondary)
                             } else {
                                 Text(model.activeWheel?.title ?? "Drag files")
                                     .font(.headline)
                                 Text(model.activeWheel == nil ? "tap a modifier key" : "move over an option")
                                     .font(.caption)
                                     .foregroundStyle(.secondary)
                             }
                         }
                    }
                    .position(center)
                    .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
                        model.importProviders(providers)
                    }
            }
        }
        .frame(height: 390)
        .overlay(alignment: .bottom) {
            if pageCount > 1 {
                HStack(spacing: 12) {
                    Button {
                        model.wheelPage = max(0, model.wheelPage - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.wheelPage == 0)

                    Text("\(model.wheelPage + 1) / \(pageCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Button {
                        model.wheelPage = min(pageCount - 1, model.wheelPage + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.wheelPage >= pageCount - 1)
                }
                .padding(.bottom, 2)
            }
        }
        .onChange(of: model.activeWheel) { _ in
            model.wheelPage = 0
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Conversion fan")
    }
}

struct FanPetal: View {
    let action: ConversionAction
    let isSelected: Bool
    let accent: Color
    let startAngle: Angle
    let endAngle: Angle
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            GeometryReader { proxy in
                let midAngle = (startAngle.radians + endAngle.radians) / 2
                let labelRadius = min(proxy.size.width, proxy.size.height) * 0.35
                ZStack {
                    RadialPetalShape(startAngle: startAngle, endAngle: endAngle)
                        .fill(isSelected ? accent.opacity(0.26) : Color.primary.opacity(0.08))
                        .overlay {
                            RadialPetalShape(startAngle: startAngle, endAngle: endAngle)
                                .stroke(isSelected ? accent : Color.primary.opacity(0.16), lineWidth: isSelected ? 2.5 : 1)
                        }

                    VStack(spacing: 4) {
                        Image(systemName: action.symbolName)
                            .font(.title3.weight(.semibold))
                        Text(action.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 94)
                    .foregroundStyle(isSelected ? accent : .primary)
                    .position(
                        x: proxy.size.width / 2 + CGFloat(cos(midAngle)) * labelRadius,
                        y: proxy.size.height / 2 + CGFloat(sin(midAngle)) * labelRadius
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .contentShape(RadialPetalShape(startAngle: startAngle, endAngle: endAngle))
        .help("\(action.title) — \(action.subtitle)")
    }
}

struct RadialPetalShape: Shape {
    var startAngle: Angle = .degrees(-112)
    var endAngle: Angle = .degrees(-68)
    var innerRadius: CGFloat = FanGeometry.innerRadius
    var outerRadius: CGFloat = FanGeometry.outerRadius

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = startAngle.radians
        let end = endAngle.radians
        let innerStart = point(center: center, radius: innerRadius, angle: start)
        let outerEnd = point(center: center, radius: outerRadius, angle: end)
        var path = Path()
        path.move(to: innerStart)
        path.addArc(center: center, radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: outerEnd)
        path.addArc(center: center, radius: outerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }
}
