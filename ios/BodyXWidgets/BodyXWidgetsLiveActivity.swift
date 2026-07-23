//
//  BodyXWidgetsLiveActivity.swift
//  BodyXWidgets
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

/// Either counting up from a start time (workout) or down to an end time
/// (mobility's per-activity countdown) — or, briefly, paused (workout only;
/// mobility's countdown has no paused state, it just ends).
private enum TimerMode {
    case countingUp(referenceDate: Date)
    case countdown(endsAt: Date)
    case paused(seconds: Int)
}

private func mode(for state: BodyXTimerAttributes.ContentState) -> TimerMode {
    if let endsAt = state.endsAt {
        return .countdown(endsAt: endsAt)
    }
    if let startedAt = state.startedAt {
        return .countingUp(
            referenceDate: startedAt.addingTimeInterval(-Double(state.accumulatedSeconds)))
    }
    return .paused(seconds: state.accumulatedSeconds)
}

private func isActive(_ state: BodyXTimerAttributes.ContentState) -> Bool {
    state.startedAt != nil || state.endsAt != nil
}

private func staticElapsedLabel(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
        return String(format: "%dh %02dm", h, m)
    }
    return String(format: "%02d:%02d", m, s)
}

private func symbolName(for kind: String) -> String {
    kind == "workout" ? "figure.strengthtraining.traditional" : "figure.flexibility"
}

private let bxBackground = Color(red: 0.0392, green: 0.0549, blue: 0.0784)
private let bxPrimary = Color(red: 0.055, green: 0.608, blue: 0.820)
private let bxBright = Color(red: 0.373, green: 0.847, blue: 1.0)
private let bxSuccess = Color(red: 0.239, green: 0.863, blue: 0.592)

@ViewBuilder
private func timerText(for state: BodyXTimerAttributes.ContentState) -> some View {
    switch mode(for: state) {
    case .countingUp(let referenceDate):
        Text(referenceDate, style: .timer)
    case .countdown(let endsAt):
        Text(endsAt, style: .timer)
    case .paused(let seconds):
        Text(staticElapsedLabel(seconds))
    }
}

struct BodyXWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BodyXTimerAttributes.self) { context in
            LockScreenTimerView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(bxBackground)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let running = isActive(context.state)
            let tint = running ? bxSuccess : bxPrimary

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: symbolName(for: context.attributes.kind))
                        .foregroundStyle(tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timerText(for: context.state)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if #available(iOS 17.0, *), running {
                        StopTimerButton(kind: context.attributes.kind)
                    }
                }
            } compactLeading: {
                Image(systemName: symbolName(for: context.attributes.kind))
                    .foregroundStyle(tint)
            } compactTrailing: {
                timerText(for: context.state)
                    .monospacedDigit()
                    .frame(width: 42)
            } minimal: {
                Image(systemName: symbolName(for: context.attributes.kind))
                    .foregroundStyle(tint)
            }
            .keylineTint(tint)
        }
    }
}

private struct LockScreenTimerView: View {
    let attributes: BodyXTimerAttributes
    let state: BodyXTimerAttributes.ContentState

    var body: some View {
        let running = isActive(state)
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: symbolName(for: attributes.kind))
                    .font(.title2)
                    .foregroundStyle(running ? bxSuccess : bxPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(running ? "In progress" : "Paused")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                timerText(for: state)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(running ? bxBright : .white)
            }

            if #available(iOS 17.0, *), running {
                StopTimerButton(kind: attributes.kind)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
    }
}

@available(iOS 17.0, *)
private struct StopTimerButton: View {
    let kind: String

    var body: some View {
        Button(intent: BodyXStopTimerIntent(kind: kind)) {
            Label("Stop", systemImage: "stop.fill")
                .font(.footnote.weight(.semibold))
        }
        .tint(.red)
        .buttonStyle(.bordered)
    }
}

extension BodyXTimerAttributes {
    fileprivate static var previewWorkout: BodyXTimerAttributes {
        BodyXTimerAttributes(kind: "workout", title: "Workout")
    }
}

extension BodyXTimerAttributes.ContentState {
    fileprivate static var running: BodyXTimerAttributes.ContentState {
        BodyXTimerAttributes.ContentState(
            startedAt: Date(), accumulatedSeconds: 125, endsAt: nil)
    }

    fileprivate static var paused: BodyXTimerAttributes.ContentState {
        BodyXTimerAttributes.ContentState(
            startedAt: nil, accumulatedSeconds: 245, endsAt: nil)
    }
}

#Preview("Notification", as: .content, using: BodyXTimerAttributes.previewWorkout) {
   BodyXWidgetsLiveActivity()
} contentStates: {
    BodyXTimerAttributes.ContentState.running
    BodyXTimerAttributes.ContentState.paused
}
