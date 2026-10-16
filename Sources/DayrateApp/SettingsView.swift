import SwiftUI
import DayrateCore

struct SettingsView: View {
    @State private var baselines: [Commodity: Double] = [:]
    @State private var enabled: [Commodity: Bool] = [:]
    @State private var currency: Currency = SharedSettings.shared.selectedCurrency

    var body: some View {
        Form {
            Section("Currency") {
                Picker("Local currency", selection: $currency) {
                    ForEach(Currency.all) { currency in
                        Text("\(currency.flag) \(currency.name) (\(currency.code))")
                            .tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: currency) {
                    SharedSettings.shared.selectedCurrency = currency
                }
            }

            Section("Energy commodities") {
                ForEach(Commodity.all) { commodity in
                    HStack {
                        Toggle(commodity.name, isOn: Binding(
                            get: { enabled[commodity] ?? commodity.defaultEnabled },
                            set: { newValue in
                                enabled[commodity] = newValue
                                SharedSettings.shared.setEnabled(newValue, for: commodity)
                            }
                        ))
                    }
                }
            }

            Section("Pre-war baselines") {
                ForEach(Commodity.all) { commodity in
                    HStack {
                        Text(commodity.name)
                        Spacer()
                        TextField("Baseline", value: Binding(
                            get: { baselines[commodity] ?? commodity.defaultBaseline },
                            set: { newValue in
                                baselines[commodity] = newValue
                                SharedSettings.shared.setBaseline(newValue, for: commodity)
                            }
                        ), format: .number)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        Text(commodity.unit)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Reset baselines to defaults") {
                    SharedSettings.shared.resetBaselines()
                    loadBaselines()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 560)
        .fixedSize()
        .onAppear {
            loadBaselines()
            loadEnabled()
            currency = SharedSettings.shared.selectedCurrency
        }
    }

    private func loadBaselines() {
        baselines = Dictionary(uniqueKeysWithValues: Commodity.all.map { ($0, SharedSettings.shared.baseline(for: $0)) })
    }

    private func loadEnabled() {
        enabled = Dictionary(uniqueKeysWithValues: Commodity.all.map { ($0, SharedSettings.shared.isEnabled($0)) })
    }
}

#Preview {
    SettingsView()
}
