//
//  LiveActivityBridge.swift
//  Runner
//
//  Bridges AppState's workout/mobility timers to a Lock Screen / Dynamic
//  Island Live Activity. Purely local ActivityKit updates (no push token,
//  no remote server involvement), so this needs no extra Apple Developer
//  capability beyond the app's existing entitlements — unlike Sign In with
//  Apple, this works on a free/personal development team.
//

import ActivityKit
import Flutter
import Foundation
import WidgetKit

@available(iOS 16.2, *)
final class LiveActivityBridge: NSObject {
    static let shared = LiveActivityBridge()

    private var activities: [String: Activity<BodyXTimerAttributes>] = [:]

    func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "bodyx/live_activity", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Doesn't address a specific activity, so it's handled before the
        // `kind` guard every other method below requires.
        if call.method == "consumePendingStop" {
            guard let defaults = UserDefaults(suiteName: BodyXTimerAttributes.appGroupId) else {
                result(nil)
                return
            }
            let stoppedKind = defaults.string(forKey: BodyXTimerAttributes.pendingStopKey)
            defaults.removeObject(forKey: BodyXTimerAttributes.pendingStopKey)
            result(stoppedKind)
            return
        }

        guard let args = call.arguments as? [String: Any],
              let kind = args["kind"] as? String
        else {
            result(FlutterError(code: "bad_args", message: "Missing kind", details: nil))
            return
        }

        switch call.method {
        case "startOrUpdate":
            let title = args["title"] as? String ?? kind
            let accumulatedSeconds = args["accumulatedSeconds"] as? Int ?? 0
            let startedAtMillis = args["startedAtMillis"] as? Int64
            let startedAt = startedAtMillis.map { Date(timeIntervalSince1970: Double($0) / 1000) }
            let endsAtMillis = args["endsAtMillis"] as? Int64
            let endsAt = endsAtMillis.map { Date(timeIntervalSince1970: Double($0) / 1000) }
            let state = BodyXTimerAttributes.ContentState(
                startedAt: startedAt, accumulatedSeconds: accumulatedSeconds, endsAt: endsAt)
            let content = ActivityContent(state: state, staleDate: nil)

            // A cached activity may have already been ended by the Lock
            // Screen Stop button (BodyXStopTimerIntent, running in the
            // widget extension process) without this dictionary finding
            // out — updating a dead activity is a silent no-op, so treat
            // anything not `.active` as gone and start a fresh one.
            if let activity = activities[kind], activity.activityState == .active {
                Task { await activity.update(content) }
            } else {
                activities.removeValue(forKey: kind)
                guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                    // User has Live Activities disabled system-wide — not an
                    // error, just a no-op, same as any other permission the
                    // rest of this app treats as optional.
                    result(nil)
                    return
                }
                do {
                    let attributes = BodyXTimerAttributes(kind: kind, title: title)
                    let activity = try Activity.request(
                        attributes: attributes, content: content)
                    activities[kind] = activity
                } catch {
                    result(FlutterError(
                        code: "start_failed", message: error.localizedDescription, details: nil))
                    return
                }
            }
            result(nil)

        case "end":
            if let activity = activities.removeValue(forKey: kind) {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

/// Receives today's dashboard numbers (and the pet) from Dart and drops
/// them into the shared App Group store, then asks WidgetKit to redraw —
/// this is how the Home Screen widgets get real data despite running in a
/// separate process with no Flutter engine.
final class WidgetOverviewBridge: NSObject {
    static let shared = WidgetOverviewBridge()

    func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "bodyx/widget_overview", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { call, result in
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterMethodNotImplemented)
                return
            }
            switch call.method {
            case "save":
                BodyXDailyOverviewData(
                    steps: args["steps"] as? Int ?? 0,
                    stepGoal: args["stepGoal"] as? Int ?? 10000,
                    calories: args["calories"] as? Int ?? 0,
                    calorieGoal: args["calorieGoal"] as? Int ?? 2200,
                    sleepMinutes: args["sleepMinutes"] as? Int ?? 0,
                    sleepGoalMinutes: args["sleepGoalMinutes"] as? Int ?? 480,
                    waterMl: args["waterMl"] as? Int ?? 0,
                    waterGoalMl: args["waterGoalMl"] as? Int ?? 2500
                ).save()
                WidgetCenter.shared.reloadAllTimelines()
                result(nil)

            case "savePet":
                // The dragon image travels as a real file in the shared App
                // Group container rather than through UserDefaults — 15
                // stages of custom-painted PNG data is too large to treat
                // as a small preference value.
                if let imageData = (args["petImagePng"] as? FlutterStandardTypedData)?.data,
                   let imageURL = BodyXPetWidgetData.imageURL {
                    try? imageData.write(to: imageURL, options: .atomic)
                }
                BodyXPetWidgetData(
                    level: args["level"] as? Int ?? 1,
                    stageLabel: args["stageLabel"] as? String ?? "",
                    xpIntoLevel: args["xpIntoLevel"] as? Int ?? 0,
                    xpGoal: args["xpGoal"] as? Int ?? 100
                ).save()
                WidgetCenter.shared.reloadTimelines(ofKind: "BodyXPetWidget")
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}

/// Entry point called from AppDelegate regardless of OS version — no-ops
/// below iOS 16.2 rather than requiring the call site to check availability.
enum LiveActivityRegistrar {
    static func register(with registrar: FlutterPluginRegistrar) {
        WidgetOverviewBridge.shared.register(with: registrar)
        if #available(iOS 16.2, *) {
            LiveActivityBridge.shared.register(with: registrar)
        }
    }
}
