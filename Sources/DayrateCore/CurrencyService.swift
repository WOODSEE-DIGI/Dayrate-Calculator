import Foundation

public enum CurrencyServiceError: Error, CustomStringConvertible {
    case invalidURL
    case network(Error)
    case decoding(String)
    case missingRate(String)

    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL for exchange-rate data."
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .decoding(let message):
            return "Failed to parse exchange-rate data: \(message)"
        case .missingRate(let currency):
            return "Could not find an exchange rate for \(currency)."
        }
    }
}

/// Fetches USD-based exchange rates from open.er-api.com.
/// Replace with a licensed FX API for production use.
public actor CurrencyService {
    public static let shared = CurrencyService()

    private let session: URLSession
    private let settings: SharedSettings

    public init(session: URLSession = .shared, settings: SharedSettings = .shared) {
        self.session = session
        self.settings = settings
    }

    public func fetchExchangeRates() async -> Result<[String: Double], CurrencyServiceError> {
        let urlString = "https://open.er-api.com/v6/latest/USD"

        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }

        do {
            let (data, _) = try await session.data(from: url)
            let rates = try parseRates(from: data)
            settings.exchangeRates = rates
            settings.exchangeRatesFetchedAt = Date()
            return .success(rates)
        } catch let error as CurrencyServiceError {
            return .failure(error)
        } catch {
            return .failure(.network(error))
        }
    }

    private func parseRates(from data: Data) throws -> [String: Double] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = json["rates"] as? [String: Double] else {
            throw CurrencyServiceError.decoding("Unexpected response shape")
        }
        return rates
    }
}
