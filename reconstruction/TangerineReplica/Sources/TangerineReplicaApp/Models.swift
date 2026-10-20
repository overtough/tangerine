import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum FanTheme: String, CaseIterable, Identifiable {
    case tangerine
    case midnight
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tangerine: return "Tangerine"
        case .midnight: return "Midnight"
        case .graphite: return "Graphite"
        }
    }

    var accent: Color {
        switch self {
        case .tangerine: return Color(red: 0.95, green: 0.36, blue: 0.12)
        case .midnight: return Color(red: 0.30, green: 0.48, blue: 0.96)
        case .graphite: return Color(red: 0.52, green: 0.56, blue: 0.63)
        }
    }
}

enum ActionCategory: String, CaseIterable, Identifiable, Hashable {
    case images
    case documents
    case spreadsheets
    case audio
    case video
    case archives
    case subtitles
    case tools

    var id: String { rawValue }

    var title: String {
        switch self {
        case .images: return "Images"
        case .documents: return "Documents"
        case .spreadsheets: return "Spreadsheets"
        case .audio: return "Audio"
        case .video: return "Video"
        case .archives: return "Archives"
        case .subtitles: return "Subtitles"
        case .tools: return "Tools"
        }
    }
}

enum ActionKind: String, Hashable {
    case convert
    case tool
}

struct ConversionAction: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let category: ActionCategory
    let modifier: String
    let kind: ActionKind
    let extensions: [String]

    static let catalog: [ConversionAction] = [
        ConversionAction(
            id: "image-jpeg",
            title: "JPEG",
            subtitle: "Image conversion",
            symbolName: "photo",
            category: .images,
            modifier: "⌘1",
            kind: .convert,
            extensions: ["jpg", "jpeg"]
        ),
        ConversionAction(
            id: "image-png",
            title: "PNG",
            subtitle: "Image conversion",
            symbolName: "photo.fill",
            category: .images,
            modifier: "⌘2",
            kind: .convert,
            extensions: ["png"]
        ),
        ConversionAction(
            id: "document-pdf",
            title: "PDF",
            subtitle: "Document conversion",
            symbolName: "doc.richtext",
            category: .documents,
            modifier: "⌘3",
            kind: .convert,
            extensions: ["pdf"]
        ),
        ConversionAction(
            id: "audio-mp3",
            title: "MP3",
            subtitle: "Audio conversion",
            symbolName: "waveform",
            category: .audio,
            modifier: "⌘4",
            kind: .convert,
            extensions: ["mp3"]
        ),
        ConversionAction(
            id: "video-mp4",
            title: "MP4",
            subtitle: "Video conversion",
            symbolName: "film",
            category: .video,
            modifier: "⌘5",
            kind: .convert,
            extensions: ["mp4"]
        ),
        ConversionAction(
            id: "archive-zip",
            title: "ZIP",
            subtitle: "Archive creation",
            symbolName: "archivebox",
            category: .archives,
            modifier: "⌘6",
            kind: .convert,
            extensions: ["zip"]
        ),
        ConversionAction(
            id: "copy-path",
            title: "Copy Path",
            subtitle: "File action",
            symbolName: "link",
            category: .tools,
            modifier: "⌘7",
            kind: .tool,
            extensions: []
        ),
        ConversionAction(
            id: "remove-metadata",
            title: "Remove Metadata",
            subtitle: "Privacy tool",
            symbolName: "eye.slash",
            category: .tools,
            modifier: "⌘8",
            kind: .tool,
            extensions: []
        )
    ]
}

struct OperationNotice: Identifiable {
    enum Level {
        case success
        case warning
        case failure
    }

    let id = UUID()
    let level: Level
    let title: String
    let detail: String
}

@MainActor
final class ReplicaModel: ObservableObject {
    @Published var hasCompletedWelcome: Bool
    @Published var selectedFiles: [URL] = []
    @Published var selectedAction: ConversionAction?
    @Published var isWorking = false
    @Published var progress = 0.0
    @Published var statusMessage = "Drop files to begin"
    @Published var notice: OperationNotice?
    @Published var fanTheme: FanTheme
    @Published var soundsEnabled: Bool
    @Published var launchAtLogin = false

    private let defaults = UserDefaults.standard

    init() {
        hasCompletedWelcome = defaults.bool(forKey: "hasCompletedWelcome")
        fanTheme = FanTheme(rawValue: defaults.string(forKey: "conversionFanTheme") ?? "tangerine") ?? .tangerine
        soundsEnabled = defaults.object(forKey: "soundsAndHapticsEnabled") as? Bool ?? true
    }

    var selectedFileSummary: String {
        guard !selectedFiles.isEmpty else { return "No files selected" }
        if selectedFiles.count == 1 {
            return selectedFiles[0].lastPathComponent
        }
        return "\(selectedFiles.count) files selected"
    }

    func completeWelcome() {
        hasCompletedWelcome = true
        defaults.set(true, forKey: "hasCompletedWelcome")
    }

    func setTheme(_ theme: FanTheme) {
        fanTheme = theme
        defaults.set(theme.rawValue, forKey: "conversionFanTheme")
    }

    func setSoundsEnabled(_ enabled: Bool) {
        soundsEnabled = enabled
        defaults.set(enabled, forKey: "soundsAndHapticsEnabled")
    }

    func receiveFiles(_ urls: [URL]) {
        let localFiles = urls.filter { $0.isFileURL }
        guard !localFiles.isEmpty else {
            notice = OperationNotice(
                level: .warning,
                title: "Drop only accessible files",
                detail: "The reconstruction accepts local file URLs only."
            )
            return
        }

        selectedFiles = localFiles
        selectedAction = selectedAction ?? ConversionAction.catalog.first
        statusMessage = "Choose a petal to continue"
        notice = nil
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Choose"
        if panel.runModal() == .OK {
            receiveFiles(panel.urls)
        }
    }

    func importProviders(_ providers: [NSItemProvider]) -> Bool {
        let typeIdentifier = UTType.fileURL.identifier
        for provider in providers where provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, _ in
                let url: URL?
                if let item = item as? Data {
                    url = URL(dataRepresentation: item, relativeTo: nil)
                } else if let item = item as? NSURL {
                    url = item as URL
                } else {
                    url = nil
                }

                guard let url else { return }
                Task { @MainActor [weak self] in
                    self?.receiveFiles([url])
                }
            }
        }
        return true
    }

    func select(_ action: ConversionAction) {
        selectedAction = action
        statusMessage = selectedFiles.isEmpty ? "Drop files to begin" : "Ready to run \(action.title)"
        notice = nil
    }

    func runSelectedAction() {
        guard !selectedFiles.isEmpty else {
            notice = OperationNotice(
                level: .warning,
                title: "Drop at least one item",
                detail: "Choose local files before starting an action."
            )
            return
        }
        guard let action = selectedAction else {
            notice = OperationNotice(
                level: .warning,
                title: "Choose an action",
                detail: "Select a conversion petal or file tool first."
            )
            return
        }

        if action.id == "copy-path" {
            let paths = selectedFiles.map(\.path).joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(paths, forType: .string)
            statusMessage = "Copied \(selectedFiles.count) path(s)"
            notice = OperationNotice(level: .success, title: "Paths copied", detail: "The selected paths are on the clipboard.")
            return
        }

        isWorking = true
        progress = 0
        statusMessage = "Tangerine is working…"
        notice = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            for step in 1...10 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                progress = Double(step) / 10.0
            }
            isWorking = false
            statusMessage = "Ready for another drop"
            notice = OperationNotice(
                level: .warning,
                title: "Backend not connected",
                detail: "The SwiftUI reconstruction has the shell and operation state, but does not claim to reproduce the original converter backend for \(action.title)."
            )
        }
    }

    func resetSelection() {
        selectedFiles = []
        selectedAction = nil
        progress = 0
        statusMessage = "Drop files to begin"
        notice = nil
    }
}
