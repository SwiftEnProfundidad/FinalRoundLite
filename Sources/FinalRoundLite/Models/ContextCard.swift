import Foundation

struct ContextCard: Codable, Hashable, Sendable {
    var problem = ""
    var users = ""
    var scale = ""
    var data = ""
    var slos = ""
    var constraints = ""
    var preferredStack = ""

    var hasMeaningfulContent: Bool {
        ![problem, users, scale, data, slos, constraints, preferredStack]
            .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

