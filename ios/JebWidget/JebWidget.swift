import SwiftUI
import WidgetKit

// Home-screen widget: this month's spend, plus the budget bar when an overall
// budget is set. Values arrive pre-formatted from the Flutter side
// (HomeWidgetService) through the shared app-group UserDefaults.

private let appGroupId = "group.com.woltrap.jebapp"

struct JebEntry: TimelineEntry {
    let date: Date
    let monthLabel: String
    let spentText: String?
    let budgetText: String
    let progress: Int
    let overBudget: Bool
    let dailyText: String

    static let sample = JebEntry(
        date: Date(),
        monthLabel: "July 2026",
        spentText: "Rs52,300",
        budgetText: "Rs80,000",
        progress: 65,
        overBudget: false,
        dailyText: "Rs2,300/day · 12 days left"
    )
}

struct JebProvider: TimelineProvider {
    func placeholder(in context: Context) -> JebEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (JebEntry) -> Void) {
        completion(context.isPreview ? .sample : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JebEntry>) -> Void) {
        // The app pushes updates on every data change; the hourly refresh is
        // just a fallback so the month label rolls over at month boundaries.
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [load()], policy: .after(refresh)))
    }

    private func load() -> JebEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return JebEntry(
            date: Date(),
            monthLabel: defaults?.string(forKey: "month_label") ?? "",
            spentText: defaults?.string(forKey: "spent_text"),
            budgetText: defaults?.string(forKey: "budget_text") ?? "",
            progress: defaults?.integer(forKey: "progress") ?? 0,
            overBudget: defaults?.bool(forKey: "over_budget") ?? false,
            dailyText: defaults?.string(forKey: "daily_text") ?? ""
        )
    }
}

struct JebWidgetView: View {
    let entry: JebEntry

    /// Warm red that stays readable on the green card — used for the bar and
    /// subtitle once the budget is exceeded.
    private static let overColor = Color(red: 1.0, green: 0.55, blue: 0.48)
    private static let overTextColor = Color(red: 1.0, green: 0.78, blue: 0.74)

    private var subtitle: String {
        if entry.spentText == nil { return "to see this month's spending" }
        if entry.budgetText.isEmpty { return "spent this month" }
        return entry.overBudget
            ? "over the \(entry.budgetText) budget"
            : "of \(entry.budgetText) budget"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !entry.monthLabel.isEmpty {
                Text(entry.monthLabel.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            Text(entry.spentText ?? "Open Jeb")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 11, weight: entry.overBudget ? .semibold : .regular))
                .foregroundColor(entry.overBudget ? Self.overTextColor : .white.opacity(0.8))
                .lineLimit(1)
            if entry.spentText != nil && !entry.budgetText.isEmpty {
                Spacer().frame(height: 8)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.2))
                        Capsule()
                            .fill(entry.overBudget ? Self.overColor : Color.white)
                            .frame(width: geo.size.width * CGFloat(entry.progress) / 100)
                    }
                }
                .frame(height: 6)
                if !entry.dailyText.isEmpty {
                    Spacer().frame(height: 4)
                    Text(entry.dailyText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetBackground(
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.49, blue: 0.36),
                         Color(red: 0.12, green: 0.36, blue: 0.26)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

extension View {
    // iOS 17 requires containerBackground; earlier versions use a padded body
    // with a plain background.
    @ViewBuilder
    func widgetBackground(_ background: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) { background }
        } else {
            self.padding(16).background(background)
        }
    }
}

@main
struct JebWidget: Widget {
    // Must match HomeWidgetService.iosWidgetKind on the Flutter side.
    let kind: String = "JebWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JebProvider()) { entry in
            JebWidgetView(entry: entry)
        }
        .configurationDisplayName("This month")
        .description("This month's spending and budget at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
