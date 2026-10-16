import Foundation

/// A fiat currency that the adjusted dayrate can be displayed in.
public struct Currency: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let code: String
    public let name: String
    public let symbol: String
    public let flag: String

    public init(code: String, name: String, symbol: String, flag: String) {
        self.id = code
        self.code = code
        self.name = name
        self.symbol = symbol
        self.flag = flag
    }

    public static let usd = Currency(code: "USD", name: "US Dollar", symbol: "$", flag: "🇺🇸")
    public static let eur = Currency(code: "EUR", name: "Euro", symbol: "€", flag: "🇪🇺")
    public static let gbp = Currency(code: "GBP", name: "British Pound", symbol: "£", flag: "🇬🇧")
    public static let aud = Currency(code: "AUD", name: "Australian Dollar", symbol: "A$", flag: "🇦🇺")
    public static let cad = Currency(code: "CAD", name: "Canadian Dollar", symbol: "C$", flag: "🇨🇦")
    public static let chf = Currency(code: "CHF", name: "Swiss Franc", symbol: "Fr", flag: "🇨🇭")
    public static let jpy = Currency(code: "JPY", name: "Japanese Yen", symbol: "¥", flag: "🇯🇵")
    public static let cny = Currency(code: "CNY", name: "Chinese Yuan", symbol: "¥", flag: "🇨🇳")
    public static let inr = Currency(code: "INR", name: "Indian Rupee", symbol: "₹", flag: "🇮🇳")
    public static let brl = Currency(code: "BRL", name: "Brazilian Real", symbol: "R$", flag: "🇧🇷")
    public static let zar = Currency(code: "ZAR", name: "South African Rand", symbol: "R", flag: "🇿🇦")
    public static let sek = Currency(code: "SEK", name: "Swedish Krona", symbol: "kr", flag: "🇸🇪")
    public static let nok = Currency(code: "NOK", name: "Norwegian Krone", symbol: "kr", flag: "🇳🇴")
    public static let dkk = Currency(code: "DKK", name: "Danish Krone", symbol: "kr", flag: "🇩🇰")
    public static let nzd = Currency(code: "NZD", name: "New Zealand Dollar", symbol: "NZ$", flag: "🇳🇿")
    public static let sgd = Currency(code: "SGD", name: "Singapore Dollar", symbol: "S$", flag: "🇸🇬")
    public static let mxn = Currency(code: "MXN", name: "Mexican Peso", symbol: "Mex$", flag: "🇲🇽")

    public static let all: [Currency] = [
        .usd, .eur, .gbp, .aud, .cad, .chf, .jpy, .cny, .inr, .brl,
        .zar, .sek, .nok, .dkk, .nzd, .sgd, .mxn
    ]

    public static func from(code: String) -> Currency {
        all.first { $0.code == code.uppercased() } ?? .usd
    }
}
