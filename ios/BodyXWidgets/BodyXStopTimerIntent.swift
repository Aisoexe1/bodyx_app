//
//  BodyXStopTimerIntent.swift
//  BodyXWidgets
//
//  Lets the Lock Screen / Dynamic Island "Stop" button end a running timer
//  without launching the app — Live Activity button intents run in this
//  extension's own process. Ending the activity here is immediate and
//  reliable; telling the Flutter app about it is best-effort (there's no
//  Flutter engine in this process to call into), so the stop is also
//  recorded in the shared App Group store for AppState to pick up on its
//  next launch or resume (see LiveActivityBridge.consumePendingStop).
//

import ActivityKit
import AppIntents

@available(iOS 17.0, *)
struct BodyXStopTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stops the running BodyX timer.")

    @Parameter(title: "kind")
    var kind: String

    init() {
        kind = ""
    }

    init(kind: String) {
        self.kind = kind
    }

    func perform() async throws -> some IntentResult {
        if let defaults = UserDefaults(suiteName: BodyXTimerAttributes.appGroupId) {
            defaults.set(kind, forKey: BodyXTimerAttributes.pendingStopKey)
        }
        for activity in Activity<BodyXTimerAttributes>.activities where activity.attributes.kind == kind {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
