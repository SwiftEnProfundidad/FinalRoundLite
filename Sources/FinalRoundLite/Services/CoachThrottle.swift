import Foundation

enum CoachThrottle {
    static func delay(lastCoachCallAt: Date?, now: Date, lowCostMode: Bool) -> TimeInterval {
        let throttleSeconds: TimeInterval = lowCostMode ? 15 : 8
        let elapsed = lastCoachCallAt.map { now.timeIntervalSince($0) } ?? .infinity
        return max(0, throttleSeconds - elapsed)
    }
}
