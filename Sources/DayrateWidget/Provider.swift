import WidgetKit
import SwiftUI
import AppIntents
import DayrateCore

struct DayrateEntry: TimelineEntry {
    let date: Date
    let result: DayrateResult?
    let currency: Currency
    let exchangeRate: Double
    let errorMessage: String?
}

struct DayrateProvider: AppIntentTimelineProvider {
    typealias Entry = DayrateEntry

    func placeholder(in context: Context) -> DayrateEntry {
        DayrateEntry(
            date: Date(),
            result: placeholderResult(),
            currency: .usd,
            exchangeRate: 1.0,
            errorMessage: nil
        )
    }

    func snapshot(for configuration: DayrateConfigurationIntent, in context: Context) async -> DayrateEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: DayrateConfigurationIntent, in context: Context) async -> Timeline<DayrateEntry> {
        let entry = await entry(for: configuration)
        // Refresh every 15 minutes. WidgetKit may throttle this.
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func entry(for configuration: DayrateConfigurationIntent) async -> DayrateEntry {
        let settings = SharedSettings.shared
        let inputDayrate = max(1, configuration.dayrate ?? settings.lastInputDayrate)
        let currency = settings.selectedCurrency

        let prices: [CommodityPrice]
        switch await CommodityService.shared.fetchEnabledPrices() {
        case .success(let fetched):
            prices = fetched
        case .failure:
            prices = settings.lastPrices
        }

        _ = await CurrencyService.shared.fetchExchangeRates()
        let exchangeRate = settings.exchangeRate(to: currency)

        let calculator = DayrateCalculator()
        let result = calculator.calculate(inputDayrate: inputDayrate, commodityPrices: prices)

        return DayrateEntry(
            date: Date(),
            result: result,
            currency: currency,
            exchangeRate: exchangeRate,
            errorMessage: nil
        )
    }

    private func placeholderResult() -> DayrateResult {
        DayrateResult(
            inputDayrateUSD: 800,
            adjustedDayrateUSD: 1024,
            overallMultiplier: 1.28,
            commodityPrices: [
                CommodityPrice(commodity: .brent, currentPrice: 85, baseline: 78, fetchedAt: Date())
            ],
            calculatedAt: Date()
        )
    }
}

struct DayrateConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Dayrate"
    static var description = IntentDescription("Your normal dayrate.")

    @Parameter(title: "Normal dayrate", default: 800)
    var dayrate: Double?
}
