import Foundation

struct SessionPersistenceSettings: Sendable, Equatable {
    var customDirectoryPath: String?
    var retentionLimit: Int

    static let `default` = SessionPersistenceSettings(
        customDirectoryPath: nil,
        retentionLimit: 12
    )
}

protocol SessionPersistenceSettingsStoring {
    func load() -> SessionPersistenceSettings
    func save(_ settings: SessionPersistenceSettings)
}

struct UserDefaultsSessionPersistenceSettingsStore: SessionPersistenceSettingsStoring {
    private enum Keys {
        static let customDirectoryPath = "persistSessions.customDirectoryPath"
        static let retentionLimit = "persistSessions.retentionLimit"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> SessionPersistenceSettings {
        let customDirectoryPath = userDefaults.string(forKey: Keys.customDirectoryPath)
        let storedLimit = userDefaults.integer(forKey: Keys.retentionLimit)
        let retentionLimit = storedLimit > 0 ? storedLimit : SessionPersistenceSettings.default.retentionLimit
        return SessionPersistenceSettings(
            customDirectoryPath: customDirectoryPath,
            retentionLimit: retentionLimit
        )
    }

    func save(_ settings: SessionPersistenceSettings) {
        if let customDirectoryPath = settings.customDirectoryPath {
            userDefaults.set(customDirectoryPath, forKey: Keys.customDirectoryPath)
        } else {
            userDefaults.removeObject(forKey: Keys.customDirectoryPath)
        }
        userDefaults.set(max(1, settings.retentionLimit), forKey: Keys.retentionLimit)
    }
}
