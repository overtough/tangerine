import AppKit

@MainActor
final class DragGestureMonitor {
    private let model: ReplicaModel
    private let overlay: ConversionOverlayController
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(model: ReplicaModel, overlay: ConversionOverlayController) {
        self.model = model
        self.overlay = overlay
        start()
    }

    deinit {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
    }

    private func start() {
        let eventMask: NSEvent.EventTypeMask = [
            .leftMouseDragged,
            .flagsChanged,
            .leftMouseUp
        ]

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handle(event)
            }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handle(event)
            }
        }
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDragged:
            guard let urls = draggedFileURLs(), !urls.isEmpty else { return }
            let modifier = DragModifier.from(flags: event.modifierFlags)
            if model.isDraggingFiles {
                model.updateExternalDragModifier(modifier)
            } else {
                model.beginExternalDrag(urls, modifier: modifier)
                print("[TangerineReplica] drag shortcut monitor started")
                overlay.show(at: NSEvent.mouseLocation)
            }

        case .flagsChanged:
            guard model.isDraggingFiles else { return }
            model.updateExternalDragModifier(DragModifier.from(flags: event.modifierFlags))

        case .leftMouseUp:
            guard model.isDraggingFiles else { return }
            model.finishExternalDrag()
            overlay.hide()

        default:
            break
        }
    }

    private func draggedFileURLs() -> [URL]? {
        let pasteboard = NSPasteboard(name: .drag)
        let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) ?? []
        let urls = objects.compactMap { ($0 as? NSURL)?.filePathURL }
        return urls.isEmpty ? nil : urls
    }
}
