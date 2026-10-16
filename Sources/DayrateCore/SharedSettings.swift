import Foundation

/// Reads and writes settings shared between the main app and the widget via App Groups.
public final class SharedSettings: @unchecked Sendable {
    public static let appGroupIdentifier = "group.com.fusv.DayrateCalculator"
    public static let shared = SharedSettings()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let baselines = "commodityBaselines"
        static let enabledCommodities = "enabledCommodities"
        static let lastPrices = "lastPrices"
        static let lastInputDayrate = "lastInputDayrate"
        static let selectedCurrencyCode = "selectedCurrencyCode"
        static let exchangeRates = "exchangeRates"
        static let exchangeRatesFetchedAt = "exchangeRatesFetchedAt"
    }

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: SharedSettings.appGroupIdentifier) ?? .standard
    }

    // MARK: - Baselines

    public func baseline(for commodity: Commodity) -> Double {
        let baselines = defaults.dictionary(forKey: Keys.baselines) as? [String: Double]
        return baselines?[commodity.id] ?? commodity.defaultBaseline
    }

    public func setBaseline(_ value: Double, for commodity: Commodity) {
        var baselines = defaults.dictionary(forKey: Keys.baselines) as? [String: Double] ?? [:]
        baselines[commodity.id] = value
        defaults.set(baselines, forKey: Keys.baselines)
    }

    public func resetBaselines() {
        defaults.removeObject(forKey: Keys.baselines)
    }

    // MARK: - Enabled commodities

    public func isEnabled(_ commodity: Commodity) -> Bool {
        let enabled = defaults.stringArray(forKey: Keys.enabledCommodities)
        return enabled?.contains(commodity.id) ?? commodity.defaultEnabled
    }

    public func setEnabled(_ enabled: Bool, for commodity: Commodity) {
        var ids = defaults.stringArray(forKey: Keys.enabledCommodities) ?? Commodity.all
            .filter(\.defaultEnabled)
            .map(\.id)
        if enabled {
            ids.append(commodity.id)
        } else {
            ids.removeAll { $0 == commodity.id }
        }
        defaults.set(Array(Set(ids)), forKey: Keys.enabledCommodities)
    }

    public var enabledCommodities: [Commodity] {
        Commodity.all.filter(isEnabled)
    }

    // MARK: - Cached prices

    public var lastPrices: [CommodityPrice] {
        get {
            guard let data = defaults.data(forKey: Keys.lastPrices) else { return [] }
            return (try? decoder.decode([CommodityPrice].self, from: data)) ?? []
        }
        set {
            guard let data = try? encoder.encode(newValue) else { return }
            defaults.set(data, forKey: Keys.lastPrices)
        }
    }

    public var lastInputDayrate: Double {
        get { defaults.double(forKey: Keys.lastInputDayrate) }
        set { defaults.set(newValue, forKey: Keys.lastInputDayrate) }
    }

    // MARK: - Currency

    public var selectedCurrency: Currency {
        get {
            let code = defaults.string(forKey: Keys.selectedCurrencyCode) ?? Currency.usd.code
            return Currency.from(code: code)
        }
        set {
            defaults.set(newValue.code, forKey: Keys.selectedCurrencyCode)
        }
    }

    public var exchangeRates: [String: Double] {
        get { defaults.dictionary(forKey: Keys.exchangeRates) as? [String: Double] ?? [:] }
        set { defaults.set(newValue, forKey: Keys.exchangeRates) }
    }

    public var exchangeRatesFetchedAt: Date? {
        get { defaults.object(forKey: Keys.exchangeRatesFetchedAt) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.exchangeRatesFetchedAt)
            } else {
                defaults.removeObject(forKey: Keys.exchangeRatesFetchedAt)
            }
        }
    }

    public func exchangeRate(to currency: Currency) -> Double {
        guard currency.code != Currency.usd.code else { return 1.0 }
        return exchangeRates[currency.code] ?? 1.0
    }
}
