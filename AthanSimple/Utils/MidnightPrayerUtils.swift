import Foundation
import Adhan

// MARK: - Date Extension for Safety
extension Date {
    var isValid: Bool {
        // More comprehensive validation
        let timeInterval = self.timeIntervalSince1970
        return timeInterval.isFinite && 
               !timeInterval.isNaN && 
               timeInterval > -2208988800 && // Before 1900
               timeInterval < 4102444800 // Before 2100
    }
}

// MARK: - Midnight Prayer Utilities
// Inspired by Islamic Prayer Times Chrome Extension logic
class MidnightPrayerUtils {
    
    // MARK: - Time Conversion Helpers
    
    /// Convert a Date to total minutes since midnight
    static func getTotalMinutes(from date: Date) -> Int {
        guard date.isValid else { 
            print("⚠️ Invalid date in getTotalMinutes: \(date)")
            return 0 
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        return hours * 60 + minutes
    }
    
    /// Convert time string (e.g., "5:30 AM") to total minutes since midnight
    static func getTotalMinutes(from timeString: String) -> Int {
        let date = PrayerUtils.convertTimeToDate(timeString)
        guard date.isValid else { return 0 }
        return getTotalMinutes(from: date)
    }
    
    // MARK: - Time Comparison Logic
    
    /// Check if current time is between two prayer times, handling midnight crossing
    /// - Parameters:
    ///   - currentTime: Current time as Date
    ///   - startTime: Start prayer time as Date
    ///   - endTime: End prayer time as Date
    /// - Returns: True if current time is between start and end times
    static func isTimeBetweenTheTwo(currentTime: Date, startTime: Date, endTime: Date) -> Bool {
        guard currentTime.isValid && startTime.isValid && endTime.isValid else { return false }
        
        let current = getTotalMinutes(from: currentTime)
        let start = getTotalMinutes(from: startTime)
        let end = getTotalMinutes(from: endTime)
        
        if end > start {
            // Normal case: end time is after start time (same day)
            return current >= start && current < end
        } else {
            // Special case: prayer spans midnight (e.g., Isha to Fajr)
            // Current time is between start and end if it's after start OR before end
            return current >= start || current < end
        }
    }
    
    // MARK: - Time Difference Calculation
    
    /// Calculate minutes between two times, handling midnight crossing
    /// - Parameters:
    ///   - startTime: Start time as Date
    ///   - endTime: End time as Date
    /// - Returns: Minutes between the two times
    static func diffMinutesBetweenTimes(startTime: Date, endTime: Date) -> Int {
        guard startTime.isValid && endTime.isValid else { return 0 }
        
        let start = getTotalMinutes(from: startTime)
        let end = getTotalMinutes(from: endTime)
        
        if start > end {
            // Handle midnight crossing
            return 1440 - (start - end) // 1440 minutes = 24 hours
        } else {
            return end - start
        }
    }
    
    /// Calculate time difference between two times and return formatted string
    /// - Parameters:
    ///   - startTime: Start time as Date
    ///   - endTime: End time as Date
    /// - Returns: Formatted time difference string (e.g., "2:30")
    static func diffBetweenTimes(startTime: Date, endTime: Date) -> String {
        let diffMinutes = diffMinutesBetweenTimes(startTime: startTime, endTime: endTime)
        let hours = diffMinutes / 60
        let minutes = diffMinutes % 60
        
        return String(format: "%d:%02d", hours, minutes)
    }
    
    // MARK: - Prayer Time Logic
    
    /// Get the next prayer considering midnight crossing
    /// - Parameters:
    ///   - currentTime: Current time
    ///   - prayerTimes: Today's prayer times
    ///   - tomorrowPrayerTimes: Tomorrow's prayer times (optional)
    /// - Returns: Next prayer name, or nil if no prayer times available
    static func getNextPrayer(
        currentTime: Date = Date(),
        prayerTimes: PrayerTimes,
        tomorrowPrayerTimes: PrayerTimes? = nil
    ) -> PrayerName? {
        
        guard currentTime.isValid else { return nil }
        
        // Check if we're past today's Isha (last prayer of the day)
        if currentTime > prayerTimes.isha {
            return .fajr
        }
        
        // Check prayers in order for today
        let prayers: [(PrayerName, Date)] = [
            (.fajr, prayerTimes.fajr),
            (.sunrise, prayerTimes.sunrise),
            (.dhuhr, prayerTimes.dhuhr),
            (.asr, prayerTimes.asr),
            (.maghrib, prayerTimes.maghrib),
            (.isha, prayerTimes.isha)
        ]
        
        for (prayer, prayerTime) in prayers {
            if currentTime < prayerTime {
                return prayer
            }
        }
        
        // If we've passed all today's prayers, return tomorrow's Fajr
        return .fajr
    }
    
    /// Get the next prayer time considering midnight crossing
    /// - Parameters:
    ///   - currentTime: Current time
    ///   - prayerTimes: Today's prayer times
    ///   - tomorrowPrayerTimes: Tomorrow's prayer times (optional)
    /// - Returns: Next prayer time as Date
    static func getNextPrayerTime(
        currentTime: Date = Date(),
        prayerTimes: PrayerTimes,
        tomorrowPrayerTimes: PrayerTimes? = nil
    ) -> Date? {
        
        guard currentTime.isValid else { return nil }
        
        guard let nextPrayer = getNextPrayer(
            currentTime: currentTime,
            prayerTimes: prayerTimes,
            tomorrowPrayerTimes: tomorrowPrayerTimes
        ) else { return nil }
        
        // If next prayer is Fajr and we're past today's Isha, return tomorrow's Fajr
        if nextPrayer == .fajr && currentTime > prayerTimes.isha {
            if let tomorrowPrayers = tomorrowPrayerTimes {
                return tomorrowPrayers.fajr
            } else {
                // Calculate tomorrow's Fajr by adding 24 hours
                return Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.fajr)
            }
        }
        
        // Convert PrayerName to Prayer for Adhan library
        let adhanPrayer: Prayer
        switch nextPrayer {
        case .fajr: adhanPrayer = .fajr
        case .sunrise: adhanPrayer = .sunrise
        case .dhuhr: adhanPrayer = .dhuhr
        case .asr: adhanPrayer = .asr
        case .maghrib: adhanPrayer = .maghrib
        case .isha: adhanPrayer = .isha
        }
        return prayerTimes.time(for: adhanPrayer)
    }
    
    /// Calculate time remaining until next prayer, handling midnight crossing
    /// - Parameters:
    ///   - currentTime: Current time
    ///   - prayerTimes: Today's prayer times
    ///   - tomorrowPrayerTimes: Tomorrow's prayer times (optional)
    /// - Returns: Time interval until next prayer, or nil if no next prayer
    static func getTimeUntilNextPrayer(
        currentTime: Date = Date(),
        prayerTimes: PrayerTimes,
        tomorrowPrayerTimes: PrayerTimes? = nil
    ) -> TimeInterval? {
        
        guard currentTime.isValid else { return nil }
        
        guard let nextPrayerTime = getNextPrayerTime(
            currentTime: currentTime,
            prayerTimes: prayerTimes,
            tomorrowPrayerTimes: tomorrowPrayerTimes
        ) else { return nil }
        
        let timeInterval = nextPrayerTime.timeIntervalSince(currentTime)
        return timeInterval > 0 ? timeInterval : nil
    }
    
    /// Get current prayer considering midnight crossing
    /// - Parameters:
    ///   - currentTime: Current time
    ///   - prayerTimes: Today's prayer times
    ///   - yesterdayPrayerTimes: Yesterday's prayer times (optional)
    /// - Returns: Current prayer name, or nil if no current prayer
    static func getCurrentPrayer(
        currentTime: Date = Date(),
        prayerTimes: PrayerTimes,
        yesterdayPrayerTimes: PrayerTimes? = nil
    ) -> PrayerName? {
        
        guard currentTime.isValid else { return nil }
        
        // Check if we're in the period after yesterday's Isha and before today's Fajr
        if let yesterdayPrayers = yesterdayPrayerTimes {
            if isTimeBetweenTheTwo(
                currentTime: currentTime,
                startTime: yesterdayPrayers.isha,
                endTime: prayerTimes.fajr
            ) {
                return .isha // We're still in yesterday's Isha period
            }
        }
        
        // Check if we're after today's Isha (should return nil for current prayer)
        if currentTime > prayerTimes.isha {
            return nil
        }
        
        // Check today's prayers in reverse order
        let prayers: [(PrayerName, Date)] = [
            (.isha, prayerTimes.isha),
            (.maghrib, prayerTimes.maghrib),
            (.asr, prayerTimes.asr),
            (.dhuhr, prayerTimes.dhuhr),
            (.sunrise, prayerTimes.sunrise),
            (.fajr, prayerTimes.fajr)
        ]
        
        for (prayer, prayerTime) in prayers {
            if currentTime >= prayerTime {
                return prayer
            }
        }
        
        return nil
    }
}
