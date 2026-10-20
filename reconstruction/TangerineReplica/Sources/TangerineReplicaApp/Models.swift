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
    case fileAction
}

enum WheelKind: String, CaseIterable, Identifiable, Hashable {
    case conversion
    case tools
    case actions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conversion: return "Conversion wheel"
        case .tools: return "Tools wheel"
        case .actions: return "Actions wheel"
        }
    }

    var symbolName: String {
        switch self {
        case .conversion: return "arrow.triangle.2.circlepath"
        case .tools: return "wrench.and.screwdriver"
        case .actions: return "folder.badge.gearshape"
        }
    }
}

enum DragModifier: String, CaseIterable, Identifiable, Hashable {
    case shift
    case command
    case control

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var symbolName: String {
        switch self {
        case .shift: return "shift"
        case .command: return "command"
        case .control: return "control"
        }
    }

    var menuTitle: String {
        wheelKind.title
    }

    var wheelKind: WheelKind {
        switch self {
        case .shift: return .conversion
        case .command: return .tools
        case .control: return .actions
        }
    }

    static func from(flags: NSEvent.ModifierFlags) -> DragModifier? {
        if flags.contains(.shift) { return .shift }
        if flags.contains(.command) { return .command }
        if flags.contains(.control) { return .control }
        return nil
    }

    static func currentEventModifier() -> DragModifier? {
        from(flags: NSEvent.modifierFlags)
    }
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
    let options: [String] = []

    var wheel: WheelKind {
        switch kind {
        case .convert: return .conversion
        case .tool: return .tools
        case .fileAction: return .actions
        }
    }

    var optionSummary: [String] {
        switch id {
        case "image-jpeg", "image-png", "image-webp", "image-heic", "image-tiff", "image-avif", "image-bmp":
            return ["Compression preset", "Target-size mode", "Target bytes", "Reduction percentage"]
        case "image-svg":
            return ["Vector rendering", "Output dimensions", "Background handling"]
        case "document-pdf":
            return ["Page rendering", "Output beside original", "Reopen and verify output"]
        case "audio-mp3", "audio-m4a", "audio-wav", "audio-flac", "audio-ogg", "audio-opus", "audio-aiff", "audio-wma":
            return ["Audio codec", "Bitrate", "Channel mapping", "Normalization"]
        case "video-mp4", "video-mov", "video-mkv", "video-webm", "video-avi", "video-wmv":
            return ["Video codec", "Audio codec", "Pixel format", "Progress reporting"]
        case "archive-zip", "archive-tar", "archive-gzip", "archive-rar":
            return ["Archive entries", "Output format validation", "Refuse unsupported entry types"]
        case "image-edit":
            return ["Exposure", "Highlights and shadows", "Temperature and tint", "Noise reduction", "Sharpening"]
        case "image-annotate":
            return ["Arrow", "Freehand", "Rectangle and ellipse", "Highlighter", "Callout", "Magnifier", "Text", "Pasted image"]
        case "image-frame":
            return ["Canvas ratio", "Background color, image, or gradient", "Padding", "Corner radius", "Shadow", "Fill or fit"]
        case "image-crop":
            return ["Crop rectangle", "Reposition", "Output preview"]
        case "image-redact":
            return ["Solid or blur", "Face detection", "Separate redacted copy"]
        case "remove-metadata":
            return ["Field-level removal", "Remove All", "Preserve orientation and color profile", "Verify private metadata is gone"]
        case "audio-normalize":
            return ["Target loudness", "Loudness range", "True peak"]
        case "audio-channels":
            return ["Channel count", "Left volume", "Right volume"]
        case "audio-trim":
            return ["Trim start", "Duration", "Waveform preview"]
        case "audio-redact":
            return ["Bleep ranges", "Playhead", "Bleep entire audio"]
        case "video-trim":
            return ["Trim start", "Duration", "Timeline preview"]
        case "video-crop":
            return ["Crop rectangle", "Preview", "Export copy"]
        case "video-speed":
            return ["Speed from 0.25× to 4×", "Preview", "Export copy"]
        case "video-snapshots":
            return ["Snapshot times", "Frame preview", "Export images"]
        case "video-split":
            return ["Split points", "Removed clips", "Export one or more videos"]
        case "video-redact":
            return ["Redaction rectangles", "Start and end time", "Cover entire video"]
        case "pdf-organize":
            return ["Page order", "Per-page rotation", "Equalize page widths"]
        case "pdf-split":
            return ["Page ranges", "Output naming", "Save beside original"]
        case "compress":
            return ["Archive format", "Output destination", "Entry validation"]
        case "read-qr":
            return ["Scan image", "Show QR results", "Copy result"]
        case "copy-path":
            return ["Copy one or more paths", "Preserve Finder paths"]
        case "copy-files":
            return ["Choose destination", "Copy files or folders", "Refuse remote URLs"]
        case "move-files":
            return ["Choose destination", "Move files or folders", "Refuse same or invalid destination"]
        case "open-terminal":
            return ["Apple Terminal", "iTerm2", "Choose terminal in settings"]
        case "airdrop":
            return ["Share selected files and folders", "Use macOS AirDrop"]
        case "float-files":
            return ["Finder-like float", "Groups", "Quick Look", "Drag selection"]
        default:
            return options
        }
    }

    static let catalog: [ConversionAction] = baseCatalog + extendedCatalog

    private static let baseCatalog: [ConversionAction] = [
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
            kind: .fileAction,
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

    private static let extendedCatalog: [ConversionAction] = [
        ConversionAction(id: "image-webp", title: "WebP", subtitle: "Image conversion", symbolName: "photo", category: .images, modifier: "", kind: .convert, extensions: ["webp"]),
        ConversionAction(id: "image-heic", title: "HEIC", subtitle: "Image conversion", symbolName: "photo", category: .images, modifier: "", kind: .convert, extensions: ["heic"]),
        ConversionAction(id: "image-tiff", title: "TIFF", subtitle: "Image conversion", symbolName: "photo", category: .images, modifier: "", kind: .convert, extensions: ["tiff"]),
        ConversionAction(id: "image-svg", title: "SVG", subtitle: "Image conversion", symbolName: "scribble.variable", category: .images, modifier: "", kind: .convert, extensions: ["svg"]),
        ConversionAction(id: "image-avif", title: "AVIF", subtitle: "Image conversion", symbolName: "photo", category: .images, modifier: "", kind: .convert, extensions: ["avif"]),
        ConversionAction(id: "image-bmp", title: "BMP", subtitle: "Image conversion", symbolName: "photo", category: .images, modifier: "", kind: .convert, extensions: ["bmp"]),
        ConversionAction(id: "image-gif", title: "GIF", subtitle: "Image conversion", symbolName: "photo.stack", category: .images, modifier: "", kind: .convert, extensions: ["gif"]),
        ConversionAction(id: "audio-m4a", title: "M4A", subtitle: "Audio conversion", symbolName: "waveform", category: .audio, modifier: "", kind: .convert, extensions: ["m4a"]),
        ConversionAction(id: "audio-wav", title: "WAV", subtitle: "Audio conversion", symbolName: "waveform", category: .audio, modifier: "", kind: .convert, extensions: ["wav"]),
        ConversionAction(id: "audio-flac", title: "FLAC", subtitle: "Audio conversion", symbolName: "waveform", category: .audio, modifier: "", kind: .convert, extensions: ["flac"]),
        ConversionAction(id: "audio-ogg", title: "OGG", subtitle: "Audio conversion", symbolName: "waveform", category: .audio, modifier: "", kind: .convert, extensions: ["ogg"]),
        ConversionAction(id: "audio-opus", title: "Opus", subtitle: "Audio conversion", symbolName: "waveform", category: .audio, modifier: "", kind: .convert, extensions: ["opus"]),
        ConversionAction(id: "audio-aiff", title: "AIFF", subtitle: "Audio conversion", symbolName: "waveform", category: .audio, modifier: "", kind: .convert, extensions: ["aiff"]),
        ConversionAction(id: "audio-wma", title: "WMA", subtitle: "Audio conversion", symbolName: "waveform", category: .audio, modifier: "", kind: .convert, extensions: ["wma"]),
        ConversionAction(id: "video-mov", title: "MOV", subtitle: "Video conversion", symbolName: "film", category: .video, modifier: "", kind: .convert, extensions: ["mov"]),
        ConversionAction(id: "video-mkv", title: "MKV", subtitle: "Video conversion", symbolName: "film", category: .video, modifier: "", kind: .convert, extensions: ["mkv"]),
        ConversionAction(id: "video-webm", title: "WebM", subtitle: "Video conversion", symbolName: "film", category: .video, modifier: "", kind: .convert, extensions: ["webm"]),
        ConversionAction(id: "video-avi", title: "AVI", subtitle: "Video conversion", symbolName: "film", category: .video, modifier: "", kind: .convert, extensions: ["avi"]),
        ConversionAction(id: "video-wmv", title: "WMV", subtitle: "Video conversion", symbolName: "film", category: .video, modifier: "", kind: .convert, extensions: ["wmv"]),
        ConversionAction(id: "document-docx", title: "DOCX", subtitle: "Document conversion", symbolName: "doc.text", category: .documents, modifier: "", kind: .convert, extensions: ["docx"]),
        ConversionAction(id: "document-pages", title: "Pages", subtitle: "Document conversion", symbolName: "doc.text", category: .documents, modifier: "", kind: .convert, extensions: ["pages"]),
        ConversionAction(id: "document-ppt", title: "PPT", subtitle: "Document conversion", symbolName: "rectangle.on.rectangle", category: .documents, modifier: "", kind: .convert, extensions: ["ppt"]),
        ConversionAction(id: "document-pptx", title: "PPTX", subtitle: "Document conversion", symbolName: "rectangle.on.rectangle", category: .documents, modifier: "", kind: .convert, extensions: ["pptx"]),
        ConversionAction(id: "document-txt", title: "TXT", subtitle: "Document conversion", symbolName: "doc.plaintext", category: .documents, modifier: "", kind: .convert, extensions: ["txt"]),
        ConversionAction(id: "document-rtf", title: "RTF", subtitle: "Document conversion", symbolName: "doc.richtext", category: .documents, modifier: "", kind: .convert, extensions: ["rtf"]),
        ConversionAction(id: "document-rtfd", title: "RTFD", subtitle: "Document conversion", symbolName: "doc.richtext", category: .documents, modifier: "", kind: .convert, extensions: ["rtfd"]),
        ConversionAction(id: "document-html", title: "HTML", subtitle: "Document conversion", symbolName: "chevron.left.forwardslash.chevron.right", category: .documents, modifier: "", kind: .convert, extensions: ["html"]),
        ConversionAction(id: "document-epub", title: "EPUB", subtitle: "Document conversion", symbolName: "book", category: .documents, modifier: "", kind: .convert, extensions: ["epub"]),
        ConversionAction(id: "sheet-xlsx", title: "XLSX", subtitle: "Spreadsheet conversion", symbolName: "tablecells", category: .spreadsheets, modifier: "", kind: .convert, extensions: ["xlsx"]),
        ConversionAction(id: "sheet-xls", title: "XLS", subtitle: "Spreadsheet conversion", symbolName: "tablecells", category: .spreadsheets, modifier: "", kind: .convert, extensions: ["xls"]),
        ConversionAction(id: "sheet-ods", title: "ODS", subtitle: "Spreadsheet conversion", symbolName: "tablecells", category: .spreadsheets, modifier: "", kind: .convert, extensions: ["ods"]),
        ConversionAction(id: "sheet-csv", title: "CSV", subtitle: "Spreadsheet conversion", symbolName: "tablecells", category: .spreadsheets, modifier: "", kind: .convert, extensions: ["csv"]),
        ConversionAction(id: "sheet-tsv", title: "TSV", subtitle: "Spreadsheet conversion", symbolName: "tablecells", category: .spreadsheets, modifier: "", kind: .convert, extensions: ["tsv"]),
        ConversionAction(id: "subtitle-srt", title: "SRT", subtitle: "Subtitle conversion", symbolName: "captions.bubble", category: .subtitles, modifier: "", kind: .convert, extensions: ["srt"]),
        ConversionAction(id: "subtitle-vtt", title: "VTT", subtitle: "Subtitle conversion", symbolName: "captions.bubble", category: .subtitles, modifier: "", kind: .convert, extensions: ["vtt"]),
        ConversionAction(id: "archive-tar", title: "TAR", subtitle: "Archive creation", symbolName: "archivebox", category: .archives, modifier: "", kind: .convert, extensions: ["tar"]),
        ConversionAction(id: "archive-gzip", title: "GZIP", subtitle: "Archive creation", symbolName: "archivebox", category: .archives, modifier: "", kind: .convert, extensions: ["gzip"]),
        ConversionAction(id: "archive-rar", title: "RAR", subtitle: "Archive extraction", symbolName: "archivebox", category: .archives, modifier: "", kind: .convert, extensions: ["rar"]),
        ConversionAction(id: "image-edit", title: "Edit Image", subtitle: "Image editor", symbolName: "slider.horizontal.3", category: .tools, modifier: "", kind: .tool, extensions: ["jpg", "png", "webp", "heic", "tiff"]),
        ConversionAction(id: "image-annotate", title: "Annotate", subtitle: "Image annotations", symbolName: "pencil.tip.crop.circle", category: .tools, modifier: "", kind: .tool, extensions: ["jpg", "png", "webp", "heic", "tiff"]),
        ConversionAction(id: "image-frame", title: "Frame Image", subtitle: "Image framing", symbolName: "rectangle.inset.filled", category: .tools, modifier: "", kind: .tool, extensions: ["jpg", "png", "webp", "heic", "tiff"]),
        ConversionAction(id: "image-crop", title: "Crop Image", subtitle: "Image crop", symbolName: "crop", category: .tools, modifier: "", kind: .tool, extensions: ["jpg", "png", "webp", "heic", "tiff"]),
        ConversionAction(id: "image-redact", title: "Redact Image", subtitle: "Image privacy tool", symbolName: "eye.slash", category: .tools, modifier: "", kind: .tool, extensions: ["jpg", "png", "webp", "heic", "tiff"]),
        ConversionAction(id: "compress", title: "Compress", subtitle: "Archive tool", symbolName: "arrow.down.right.and.arrow.up.left", category: .tools, modifier: "", kind: .tool, extensions: []),
        ConversionAction(id: "audio-normalize", title: "Normalize Audio", subtitle: "Audio tool", symbolName: "waveform.path.ecg", category: .tools, modifier: "", kind: .tool, extensions: ["mp3", "m4a", "wav", "flac", "ogg", "opus", "aiff", "wma"]),
        ConversionAction(id: "audio-trim", title: "Trim Audio", subtitle: "Audio tool", symbolName: "scissors", category: .tools, modifier: "", kind: .tool, extensions: ["mp3", "m4a", "wav", "flac", "ogg", "opus", "aiff", "wma"]),
        ConversionAction(id: "audio-channels", title: "Audio Channels", subtitle: "Audio tool", symbolName: "slider.horizontal.2.square", category: .tools, modifier: "", kind: .tool, extensions: ["mp3", "m4a", "wav", "flac", "ogg", "opus", "aiff", "wma"]),
        ConversionAction(id: "audio-redact", title: "Redact Audio", subtitle: "Audio privacy tool", symbolName: "waveform.badge.magnifyingglass", category: .tools, modifier: "", kind: .tool, extensions: ["mp3", "m4a", "wav", "flac", "ogg", "opus", "aiff", "wma"]),
        ConversionAction(id: "video-trim", title: "Trim Video", subtitle: "Video tool", symbolName: "scissors", category: .tools, modifier: "", kind: .tool, extensions: ["mp4", "mov", "mkv", "webm", "avi", "wmv"]),
        ConversionAction(id: "video-crop", title: "Crop Video", subtitle: "Video tool", symbolName: "crop", category: .tools, modifier: "", kind: .tool, extensions: ["mp4", "mov", "mkv", "webm", "avi", "wmv"]),
        ConversionAction(id: "video-speed", title: "Change Speed", subtitle: "Video tool", symbolName: "gauge.with.dots.needle.67percent", category: .tools, modifier: "", kind: .tool, extensions: ["mp4", "mov", "mkv", "webm", "avi", "wmv"]),
        ConversionAction(id: "video-snapshots", title: "Snapshots", subtitle: "Video tool", symbolName: "camera.aperture", category: .tools, modifier: "", kind: .tool, extensions: ["mp4", "mov", "mkv", "webm", "avi", "wmv"]),
        ConversionAction(id: "video-split", title: "Split Video", subtitle: "Video tool", symbolName: "rectangle.split.3x1", category: .tools, modifier: "", kind: .tool, extensions: ["mp4", "mov", "mkv", "webm", "avi", "wmv"]),
        ConversionAction(id: "video-redact", title: "Redact Video", subtitle: "Video privacy tool", symbolName: "eye.slash", category: .tools, modifier: "", kind: .tool, extensions: ["mp4", "mov", "mkv", "webm", "avi", "wmv"]),
        ConversionAction(id: "pdf-split", title: "Split PDF", subtitle: "PDF tool", symbolName: "rectangle.split.3x1", category: .tools, modifier: "", kind: .tool, extensions: ["pdf"]),
        ConversionAction(id: "pdf-organize", title: "Organize PDF", subtitle: "PDF tool", symbolName: "rectangle.3.group", category: .tools, modifier: "", kind: .tool, extensions: ["pdf"]),
        ConversionAction(id: "read-qr", title: "Read QR Code", subtitle: "Image tool", symbolName: "qrcode.viewfinder", category: .tools, modifier: "", kind: .tool, extensions: ["jpg", "png", "webp", "heic"]),
        ConversionAction(id: "copy-files", title: "Copy Files", subtitle: "File action", symbolName: "doc.on.doc", category: .tools, modifier: "", kind: .fileAction, extensions: []),
        ConversionAction(id: "move-files", title: "Move Files", subtitle: "File action", symbolName: "arrow.up.right.and.arrow.down.left", category: .tools, modifier: "", kind: .fileAction, extensions: []),
        ConversionAction(id: "open-terminal", title: "Open Terminal", subtitle: "File action", symbolName: "terminal", category: .tools, modifier: "", kind: .fileAction, extensions: []),
        ConversionAction(id: "airdrop", title: "AirDrop", subtitle: "File action", symbolName: "airplayaudio", category: .tools, modifier: "", kind: .fileAction, extensions: []),
        ConversionAction(id: "float-files", title: "Float Files", subtitle: "File action", symbolName: "pin", category: .tools, modifier: "", kind: .fileAction, extensions: [])
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
    @Published var activeModifier: DragModifier?
    @Published var activeWheel: WheelKind?
    @Published var isDraggingFiles = false
    @Published var isWorking = false
    @Published var progress = 0.0
    @Published var statusMessage = "Drag files and tap a shortcut"
    @Published var notice: OperationNotice?
    @Published var fanTheme: FanTheme
    @Published var soundsEnabled: Bool
    @Published var launchAtLogin = false

    private let defaults = UserDefaults.standard

    init() {
        hasCompletedWelcome = defaults.bool(forKey: "hasCompletedWelcome")
        fanTheme = FanTheme(rawValue: defaults.string(forKey: "conversionFanTheme") ?? "tangerine") ?? .tangerine
        soundsEnabled = defaults.object(forKey: "soundsAndHapticsEnabled") as? Bool ?? true
        activeModifier = nil
        activeWheel = nil
        isDraggingFiles = false
    }

    func actions(for wheel: WheelKind) -> [ConversionAction] {
        ConversionAction.catalog.filter { $0.wheel == wheel }
    }

    var activeMenuActions: [ConversionAction] {
        guard let activeWheel else { return [] }
        return actions(for: activeWheel)
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

    func receiveFiles(_ urls: [URL], modifier: DragModifier? = nil) {
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
        activeModifier = modifier
        activeWheel = modifier?.wheelKind
        let availableActions = activeWheel.map { actions(for: $0) } ?? ConversionAction.catalog
        selectedAction = availableActions.first
        statusMessage = activeWheel.map { "\($0.title) ready" } ?? "Drag files and tap a shortcut"
        notice = nil
    }

    func beginExternalDrag(_ urls: [URL], modifier: DragModifier?) {
        receiveFiles(urls, modifier: modifier)
        isDraggingFiles = true
    }

    func updateExternalDragModifier(_ modifier: DragModifier?) {
        guard isDraggingFiles else { return }
        activeModifier = modifier
        activeWheel = modifier?.wheelKind
        if let activeWheel {
            selectedAction = actions(for: activeWheel).first
            statusMessage = "\(activeWheel.title) ready"
        } else {
            selectedAction = nil
            statusMessage = "Tap Shift, Command, or Control"
        }
    }

    func finishExternalDrag() {
        isDraggingFiles = false
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Choose"
        if panel.runModal() == .OK {
            receiveFiles(panel.urls, modifier: nil)
        }
    }

    func importProviders(_ providers: [NSItemProvider]) -> Bool {
        let typeIdentifier = UTType.fileURL.identifier
        let modifier = DragModifier.currentEventModifier()
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
                    self?.receiveFiles([url], modifier: modifier)
                }
            }
        }
        return true
    }

    func select(_ action: ConversionAction) {
        selectedAction = action
        statusMessage = selectedFiles.isEmpty ? "Drag files and tap a shortcut" : "Selected \(action.title)"
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

        if action.kind == .fileAction {
            notice = OperationNotice(
                level: .warning,
                title: "Action options available",
                detail: "\(action.title) requires the documented destination or macOS sharing step; this clean-room build does not claim to execute it yet."
            )
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
        activeModifier = nil
        activeWheel = nil
        isDraggingFiles = false
        progress = 0
        statusMessage = "Drag files and tap a shortcut"
        notice = nil
    }
}
