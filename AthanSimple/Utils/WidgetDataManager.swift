import Foundation
import CoreLocation
import Adhan

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults: UserDefaults
    
    private init() {
        // Use App Group for sharing data between app and widget
        if let sharedDefaults = UserDefaults(suiteName: "group.com.siddiqui.AthanSimple") {
            self.userDefaults = sharedDefaults
        } else {
            // Fallback to standard UserDefaults if App Group is not available
            self.userDefaults = UserDefaults.standard
        }
    }
    
    func saveLocation(_ location: CLLocation) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: true)
            userDefaults.set(data, forKey: "lastKnownLocation")
            print("App: Successfully saved location to App Group")
            print("App: Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } catch {
            print("Failed to save location for widget: \(error)")
        }
    }
    
    func saveSettings(_ settings: SettingsModel) {
        let widgetSettings = WidgetSettings(
            calculationMethod: settings.calculationMethod.rawValue,
            madhab: settings.madhab.displayName,
            highLatitudeRule: settings.highLatitudeRule.displayName,
            shafaq: settings.shafaq.rawValue,
            fajrAdjustment: settings.fajrAdjustment,
            sunriseAdjustment: settings.sunriseAdjustment,
            dhuhrAdjustment: settings.dhuhrAdjustment,
            asrAdjustment: settings.asrAdjustment,
            maghribAdjustment: settings.maghribAdjustment,
            ishaAdjustment: settings.ishaAdjustment,
            rounding: settings.rounding.displayName
        )
        
        do {
            let data = try JSONEncoder().encode(widgetSettings)
            userDefaults.set(data, forKey: "widgetSettings")
        } catch {
            print("Failed to save settings for widget: \(error)")
        }
    }
    
    func savePrayerTimes(_ prayerTimes: PrayerTimes, currentPrayer: PrayerName?, nextPrayer: PrayerName?) {
        let prayerData = PrayerData(
            fajr: prayerTimes.fajr,
            sunrise: prayerTimes.sunrise,
            dhuhr: prayerTimes.dhuhr,
            asr: prayerTimes.asr,
            maghrib: prayerTimes.maghrib,
            isha: prayerTimes.isha,
            currentPrayer: currentPrayer?.rawValue,
            nextPrayer: nextPrayer?.rawValue,
            lastUpdated: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(prayerData)
            userDefaults.set(data, forKey: "widgetPrayerData")
            print("App: Successfully saved prayer data to App Group")
            print("App: Current prayer: \(currentPrayer?.rawValue ?? "nil")")
            print("App: Next prayer: \(nextPrayer?.rawValue ?? "nil")")
            print("App: Fajr time: \(prayerTimes.fajr)")
        } catch {
            print("Failed to save prayer data for widget: \(error)")
        }
    }
}

// MARK: - Widget Data Models
struct WidgetSettings: Codable {
    let calculationMethod: String
    let madhab: String
    let highLatitudeRule: String
    let shafaq: String
    let fajrAdjustment: Int
    let sunriseAdjustment: Int
    let dhuhrAdjustment: Int
    let asrAdjustment: Int
    let maghribAdjustment: Int
    let ishaAdjustment: Int
    let rounding: String
}

struct PrayerData: Codable {
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let currentPrayer: String?
    let nextPrayer: String?
    let lastUpdated: Date
}

