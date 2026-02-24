import AppKit
import Foundation
import UniformTypeIdentifiers

enum FileExporter {
    @MainActor
    static func saveMarkdown(_ markdown: String, defaultFilename: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = defaultFilename
        let markdownType = UTType(filenameExtension: "md") ?? .plainText
        panel.allowedContentTypes = [markdownType, .plainText]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try markdown.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    static func defaultFilename(now: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return "finalround-lite-\(formatter.string(from: now)).md"
    }
}
