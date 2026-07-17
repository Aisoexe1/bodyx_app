import ActivityKit
import Foundation

/// Shared between the Runner app (which starts/updates/ends the activity)
/// and the BodyXWidgets extension (which renders it) — this file is a
/// member of both targets. One activity per running timer, distinguished
/// by `kind`, so the workout and mobility timers can show independently
/// on the Lock Screen / Dynamic Island at the same time.
struct BodyXTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the timer was last (re)started; nil while paused.
        var startedAt: Date?
        /// Total seconds banked from previous start/stop segments — the
        /// live elapsed time is this plus (now - startedAt) while running.
        var accumulatedSeconds: Int
    }

    /// "workout" or "mobility" — which AppState timer this activity mirrors.
    var kind: String
    /// Localized display title, e.g. "Workout" / "Mobility & Stretch".
    var title: String
}
