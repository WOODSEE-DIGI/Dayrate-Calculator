import Foundation

/// A snapshot of a commodity's current price and the baseline it is compared against.
public struct CommodityPrice: Identifiable, Hashable, Codable, Sendable {
    public var id: String { commodity.id }
    public let commodity: Commodity
    public let currentPrice: Double
    public let baseline: Double
    public let fetchedAt: Date

    public init(commodity: Commodity, currentPrice: Double, baseline: Double, fetchedAt: Date) {
        self.commodity = commodity
        self.currentPrice = currentPrice
        self.baseline = baseline
        self.fetchedAt = fetchedAt
    }

    /// The ratio of current price to baseline. 1.0 means unchanged.
    public var multiplier: Double {
        guard baseline > 0 else { return 1.0 }
        return currentPrice / baseline
    }

    public var percentChange: Double {
        (multiplier - 1.0) * 100
    }

    public var formattedMultiplier: String {
        String(format: "%.2fx", multiplier)
    }

    public var formattedPercentChange: String {
        String(format: "%+.1f%%", percentChange)
    }

    public var formattedCurrentPrice: String {
        String(format: "%.2f", currentPrice)
    }

    public var formattedBaseline: String {
        String(format: "%.2f", baseline)
    }
}
