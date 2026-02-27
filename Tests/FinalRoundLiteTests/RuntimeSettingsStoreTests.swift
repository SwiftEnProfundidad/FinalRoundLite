import XCTest
@testable import FinalRoundLite

final class RuntimeSettingsStoreTests: XCTestCase {
    func testLoad_returnsDefaultValuesWhenNoStoredPreferences() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsRuntimeSettingsStore(userDefaults: userDefaults)

        let preferences = store.load()

        XCTAssertEqual(preferences, .default)
    }

    func testSave_persistsPreferencesRoundTrip() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsRuntimeSettingsStore(userDefaults: userDefaults)
        let expected = RuntimeSettingsPreferences(
            sendAudioToOpenAI: true,
            lowCostMode: true,
            persistSessionsLocally: true,
            languageCode: "en",
            transcriptionModel: "gpt-4o-transcribe",
            coachModel: "gpt-4.1-mini"
        )

        store.save(expected)
        let loaded = store.load()

        XCTAssertEqual(loaded, expected)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "RuntimeSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("No se pudo crear UserDefaults para pruebas")
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
