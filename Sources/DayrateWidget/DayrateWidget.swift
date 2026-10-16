import WidgetKit
import SwiftUI
import DayrateCore

struct DayrateWidgetEntryView: View {
    var entry: DayrateProvider.Entry
    @Environment(\.widgetFamily) var family

    private var isLocalCurrency: Bool {
        entry.currency.code != Currency.usd.code
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge, .systemExtraLarge:
            largeView
        @unknown default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What you should charge")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let result = entry.result {
                Text(result.formattedRecommendedDayrate(currency: entry.currency, exchangeRate: entry.exchangeRate))
                    .font(.title2.bold())
                if isLocalCurrency {
                    Text(result.formattedRecommendedDayrate())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(result.formattedMultiplier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("--")
                    .font(.title2.bold())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What you should charge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let result = entry.result {
                    Text(result.formattedRecommendedDayrate(currency: entry.currency, exchangeRate: entry.exchangeRate))
                        .font(.title.bold())
                    if isLocalCurrency {
                        Text(result.formattedRecommendedDayrate())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(result.formattedMultiplier) of what they pay")
                        .font(.caption)
                } else {
                    Text("--")
                        .font(.title.bold())
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(entry.result?.commodityPrices ?? []) { price in
                    HStack(spacing: 4) {
                        Text(price.commodity.symbol)
                            .font(.caption.bold())
                        Text(price.formattedMultiplier)
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(price.multiplier >= 1 ? .green : .red)
                }
            }
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            mediumView
            Divider()
            Text("Open the app to update commodities, baselines, and currency — then weep.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct DayrateWidget: Widget {
    let kind: String = "DayrateWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: DayrateConfigurationIntent.self,
            provider: DayrateProvider()
        ) { entry in
            DayrateWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Energy Dayrate")
        .description("Shows what your dayrate should be if energy markets got a vote.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct DayrateWidgetBundle: WidgetBundle {
    var body: some Widget {
        DayrateWidget()
    }
}
