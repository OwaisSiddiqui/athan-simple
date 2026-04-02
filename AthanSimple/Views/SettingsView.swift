import SwiftUI
import Adhan

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Calculation Method Section
                Section("Calculation Method") {
                    Picker("Method", selection: $settings.calculationMethod) {
                        ForEach(CalculationMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Madhab Section
                Section("Madhab") {
                    Picker("Madhab", selection: $settings.madhab) {
                        ForEach(Madhab.allCases, id: \.self) { madhab in
                            Text(madhab.displayName).tag(madhab)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // High Latitude Rule Section
                Section("High Latitude Rule") {
                    Picker("Rule", selection: $settings.highLatitudeRule) {
                        ForEach(HighLatitudeRule.allCases, id: \.self) { rule in
                            Text(rule.displayName).tag(rule)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Shafaq Section (only for Moonsighting Committee)
                if settings.calculationMethod == .moonsightingCommittee {
                    Section("Shafaq (Twilight Type)") {
                        Picker("Shafaq", selection: $settings.shafaq) {
                            ForEach(Shafaq.allCases, id: \.self) { shafaq in
                                Text(shafaq.displayName).tag(shafaq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // Prayer Adjustments Section
                Section("Prayer Time Adjustments (Minutes)") {
                    AdjustmentRow(title: "Fajr", value: $settings.fajrAdjustment)
                    AdjustmentRow(title: "Sunrise", value: $settings.sunriseAdjustment)
                    AdjustmentRow(title: "Dhuhr", value: $settings.dhuhrAdjustment)
                    AdjustmentRow(title: "Asr", value: $settings.asrAdjustment)
                    AdjustmentRow(title: "Maghrib", value: $settings.maghribAdjustment)
                    AdjustmentRow(title: "Isha", value: $settings.ishaAdjustment)
                }
                
                // Rounding Section
                Section("Time Rounding") {
                    Picker("Rounding", selection: $settings.rounding) {
                        ForEach(Rounding.allCases, id: \.self) { rounding in
                            Text(rounding.displayName).tag(rounding)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Reset Section
                Section {
                    Button("Reset to Defaults") {
                        settings.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        settings.saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        settings.saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                #endif
            }
        }
    }
}

// MARK: - Adjustment Row Component
struct AdjustmentRow: View {
    let title: String
    @Binding var value: Int
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Stepper(value: $value, in: -60...60) {
                Text("\(value >= 0 ? "+" : "")\(value) min")
                    .frame(width: 60, alignment: .trailing)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView(settings: SettingsModel())
}
