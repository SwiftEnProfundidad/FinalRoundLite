import AppKit

enum SessionDirectoryPicker {
    @MainActor
    static func pickDirectory(onPick: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Seleccionar carpeta"

        panel.begin { response in
            guard response == .OK else {
                onPick(nil)
                return
            }
            onPick(panel.url)
        }
    }
}
