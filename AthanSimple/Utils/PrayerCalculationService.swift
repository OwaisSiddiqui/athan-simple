import Foundation
import CoreLocation
import Adhan
import Combine

class PrayerCalculationService: ObservableObject {
    @Published var prayerTimes: PrayerTimes?
    @Published var tomorrowPrayerTimes: PrayerTimes?
    @Published var currentPrayer: PrayerName?
    @Published var nextPrayer: PrayerName?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let settings: SettingsModel
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    init(settings: SettingsModel = SettingsModel()) {
        self.settings = settings
    }
    
    func calculatePrayerTimes(for coordinates: CLLocation, date: Date = Date()) {
        isLoading = true
        errorMessage = nil
        
        // Create coordinates for Adhan
        let adhanCoordinates = Coordinates(
            latitude: coordinates.coordinate.latitude,
            longitude: coordinates.coordinate.longitude
        )
        
        print("Adhan Coordinates", adhanCoordinates)
        
        // Create date components for today and tomorrow
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        let tomorrowDateComponents = calendar.dateComponents([.year, .month, .day], from: tomorrowDate)
        
        // Use user's calculation parameters
        var params = settings.getCalculationParameters()
        print(params.ishaAngle, params.fajrAngle)
        print(params.adjustments.dhuhr, params.adjustments.maghrib)
        params.adjustments.dhuhr = 1
        params.adjustments.maghrib = 1
        
        // Calculate today's prayer times
        if let prayers = PrayerTimes(
            coordinates: adhanCoordinates,
            date: dateComponents,
            calculationParameters: params
        ) {
            // Calculate tomorrow's prayer times for midnight crossing logic
            let tomorrowPrayers = PrayerTimes(
                coordinates: adhanCoordinates,
                date: tomorrowDateComponents,
                calculationParameters: params
            )
            
            DispatchQueue.main.async {
                self.prayerTimes = prayers
                self.tomorrowPrayerTimes = tomorrowPrayers
                
                // Use our custom midnight-crossing logic
                let currentTime = Date()
                guard currentTime.isValid else {
                    print("⚠️ Invalid current time in calculatePrayerTimes")
                    self.isLoading = false
                    return
                }
                
                self.currentPrayer = MidnightPrayerUtils.getCurrentPrayer(
                    currentTime: currentTime,
                    prayerTimes: prayers,
                    yesterdayPrayerTimes: nil as PrayerTimes? // We'll add this later if needed
                )
                self.nextPrayer = MidnightPrayerUtils.getNextPrayer(
                    currentTime: currentTime,
                    prayerTimes: prayers,
                    tomorrowPrayerTimes: tomorrowPrayers
                )
                self.isLoading = false
                
                // Save data for widget
                WidgetDataManager.shared.savePrayerTimes(prayers, currentPrayer: self.currentPrayer, nextPrayer: self.nextPrayer)
                WidgetDataManager.shared.saveSettings(self.settings)
                
                print("Prayer times calculated successfully")
                print("Current prayer: \(self.currentPrayer != nil ? self.getPrayerName(for: self.currentPrayer!) : "nil")")
                print("Next prayer: \(self.nextPrayer != nil ? self.getPrayerName(for: self.nextPrayer!) : "nil")")
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to calculate prayer times"
                self.isLoading = false
            }
        }
    }
    
    func getPrayerTimeString(for prayer: PrayerName) -> String {
        guard let prayerTimes = prayerTimes else { return "" }
        
        let prayerDate: Date
        switch prayer {
        case .fajr:
            prayerDate = prayerTimes.fajr
        case .sunrise:
            prayerDate = prayerTimes.sunrise
        case .dhuhr:
            prayerDate = prayerTimes.dhuhr
        case .asr:
            prayerDate = prayerTimes.asr
        case .maghrib:
            prayerDate = prayerTimes.maghrib
        case .isha:
            prayerDate = prayerTimes.isha
        }
        
        return dateFormatter.string(from: prayerDate)
    }
    
    func getPrayerName(for prayer: PrayerName) -> String {
        switch prayer {
        case .fajr:
            return "Fajr"
        case .sunrise:
            return "Sunrise"
        case .dhuhr:
            return "Dhuhr"
        case .asr:
            return "Asr"
        case .maghrib:
            return "Maghrib"
        case .isha:
            return "Isha"
        }
    }
    
    func getTimeUntilNextPrayer() -> TimeInterval? {
        guard let prayerTimes = prayerTimes else { return nil }
        
        let currentTime = Date()
        guard currentTime.isValid else {
            print("⚠️ Invalid current time in getTimeUntilNextPrayer")
            return nil
        }
        
        let timeInterval = MidnightPrayerUtils.getTimeUntilNextPrayer(
            currentTime: currentTime,
            prayerTimes: prayerTimes,
            tomorrowPrayerTimes: tomorrowPrayerTimes
        )
        
        // Ensure we return a valid positive time interval
        guard let interval = timeInterval, interval > 0 else {
            // If no valid time interval, try to calculate next prayer time directly
            if let nextPrayerTime = MidnightPrayerUtils.getNextPrayerTime(
                currentTime: currentTime,
                prayerTimes: prayerTimes,
                tomorrowPrayerTimes: tomorrowPrayerTimes
            ) {
                let calculatedInterval = nextPrayerTime.timeIntervalSince(currentTime)
                return calculatedInterval > 0 ? calculatedInterval : nil
            }
            return nil
        }
        
        return interval
    }
    
    func recalculatePrayerTimes(for coordinates: CLLocation) {
        calculatePrayerTimes(for: coordinates)
    }
    
    func updateCurrentAndNextPrayer() {
        guard let prayers = prayerTimes else { return }
        
        let currentTime = Date()
        guard currentTime.isValid else {
            print("⚠️ Invalid current time in updateCurrentAndNextPrayer")
            return
        }
        
        DispatchQueue.main.async {
            self.currentPrayer = MidnightPrayerUtils.getCurrentPrayer(
                currentTime: currentTime,
                prayerTimes: prayers,
                yesterdayPrayerTimes: nil as PrayerTimes?
            )
            self.nextPrayer = MidnightPrayerUtils.getNextPrayer(
                currentTime: currentTime,
                prayerTimes: prayers,
                tomorrowPrayerTimes: self.tomorrowPrayerTimes
            )
        }
    }
    
    func getProgressToNextPrayer() -> Double {
        guard let prayers = prayerTimes,
              let next = nextPrayer else {
            return 0.0
        }
        
        let now = Date()
        
        // Determine the start time for progress calculation
        let startTime: Date
        if let current = currentPrayer {
            // We have a current prayer, use its time as start
            let currentAdhanPrayer: Prayer
            switch current {
            case .fajr: currentAdhanPrayer = .fajr
            case .sunrise: currentAdhanPrayer = .sunrise
            case .dhuhr: currentAdhanPrayer = .dhuhr
            case .asr: currentAdhanPrayer = .asr
            case .maghrib: currentAdhanPrayer = .maghrib
            case .isha: currentAdhanPrayer = .isha
            }
            startTime = prayers.time(for: currentAdhanPrayer)
        } else {
            // No current prayer (e.g., after Isha), use Isha time as start
            startTime = prayers.isha
        }
        
        // Get next prayer time, handling midnight crossing
        let nextTime: Date
        if next == .fajr && now > prayers.isha {
            // Next prayer is tomorrow's Fajr
            nextTime = tomorrowPrayerTimes?.fajr ?? Calendar.current.date(byAdding: .day, value: 1, to: prayers.fajr) ?? prayers.fajr
        } else {
            // Convert PrayerName to Prayer for Adhan library
            let nextAdhanPrayer: Prayer
            switch next {
            case .fajr: nextAdhanPrayer = .fajr
            case .sunrise: nextAdhanPrayer = .sunrise
            case .dhuhr: nextAdhanPrayer = .dhuhr
            case .asr: nextAdhanPrayer = .asr
            case .maghrib: nextAdhanPrayer = .maghrib
            case .isha: nextAdhanPrayer = .isha
            }
            nextTime = prayers.time(for: nextAdhanPrayer)
        }
        
        let totalDuration = nextTime.timeIntervalSince(startTime)
        let elapsed = now.timeIntervalSince(startTime)
        
        guard totalDuration > 0 else { return 0.0 }
        
        let progress = elapsed / totalDuration
        return max(0.0, min(1.0, progress))
    }
    
}
