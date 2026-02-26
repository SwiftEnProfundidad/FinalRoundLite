import SwiftUI

@main
struct FinalRoundLiteApp: App {
    @State private var model: AppModel

    init() {
        _model = State(
            initialValue: AppModel(
                fileOpener: WorkspaceFileOpener()
            )
        )
    }

    var body: some Scene {
        MenuBarExtra("FinalRound Lite", systemImage: "sparkles") {
            MenuBarPanelView(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}
