//
//  BodyXPetWidget.swift
//  BodyXWidgets
//
//  Home Screen widget showing the dragon pet — level, stage name, and XP
//  progress. The dragon image itself is rendered Dart-side (DragonPainter,
//  the same 15-stage custom painter the in-app pet card uses) and shipped
//  in as a PNG via the shared App Group container (see
//  BodyXPetWidgetData.swift); this file just lays the image and numbers
//  out, the same split BodyXWidgets.swift uses for the daily-overview data.
//

import WidgetKit
import SwiftUI

private let bxBackground = Color(red: 0.0392, green: 0.0549, blue: 0.0784)
private let bxPrimary = Color(red: 0.055, green: 0.608, blue: 0.820)
private let bxBright = Color(red: 0.373, green: 0.847, blue: 1.0)

struct PetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: Date(), data: nil, image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        // Refresh every 30 min as a fallback; the app also force-reloads
        // this widget's timeline whenever it pushes fresh pet data.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [loadEntry()], policy: .after(next)))
    }

    private func loadEntry() -> PetEntry {
        let data = BodyXPetWidgetData.load()
        let image = BodyXPetWidgetData.imageURL
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { UIImage(data: $0) }
        return PetEntry(date: Date(), data: data, image: image)
    }
}

struct PetEntry: TimelineEntry {
    let date: Date
    let data: BodyXPetWidgetData?
    let image: UIImage?
}

struct BodyXPetWidgetEntryView: View {
    var entry: PetProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let data = entry.data, let image = entry.image {
            switch family {
            case .systemMedium:
                MediumPetView(data: data, image: image)
            default:
                SmallPetView(data: data, image: image)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "pawprint.fill").foregroundStyle(bxBright)
                Text("Your pet").font(.headline).foregroundStyle(.white)
                Text("Open the app once to fill this in")
                    .font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct SmallPetView: View {
    let data: BodyXPetWidgetData
    let image: UIImage

    var body: some View {
        VStack(spacing: 4) {
            // A fixed size, not maxHeight: .infinity — letting the image
            // greedily fill the VStack's height left almost nothing for
            // the level text and XP bar below it to render into.
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
            Text("Lv. \(data.level)")
                .font(.caption.weight(.bold))
                .foregroundStyle(bxBright)
            XpBar(progress: data.xpProgress)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MediumPetView: View {
    let data: BodyXPetWidgetData
    let image: UIImage

    var body: some View {
        HStack(spacing: 14) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text(data.stageLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Level \(data.level)")
                    .font(.caption)
                    .foregroundStyle(bxBright)
                XpBar(progress: data.xpProgress)
                Text("\(data.xpIntoLevel) / \(data.xpGoal) XP")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct XpBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(bxPrimary)
                    .frame(width: max(4, geo.size.width * progress))
            }
        }
        // GeometryReader has no intrinsic size of its own — without an
        // explicit maxWidth it can collapse to whatever sliver its parent
        // happens to leave it, which is how the small widget ended up with
        // both capsules squeezed down to the same tiny "always full" nub.
        .frame(maxWidth: .infinity, minHeight: 6, maxHeight: 6)
    }
}

private extension BodyXPetWidgetData {
    var xpProgress: Double {
        xpGoal <= 0 ? 0 : min(1, Double(xpIntoLevel) / Double(xpGoal))
    }
}

struct BodyXPetWidget: Widget {
    let kind: String = "BodyXPetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetProvider()) { entry in
            BodyXPetWidgetEntryView(entry: entry)
                .containerBackground(bxBackground, for: .widget)
        }
        .configurationDisplayName("Your pet")
        .description("Your dragon's level and XP progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BodyXPetWidget()
} timeline: {
    PetEntry(
        date: .now,
        data: BodyXPetWidgetData(level: 5, stageLabel: "Young Dragon", xpIntoLevel: 40, xpGoal: 100),
        image: nil
    )
}
