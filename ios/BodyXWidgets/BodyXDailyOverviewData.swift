import Foundation

/// Today's dashboard numbers, written by the Runner app and read by the
/// BodyXWidgets Home Screen widget — the two run in separate processes, so
/// this travels through a shared App Group UserDefaults suite rather than
/// any direct in-memory reference.
struct BodyXDailyOverviewData: Codable {
    var steps: Int
    var stepGoal: Int
    var calories: Int
    var calorieGoal: Int
    var sleepMinutes: Int
    var sleepGoalMinutes: Int
    var waterMl: Int
    var waterGoalMl: Int

    static let appGroupId = "group.com.bodyx.bodyxApp"
    private static let storageKey = "bodyx.daily_overview"

    static func load() -> BodyXDailyOverviewData? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let raw = defaults.data(forKey: storageKey)
        else { return nil }
        return try? JSONDecoder().decode(BodyXDailyOverviewData.self, from: raw)
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId),
              let raw = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(raw, forKey: Self.storageKey)
    }
}
