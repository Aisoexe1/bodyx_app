import Foundation

/// The pet's Home Screen widget data, written by the Runner app and read by
/// the BodyXWidgets extension — same split as BodyXDailyOverviewData, since
/// the two run in separate processes. The dragon image itself is too big
/// (and too stage-dependent — 15 stages of custom Flutter-side painting) to
/// redraw natively, so it's shipped as a real PNG file in the shared App
/// Group container rather than embedded in UserDefaults; this struct only
/// carries the file name plus the small bits of text/numbers around it.
struct BodyXPetWidgetData: Codable {
    var level: Int
    var stageLabel: String
    var xpIntoLevel: Int
    var xpGoal: Int

    static let appGroupId = "group.com.bodyx.bodyxApp"
    private static let storageKey = "bodyx.pet_widget"
    // Always overwritten in place on every push, so there's never more than
    // one pet image file to clean up — no per-update unique naming needed.
    static let imageFileName = "bodyx_pet_widget.png"

    static func load() -> BodyXPetWidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let raw = defaults.data(forKey: storageKey)
        else { return nil }
        return try? JSONDecoder().decode(BodyXPetWidgetData.self, from: raw)
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId),
              let raw = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(raw, forKey: Self.storageKey)
    }

    /// The shared container directory both the Runner app and the widget
    /// extension can read/write — where the actual PNG file lives.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    static var imageURL: URL? {
        containerURL?.appendingPathComponent(imageFileName)
    }
}
