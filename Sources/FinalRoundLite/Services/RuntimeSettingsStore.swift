import Foundation

struct RuntimeSettingsPreferences: Sendable, Equatable {
    var sendAudioToOpenAI: Bool
    var lowCostMode: Bool
    var persistSessionsLocally: Bool
    var languageCode: String
    var transcriptionModel: String
    var coachModel: String

    static let `default` = RuntimeSettingsPreferences(
        sendAudioToOpenAI: false,
        lowCostMode: false,
        persistSessionsLocally: false,
        languageCode: "es",
        transcriptionModel: "gpt-4o-mini-transcribe",
        coachModel: "gpt-4o-mini"
    )
}

protocol RuntimeSettingsStoring {
    func load() -> RuntimeSettingsPreferences
    func save(_ preferences: RuntimeSettingsPreferences)
}

struct UserDefaultsRuntimeSettingsStore: RuntimeSettingsStoring {
    private enum Keys {
        static let sendAudioToOpenAI = "runtimeSettings.sendAudioToOpenAI"
        static let lowCostMode = "runtimeSettings.lowCostMode"
        static let persistSessionsLocally = "runtimeSettings.persistSessionsLocally"
        static let languageCode = "runtimeSettings.languageCode"
        static let transcriptionModel = "runtimeSettings.transcriptionModel"
        static let coachModel = "runtimeSettings.coachModel"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> RuntimeSettingsPreferences {
        let hasStoredValues =
            userDefaults.object(forKey: Keys.sendAudioToOpenAI) != nil ||
            userDefaults.object(forKey: Keys.lowCostMode) != nil ||
            userDefaults.object(forKey: Keys.persistSessionsLocally) != nil ||
            userDefaults.object(forKey: Keys.languageCode) != nil ||
            userDefaults.object(forKey: Keys.transcriptionModel) != nil ||
            userDefaults.object(forKey: Keys.coachModel) != nil

        guard hasStoredValues else {
            return .default
        }

        let languageCode = userDefaults.string(forKey: Keys.languageCode)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let transcriptionModel = userDefaults.string(forKey: Keys.transcriptionModel)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let coachModel = userDefaults.string(forKey: Keys.coachModel)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return RuntimeSettingsPreferences(
            sendAudioToOpenAI: userDefaults.bool(forKey: Keys.sendAudioToOpenAI),
            lowCostMode: userDefaults.bool(forKey: Keys.lowCostMode),
            persistSessionsLocally: userDefaults.bool(forKey: Keys.persistSessionsLocally),
            languageCode: nonEmpty(languageCode, fallback: RuntimeSettingsPreferences.default.languageCode),
            transcriptionModel: nonEmpty(
                transcriptionModel,
                fallback: RuntimeSettingsPreferences.default.transcriptionModel
            ),
            coachModel: nonEmpty(coachModel, fallback: RuntimeSettingsPreferences.default.coachModel)
        )
    }

    func save(_ preferences: RuntimeSettingsPreferences) {
        userDefaults.set(preferences.sendAudioToOpenAI, forKey: Keys.sendAudioToOpenAI)
        userDefaults.set(preferences.lowCostMode, forKey: Keys.lowCostMode)
        userDefaults.set(preferences.persistSessionsLocally, forKey: Keys.persistSessionsLocally)
        userDefaults.set(preferences.languageCode, forKey: Keys.languageCode)
        userDefaults.set(preferences.transcriptionModel, forKey: Keys.transcriptionModel)
        userDefaults.set(preferences.coachModel, forKey: Keys.coachModel)
    }

    private func nonEmpty(_ value: String?, fallback: String) -> String {
        guard let value, !value.isEmpty else {
            return fallback
        }
        return value
    }
}
