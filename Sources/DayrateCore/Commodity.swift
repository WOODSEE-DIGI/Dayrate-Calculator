import Foundation

/// A commodity whose price can influence the dayrate adjustment.
public struct Commodity: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let symbol: String
    public let name: String
    public let unit: String
    public let defaultBaseline: Double
    public let defaultEnabled: Bool
    public let yahooTicker: String

    public init(
        id: String,
        symbol: String,
        name: String,
        unit: String,
        defaultBaseline: Double,
        defaultEnabled: Bool,
        yahooTicker: String
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.unit = unit
        self.defaultBaseline = defaultBaseline
        self.defaultEnabled = defaultEnabled
        self.yahooTicker = yahooTicker
    }

    public static let brent = Commodity(
        id: "brent",
        symbol: "BZ",
        name: "Brent Crude Oil",
        unit: "USD/bbl",
        defaultBaseline: 78.0,
        defaultEnabled: true,
        yahooTicker: "BZ=F"
    )

    public static let wti = Commodity(
        id: "wti",
        symbol: "CL",
        name: "WTI Crude Oil",
        unit: "USD/bbl",
        defaultBaseline: 74.0,
        defaultEnabled: true,
        yahooTicker: "CL=F"
    )

    public static let naturalGas = Commodity(
        id: "naturalGas",
        symbol: "NG",
        name: "Natural Gas",
        unit: "USD/MMBtu",
        defaultBaseline: 2.80,
        defaultEnabled: false,
        yahooTicker: "NG=F"
    )

    public static let all: [Commodity] = [.brent, .wti, .naturalGas]
}
