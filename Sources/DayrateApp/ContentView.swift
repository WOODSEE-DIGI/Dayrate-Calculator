import SwiftUI
import DayrateCore

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var result: DayrateResult?
    @State private var prices: [CommodityPrice] = []
    @State private var currency: Currency = SharedSettings.shared.selectedCurrency
    @State private var exchangeRate: Double = 1.0
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let calculator = DayrateCalculator()
    private let inputFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f
    }()

    private var isLocalCurrency: Bool {
        currency.code != Currency.usd.code
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                inputSection
                currencySection
                commoditySection
                resultSection
                sarcasticFooter
            }
            .padding()
        }
        .frame(minWidth: 460, minHeight: 720)
        .task {
            await refreshData()
        }
        .onChange(of: inputText) {
            recalculate()
        }
        .onChange(of: prices) {
            recalculate()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Dayrate Calculator")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("What you'd charge if corporations let you.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What you're currently settling for")
                .font(.headline)
            HStack {
                TextField("800", text: $inputText)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        recalculate()
                    }
                Button("Refresh prices") {
                    Task { await refreshData() }
                }
                .disabled(isLoading)
            }
        }
    }

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick a currency to cry in")
                .font(.headline)
            Picker("Currency", selection: $currency) {
                ForEach(Currency.all) { currency in
                    Text("\(currency.flag) \(currency.name) (\(currency.code))")
                        .tag(currency)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: currency) {
                SharedSettings.shared.selectedCurrency = currency
                exchangeRate = SharedSettings.shared.exchangeRate(to: currency)
                recalculate()
            }
        }
    }

    private var commoditySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Things that went up while your pay didn't")
                .font(.headline)

            ForEach(prices) { price in
                CommodityRow(
                    price: price,
                    result: result,
                    currency: currency,
                    exchangeRate: exchangeRate
                )
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let result {
            VStack(spacing: 16) {
                Text("What you should be charging (in a just world)")
                    .font(.headline)

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(result.formattedInputDayrate(currency: currency, exchangeRate: exchangeRate))
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                        Text("What they pay you")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    VStack(spacing: 4) {
                        Text(result.formattedAdjustedDayrate(currency: currency, exchangeRate: exchangeRate))
                            .font(.title2.bold())
                            .foregroundStyle(.orange)
                        Text("What keeps pace with greed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(spacing: 4) {
                        Text(result.formattedRecommendedDayrate(currency: currency, exchangeRate: exchangeRate))
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                        Text("Round up and dream")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if isLocalCurrency {
                    Text("Raw: \(result.formattedAdjustedDayrate(currency: currency, exchangeRate: exchangeRate)) · \(result.formattedAdjustedDayrate())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("That's \(result.formattedMultiplier) your current rate. Your landlord will be thrilled.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .font(.caption)
        } else {
            Text("Enter your dayrate and refresh to see how much corporations think you don't deserve.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var sarcasticFooter: some View {
        VStack(spacing: 4) {
            Text(randomSarcasticLine())
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func randomSarcasticLine() -> String {
        let lines = [
            "Your rent went up. So did Brent. Your dayrate? Still 'market rate'.",
            "Corporations pass costs to you. You pass nothing to them. It's the circle of life.",
            "If only your clients priced your work like they price a barrel of oil.",
            "This number is theoretical, like your savings.",
            "Not financial advice. Just financial despair.",
            "Your skills didn't depreciate. The dollar just got selective.",
            "Send this to your client. What's the worst that could happen? (Don't actually.)",
            "Energy companies get to hedge. You get to hope."
        ]
        return lines.randomElement() ?? lines[0]
    }

    private func refreshData() async {
        isLoading = true
        errorMessage = nil

        async let commodityTask = CommodityService.shared.fetchEnabledPrices()
        async let currencyTask = CurrencyService.shared.fetchExchangeRates()

        switch await commodityTask {
        case .success(let fetched):
            prices = fetched
        case .failure(let error):
            errorMessage = error.description
            prices = SharedSettings.shared.lastPrices
        }

        _ = await currencyTask
        currency = SharedSettings.shared.selectedCurrency
        exchangeRate = SharedSettings.shared.exchangeRate(to: currency)

        recalculate()
        isLoading = false
    }

    private func recalculate() {
        guard let value = inputFormatter.number(from: inputText)?.doubleValue, value > 0 else {
            result = nil
            return
        }
        SharedSettings.shared.lastInputDayrate = value
        result = calculator.calculate(inputDayrate: value, commodityPrices: prices)
    }
}

// MARK: - Commodity row

struct CommodityRow: View {
    let price: CommodityPrice
    let result: DayrateResult?
    let currency: Currency
    let exchangeRate: Double

    private var impact: Double? {
        guard let result else { return nil }
        return result.isolatedImpact(commodityPrice: price, exchangeRate: exchangeRate)
    }

    private var hypothetical: Double? {
        guard let result else { return nil }
        return result.hypotheticalDayrate(only: price, exchangeRate: exchangeRate)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(price.multiplier >= 1 ? Color.green : Color.red)
                .frame(width: 4, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(price.commodity.name)
                    .font(.subheadline.bold())
                Text("\(price.formattedCurrentPrice) / \(price.formattedBaseline) \(price.commodity.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let hypothetical, let impact {
                    Text("If \(price.commodity.name) alone set your rate: \(DayrateResult.formatStatic(hypothetical, currency: currency)) (") +
                    Text(impact >= 0 ? "+" : "") +
                    Text("\(DayrateResult.formatStatic(abs(impact), currency: currency))")
                        .foregroundStyle(impact >= 0 ? .green : .red) +
                    Text(")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(price.formattedMultiplier) · \(price.formattedPercentChange)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(price.multiplier >= 1 ? .green : .red)
                Text(price.commodity.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension DayrateResult {
    static func formatStatic(_ value: Double, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.maximumFractionDigits = 0
        formatter.currencySymbol = currency.symbol
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency.symbol)\(Int(value))"
    }
}

#Preview {
    ContentView()
}
