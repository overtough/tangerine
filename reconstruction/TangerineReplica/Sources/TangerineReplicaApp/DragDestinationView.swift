import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DragDestinationView: NSViewRepresentable {
    @ObservedObject var model: ReplicaModel
    let onDrop: () -> Void

    func makeNSView(context: Context) -> FanDragDestinationNSView {
        FanDragDestinationNSView(model: model, onDrop: onDrop)
    }

    func updateNSView(_ nsView: FanDragDestinationNSView, context: Context) {
        nsView.model = model
        nsView.onDrop = onDrop
    }
}

@MainActor
final class FanDragDestinationNSView: NSView {
    var model: ReplicaModel
    var onDrop: () -> Void

    init(model: ReplicaModel, onDrop: @escaping () -> Void) {
        self.model = model
        self.onDrop = onDrop
        super.init(frame: .zero)
        registerForDraggedTypes([.fileURL])
        wantsLayer = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        model.isDraggingFiles ? super.hitTest(point) : nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        updateHighlight(from: sender)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        updateHighlight(from: sender)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        model.highlightAction(nil)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        updateHighlight(from: sender)
        model.commitExternalDrop()
        onDrop()
        return true
    }

    private func updateHighlight(from info: NSDraggingInfo) {
        let location = convert(info.draggingLocation, from: nil)
        let actions = model.visibleWheelActions
        model.highlightAction(FanGeometry.action(at: location, in: bounds.size, actions: actions))
    }
}
