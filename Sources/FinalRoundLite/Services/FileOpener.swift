import AppKit
import Foundation

protocol FileOpening {
    @MainActor
    @discardableResult
    func open(_ url: URL) -> Bool

    @MainActor
    @discardableResult
    func reveal(_ url: URL) -> Bool
}

struct WorkspaceFileOpener: FileOpening {
    @MainActor
    func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    @MainActor
    func reveal(_ url: URL) -> Bool {
        NSWorkspace.shared.activateFileViewerSelecting([url])
        return true
    }
}
