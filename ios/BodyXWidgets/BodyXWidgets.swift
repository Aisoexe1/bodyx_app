//
//  BodyXWidgets.swift
//  BodyXWidgets
//
//  Home Screen "daily overview" widget — mirrors the dashboard's Daily
//  overview card (steps ring + steps/calories/sleep/water lines). Data
//  arrives through the shared App Group store (see BodyXDailyOverviewData);
//  the app rewrites it and reloads timelines whenever today's numbers
//  change. Deliberately a plain TimelineProvider (no AppIntents): the App
//  Intents metadata build step cycles against Flutter's Thin Binary phase.
//

import WidgetKit
import SwiftUI

private let bxBackground = Color(red: 0.0392, green: 0.0549, blue: 0.0784)
private let bxPrimary = Color(red: 0.055, green: 0.608, blue: 0.820)
private let bxBright = Color(red: 0.373, green: 0.847, blue: 1.0)
private let bxWarning = Color(red: 1.0, green: 0.420, blue: 0.290)
private let bxInfo = Color(red: 0.239, green: 0.863, blue: 0.592)

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> OverviewEntry {
        OverviewEntry(date: Date(), data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (OverviewEntry) -> Void) {
        completion(OverviewEntry(date: Date(), data: BodyXDailyOverviewData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OverviewEntry>) -> Void) {
        let entry = OverviewEntry(date: Date(), data: BodyXDailyOverviewData.load())
        // Refresh every 30 min as a fallback; the app also force-reloads
        // timelines whenever it writes fresh numbers.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct OverviewEntry: TimelineEntry {
    let date: Date
    let data: BodyXDailyOverviewData?
}

struct BodyXWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let data = entry.data {
            switch family {
            case .systemMedium:
                MediumOverviewView(data: data)
            default:
                SmallOverviewView(data: data)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "bolt.fill").foregroundStyle(bxBright)
                Text("BodyX").font(.headline).foregroundStyle(.white)
                Text("Open the app once to fill this in")
                    .font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SmallOverviewView: View {
    let data: BodyXDailyOverviewData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StepsRing(progress: data.stepProgress, size: 44)
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(bxBright)
            }
            Text("\(data.steps)")
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
            Text("of \(data.stepGoal) steps")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 10) {
                MiniStat(icon: "flame.fill", color: bxWarning, text: "\(data.calories)")
                MiniStat(icon: "drop.fill", color: bxPrimary,
                         text: String(format: "%.1fL", Double(data.waterMl) / 1000))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumOverviewView: View {
    let data: BodyXDailyOverviewData

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                StepsRing(progress: data.stepProgress, size: 64)
                Text("\(data.steps)")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 7) {
                StatRow(icon: "figure.walk", color: bxBright,
                        label: "Steps", value: "\(data.steps) / \(data.stepGoal)")
                StatRow(icon: "flame.fill", color: bxWarning,
                        label: "Calories", value: "\(data.calories) kcal")
                StatRow(icon: "moon.fill", color: bxInfo,
                        label: "Sleep", value: sleepLabel)
                StatRow(icon: "drop.fill", color: bxPrimary,
                        label: "Water",
                        value: String(format: "%.1f / %.1fL",
                                      Double(data.waterMl) / 1000,
                                      Double(data.waterGoalMl) / 1000))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sleepLabel: String {
        "\(data.sleepMinutes / 60)h \(data.sleepMinutes % 60)m"
    }
}

private struct StepsRing: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: size * 0.11)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(bxBright,
                        style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "figure.walk")
                .font(.system(size: size * 0.34))
                .foregroundStyle(bxBright)
        }
        .frame(width: size, height: size)
    }
}

private struct MiniStat: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.caption2).foregroundStyle(color)
            Text(text)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

private struct StatRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .frame(width: 14)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}

extension BodyXDailyOverviewData {
    var stepProgress: Double {
        stepGoal <= 0 ? 0 : min(1, Double(steps) / Double(stepGoal))
    }
}

struct BodyXWidgets: Widget {
    let kind: String = "BodyXWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BodyXWidgetsEntryView(entry: entry)
                .containerBackground(bxBackground, for: .widget)
        }
        .configurationDisplayName("Daily overview")
        .description("Today's steps, calories, sleep and water.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BodyXWidgets()
} timeline: {
    OverviewEntry(date: .now, data: BodyXDailyOverviewData(
        steps: 6540, stepGoal: 10000, calories: 480, calorieGoal: 2200,
        sleepMinutes: 432, sleepGoalMinutes: 480, waterMl: 1400, waterGoalMl: 2500))
}
