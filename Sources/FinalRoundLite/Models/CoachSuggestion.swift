import Foundation

struct CoachSuggestion: Hashable, Sendable {
    var currentQuestion: String
    var shortScript: String
    var clarifyingQuestions: [String]
    var tradeoffs: [String]
    var nextSteps: [String]
    var createdAt: Date?
}

