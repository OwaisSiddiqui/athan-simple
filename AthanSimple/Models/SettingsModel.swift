import Foundation
import Combine
import Adhan

// MARK: - Settings Model
class SettingsModel: ObservableObject {
    @Published var calculationMethod: CalculationMethod = .northAmerica
    @Published var madhab: Madhab = .hanafi
    @Published var highLatitudeRule: HighLatitudeRule = .middleOfTheNight
    @Published var shafaq: Shafaq = .general
    @Published var fajrAdjustment: Int = 0
    @Published var sunriseAdjustment: Int = 0
    @Published var dhuhrAdjustment: Int = 0
    @Published var asrAdjustment: Int = 0
    @Published var maghribAdjustment: Int = 0
    @Published var ishaAdjustment: Int = 0
    @Published var rounding: Rounding = .nearest
    
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        // For now, just use default values
        // TODO: Implement proper UserDefaults loading once we know the correct enum types
    }
    
    func saveSettings() {
        // For now, just save the integer adjustments
        UserDefaults.standard.set(fajrAdjustment, forKey: "fajrAdjustment")
        UserDefaults.standard.set(sunriseAdjustment, forKey: "sunriseAdjustment")
        UserDefaults.standard.set(dhuhrAdjustment, forKey: "dhuhrAdjustment")
        UserDefaults.standard.set(asrAdjustment, forKey: "asrAdjustment")
        UserDefaults.standard.set(maghribAdjustment, forKey: "maghribAdjustment")
        UserDefaults.standard.set(ishaAdjustment, forKey: "ishaAdjustment")
    }
    
    // MARK: - Helper Methods
    func getCalculationParameters() -> CalculationParameters {
        var params = calculationMethod.params
        params.madhab = madhab
        params.highLatitudeRule = highLatitudeRule
        params.shafaq = shafaq
        params.rounding = rounding
        
        // Apply custom adjustments
        params.adjustments.fajr = fajrAdjustment
        params.adjustments.sunrise = sunriseAdjustment
        params.adjustments.dhuhr = dhuhrAdjustment
        params.adjustments.asr = asrAdjustment
        params.adjustments.maghrib = maghribAdjustment
        params.adjustments.isha = ishaAdjustment
        
        return params
    }
    
    func resetToDefaults() {
        calculationMethod = .moonsightingCommittee
        madhab = .hanafi
        highLatitudeRule = .middleOfTheNight
        shafaq = .general
        fajrAdjustment = 0
        sunriseAdjustment = 0
        dhuhrAdjustment = 0
        asrAdjustment = 0
        maghribAdjustment = 0
        ishaAdjustment = 0
        rounding = .nearest
        saveSettings()
    }
}

// MARK: - Display Names
extension CalculationMethod {
    var displayName: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian"
        case .karachi: return "Karachi"
        case .ummAlQura: return "Umm al-Qura"
        case .dubai: return "Dubai"
        case .qatar: return "Qatar"
        case .kuwait: return "Kuwait"
        case .moonsightingCommittee: return "Moonsighting Committee"
        case .singapore: return "Singapore"
        case .turkey: return "Turkey"
        case .tehran: return "Tehran"
        case .northAmerica: return "North America (ISNA)"
        case .other: return "Custom"
        }
    }
}

extension Madhab {
    var displayName: String {
        switch self {
        case .shafi: return "Shafi (Earlier Asr)"
        case .hanafi: return "Hanafi (Later Asr)"
        }
    }
}

extension HighLatitudeRule {
    var displayName: String {
        switch self {
        case .middleOfTheNight: return "Middle of the Night"
        case .seventhOfTheNight: return "Seventh of the Night"
        case .twilightAngle: return "Twilight Angle"
        }
    }
}

extension Shafaq {
    var displayName: String {
        switch self {
        case .general: return "General"
        case .ahmer: return "Ahmer (Red Twilight)"
        case .abyad: return "Abyad (White Twilight)"
        }
    }
}

extension Rounding {
    var displayName: String {
        switch self {
        case .nearest: return "Nearest Minute"
        case .up: return "Round Up"
        case .none: return "No Rounding"
        }
    }
}
