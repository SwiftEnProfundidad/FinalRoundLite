import AppKit
import UniformTypeIdentifiers

enum AudioFileImporter {
    @MainActor
    static func pickAudioFile(onPick: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.audio]

        panel.begin { response in
            guard response == .OK else {
                onPick(nil)
                return
            }
            onPick(panel.url)
        }
    }
}
