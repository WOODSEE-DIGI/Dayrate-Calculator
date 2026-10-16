import Foundation

/// The outcome of running the dayrate adjustment. All monetary values are stored in USD.
public struct DayrateResult: Hashable, Codable, Sendable {
    public let inputDayrateUSD: Double
    public let adjustedDayrateUSD: Double
    public let overallMultiplier: Double
    public let commodityPrices: [CommodityPrice]
    public let calculatedAt: Date

    public init(
        inputDayrateUSD: Double,
        adjustedDayrateUSD: Double,
        overallMultiplier: Double,
        commodityPrices: [CommodityPrice],
        calculatedAt: Date
    ) {
        self.inputDayrateUSD = inputDayrateUSD
        self.adjustedDayrateUSD = adjustedDayrateUSD
        self.overallMultiplier = overallMultiplier
        self.commodityPrices = commodityPrices
        self.calculatedAt = calculatedAt
    }

    /// Converts the USD-adjusted dayrate to a local currency.
    public func adjustedDayrate(in currency: Currency, exchangeRate: Double) -> Double {
        guard currency.code != Currency.usd.code else { return adjustedDayrateUSD }
        return adjustedDayrateUSD * exchangeRate
    }

    public func formattedInputDayrate(currency: Currency = .usd, exchangeRate: Double = 1.0) -> String {
        let value = currency.code == Currency.usd.code ? inputDayrateUSD : inputDayrateUSD * exchangeRate
        return Self.format(value, currency: currency)
    }

    public func formattedAdjustedDayrate(currency: Currency = .usd, exchangeRate: Double = 1.0) -> String {
        Self.format(adjustedDayrateUSD * exchangeRate, currency: currency)
    }

    public var formattedMultiplier: String {
        String(format: "%.2fx", overallMultiplier)
    }

    /// A "client-friendly" rounded version of the adjusted dayrate.
    /// Rounds to a sensible billing increment based on magnitude.
    public var recommendedDayrateUSD: Double {
        DayrateResult.roundForBilling(adjustedDayrateUSD)
    }

    public func recommendedDayrate(in currency: Currency, exchangeRate: Double) -> Double {
        guard currency.code != Currency.usd.code else { return recommendedDayrateUSD }
        return DayrateResult.roundForBilling(adjustedDayrateUSD * exchangeRate)
    }

    public func formattedRecommendedDayrate(currency: Currency = .usd, exchangeRate: Double = 1.0) -> String {
        Self.format(recommendedDayrate(in: currency, exchangeRate: exchangeRate), currency: currency)
    }

    /// What the dayrate would be if only this commodity's price change applied.
    public func hypotheticalDayrateUSD(only commodityPrice: CommodityPrice) -> Double {
        inputDayrateUSD * commodityPrice.multiplier
    }

    public func hypotheticalDayrate(only commodityPrice: CommodityPrice, exchangeRate: Double) -> Double {
        hypotheticalDayrateUSD(only: commodityPrice) * exchangeRate
    }

    /// The isolated dollar impact of a single commodity's price change.
    public func isolatedImpactUSD(commodityPrice: CommodityPrice) -> Double {
        inputDayrateUSD * (commodityPrice.multiplier - 1.0)
    }

    public func isolatedImpact(commodityPrice: CommodityPrice, exchangeRate: Double) -> Double {
        isolatedImpactUSD(commodityPrice: commodityPrice) * exchangeRate
    }

    /// Rounds a dayrate to a clean billing number.
    public static func roundForBilling(_ value: Double) -> Double {
        let increment: Double
        switch value {
        case ..<100:    increment = 25
        case ..<500:   increment = 50
        case ..<1000:  increment = 100
        case ..<5000:  increment = 250
        case ..<10000: increment = 500
        default:        increment = 1000
        }
        return max(increment, (value / increment).rounded() * increment)
    }

    private static func format(_ value: Double, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.maximumFractionDigits = 0
        formatter.currencySymbol = currency.symbol
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency.symbol)\(Int(value))"
    }
}

/// Calculates an adjusted dayrate from current commodity prices and a baseline.
public struct DayrateCalculator: Sendable {
    public init() {}

    /// Adjusts the input dayrate by the geometric mean of each enabled commodity's price ratio.
    /// Using the geometric mean keeps the math sane when mixing commodities with very different prices.
    public func calculate(
        inputDayrate: Double,
        commodityPrices: [CommodityPrice]
    ) -> DayrateResult? {
        guard inputDayrate > 0 else { return nil }
        let active = commodityPrices.filter { $0.baseline > 0 && $0.currentPrice > 0 }
        guard !active.isEmpty else { return nil }

        let logSum = active.reduce(0.0) { sum, price in
            sum + log(price.multiplier)
        }
        let overallMultiplier = exp(logSum / Double(active.count))
        let adjustedDayrate = inputDayrate * overallMultiplier

        return DayrateResult(
            inputDayrateUSD: inputDayrate,
            adjustedDayrateUSD: adjustedDayrate,
            overallMultiplier: overallMultiplier,
            commodityPrices: active,
            calculatedAt: Date()
        )
    }
}
