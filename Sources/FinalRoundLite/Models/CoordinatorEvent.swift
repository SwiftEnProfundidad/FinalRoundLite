import Foundation

enum CoordinatorEvent: Sendable {
    case started
    case stopped
    case statusChanged(AppModel.Status)
    case transcriptAppended(String)
    case suggestionUpdated(CoachSuggestion)
    case error(String)
}

