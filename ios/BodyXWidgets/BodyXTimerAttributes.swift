import ActivityKit
import Foundation

/// Shared between the Runner app (which starts/updates/ends the activity)
/// and the BodyXWidgets extension (which renders it) — this file is a
/// member of both targets. One activity per running timer, distinguished
/// by `kind`, so the workout and mobility timers can show independently
/// on the Lock Screen / Dynamic Island at the same time.
struct BodyXTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the timer was last (re)started; nil while paused. Mutually
        /// exclusive with `endsAt` — a given activity is either counting up
        /// from a start time (workout) or down to an end time (mobility).
        var startedAt: Date?
        /// Total seconds banked from previous start/stop segments — the
        /// live elapsed time is this plus (now - startedAt) while running.
        var accumulatedSeconds: Int
        /// Set for a countdown (mobility's per-activity timer): the moment
        /// it reaches zero. Nil for a count-up timer (workout).
        var endsAt: Date?
    }

    /// "workout" or "mobility" — which AppState timer this activity mirrors.
    var kind: String
    /// Localized display title, e.g. "Workout" / the mobility activity name.
    var title: String
}

/// Shared App Group storage so the widget extension (which can end a Live
/// Activity from a Lock Screen button tap, entirely without the Flutter app
/// running) can leave a note for the app to pick up on its next launch or
/// resume — ActivityKit intents can act on the activity directly, but they
/// can't call back into the Flutter engine.
extension BodyXTimerAttributes {
    static let appGroupId = "group.com.bodyx.bodyxApp"
    static let pendingStopKey = "bodyx.live_activity.pending_stop_kind"
}
