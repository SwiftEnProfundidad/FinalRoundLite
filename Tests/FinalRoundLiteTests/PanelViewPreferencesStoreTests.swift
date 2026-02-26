import XCTest
@testable import FinalRoundLite

final class PanelViewPreferencesStoreTests: XCTestCase {
    func testLoad_returnsDefaultValuesWhenNoStoredPreferences() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsPanelViewPreferencesStore(userDefaults: userDefaults)

        let preferences = store.load()

        XCTAssertEqual(preferences, .default)
    }

    func testSave_persistsPreferencesRoundTrip() {
        let userDefaults = makeUserDefaults()
        let store = UserDefaultsPanelViewPreferencesStore(userDefaults: userDefaults)
        let expected = PanelViewPreferences(
            isCompactMode: true,
            isTranscriptExpanded: true,
            isCoachExpanded: false
        )

        store.save(expected)
        let loaded = store.load()

        XCTAssertEqual(loaded, expected)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "PanelViewPreferencesStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("No se pudo crear UserDefaults para pruebas")
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
