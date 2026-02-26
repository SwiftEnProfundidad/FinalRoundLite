import Foundation

struct PanelViewPreferences: Sendable, Equatable {
    var isCompactMode: Bool
    var isTranscriptExpanded: Bool
    var isCoachExpanded: Bool

    static let `default` = PanelViewPreferences(
        isCompactMode: false,
        isTranscriptExpanded: false,
        isCoachExpanded: false
    )
}

protocol PanelViewPreferencesStoring {
    func load() -> PanelViewPreferences
    func save(_ preferences: PanelViewPreferences)
}

struct UserDefaultsPanelViewPreferencesStore: PanelViewPreferencesStoring {
    private enum Keys {
        static let compactMode = "panelView.compactMode"
        static let transcriptExpanded = "panelView.transcriptExpanded"
        static let coachExpanded = "panelView.coachExpanded"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> PanelViewPreferences {
        if userDefaults.object(forKey: Keys.compactMode) == nil,
           userDefaults.object(forKey: Keys.transcriptExpanded) == nil,
           userDefaults.object(forKey: Keys.coachExpanded) == nil {
            return .default
        }

        return PanelViewPreferences(
            isCompactMode: userDefaults.bool(forKey: Keys.compactMode),
            isTranscriptExpanded: userDefaults.bool(forKey: Keys.transcriptExpanded),
            isCoachExpanded: userDefaults.bool(forKey: Keys.coachExpanded)
        )
    }

    func save(_ preferences: PanelViewPreferences) {
        userDefaults.set(preferences.isCompactMode, forKey: Keys.compactMode)
        userDefaults.set(preferences.isTranscriptExpanded, forKey: Keys.transcriptExpanded)
        userDefaults.set(preferences.isCoachExpanded, forKey: Keys.coachExpanded)
    }
}
