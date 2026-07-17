//
//  BodyXWidgetsLiveActivity.swift
//  BodyXWidgets
//

import ActivityKit
import WidgetKit
import SwiftUI

/// Ticks natively (no app-side updates needed while running) by rendering
/// the elapsed time as a `.timer`-style Text anchored to a reference date
/// shifted back by the already-banked seconds — the OS keeps it live.
private func referenceDate(for state: BodyXTimerAttributes.ContentState) -> Date {
    (state.startedAt ?? Date()).addingTimeInterval(-Double(state.accumulatedSeconds))
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

struct BodyXWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BodyXTimerAttributes.self) { context in
            LockScreenTimerView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(bxBackground)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let running = context.state.startedAt != nil
            let tint = running ? bxSuccess : bxPrimary

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: symbolName(for: context.attributes.kind))
                        .foregroundStyle(tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if running {
                        Text(referenceDate(for: context.state), style: .timer)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    } else {
                        Text(staticElapsedLabel(context.state.accumulatedSeconds))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: symbolName(for: context.attributes.kind))
                    .foregroundStyle(tint)
            } compactTrailing: {
                if running {
                    Text(referenceDate(for: context.state), style: .timer)
                        .monospacedDigit()
                        .frame(width: 42)
                } else {
                    Text(staticElapsedLabel(context.state.accumulatedSeconds))
                        .monospacedDigit()
                }
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
        let running = state.startedAt != nil
        HStack(spacing: 14) {
            Image(systemName: symbolName(for: attributes.kind))
                .font(.title2)
                .foregroundStyle(running ? bxSuccess : bxPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(running ? "In progress" : "Paused")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            if running {
                Text(referenceDate(for: state), style: .timer)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(bxBright)
            } else {
                Text(staticElapsedLabel(state.accumulatedSeconds))
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
    }
}

extension BodyXTimerAttributes {
    fileprivate static var previewWorkout: BodyXTimerAttributes {
        BodyXTimerAttributes(kind: "workout", title: "Workout")
    }
}

extension BodyXTimerAttributes.ContentState {
    fileprivate static var running: BodyXTimerAttributes.ContentState {
        BodyXTimerAttributes.ContentState(startedAt: Date(), accumulatedSeconds: 125)
    }

    fileprivate static var paused: BodyXTimerAttributes.ContentState {
        BodyXTimerAttributes.ContentState(startedAt: nil, accumulatedSeconds: 245)
    }
}

#Preview("Notification", as: .content, using: BodyXTimerAttributes.previewWorkout) {
   BodyXWidgetsLiveActivity()
} contentStates: {
    BodyXTimerAttributes.ContentState.running
    BodyXTimerAttributes.ContentState.paused
}
