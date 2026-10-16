import Foundation

public enum CommodityServiceError: Error, CustomStringConvertible {
    case invalidURL
    case network(Error)
    case decoding(String)
    case missingPrice(String)

    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL for commodity data."
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .decoding(let message):
            return "Failed to parse price data: \(message)"
        case .missingPrice(let ticker):
            return "Could not find a current price for \(ticker)."
        }
    }
}

/// Fetches commodity prices from Yahoo Finance.
/// This is a prototype data source. For production use, replace with a licensed commodity API.
public actor CommodityService {
    public static let shared = CommodityService()

    private let session: URLSession
    private let settings: SharedSettings

    public init(session: URLSession = .shared, settings: SharedSettings = .shared) {
        self.session = session
        self.settings = settings
    }

    public func fetchCurrentPrices() async -> Result<[CommodityPrice], CommodityServiceError> {
        var prices: [CommodityPrice] = []

        for commodity in Commodity.all {
            switch await fetchPrice(for: commodity) {
            case .success(let price):
                prices.append(price)
            case .failure(let error):
                return .failure(error)
            }
        }

        settings.lastPrices = prices
        return .success(prices)
    }

    public func fetchEnabledPrices() async -> Result<[CommodityPrice], CommodityServiceError> {
        var prices: [CommodityPrice] = []

        for commodity in settings.enabledCommodities {
            switch await fetchPrice(for: commodity) {
            case .success(let price):
                prices.append(price)
            case .failure(let error):
                return .failure(error)
            }
        }

        settings.lastPrices = prices
        return .success(prices)
    }

    private func fetchPrice(for commodity: Commodity) async -> Result<CommodityPrice, CommodityServiceError> {
        let encoded = commodity.yahooTicker.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? commodity.yahooTicker
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)"

        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }

        do {
            let (data, _) = try await session.data(from: url)
            let price = try parsePrice(from: data, commodity: commodity)
            return .success(price)
        } catch let error as CommodityServiceError {
            return .failure(error)
        } catch {
            return .failure(.network(error))
        }
    }

    private func parsePrice(from data: Data, commodity: Commodity) throws -> CommodityPrice {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let result = chart["result"] as? [[String: Any]],
              let first = result.first,
              let meta = first["meta"] as? [String: Any],
              let rawPrice = meta["regularMarketPrice"] as? Double ?? meta["previousClose"] as? Double else {
            throw CommodityServiceError.decoding("Unexpected response shape for \(commodity.yahooTicker)")
        }

        let baseline = settings.baseline(for: commodity)
        return CommodityPrice(
            commodity: commodity,
            currentPrice: rawPrice,
            baseline: baseline,
            fetchedAt: Date()
        )
    }
}
