import Foundation

struct RuntimeSettings: Hashable, Sendable {
    var sendAudioToOpenAI: Bool
    var lowCostMode: Bool
    var languageCode: String
    var transcriptionModel: String
    var coachModel: String
}

