import Foundation

// MARK: - Prayer Utilities
class PrayerUtils {
    
    // MARK: - Time Conversion
    static func convertTimeToDate(_ timeStr: String, referenceDate: Date? = nil) -> Date {
        guard !timeStr.isEmpty else { 
            print("⚠️ Empty time string in convertTimeToDate")
            return Date() 
        }
        
        let components = timeStr.components(separatedBy: " ")
        guard components.count == 2 else { 
            print("⚠️ Invalid time format in convertTimeToDate: \(timeStr)")
            return Date() 
        }
        
        let time = components[0]
        let period = components[1]
        
        let timeComponents = time.components(separatedBy: ":")
        guard timeComponents.count == 2,
              let hours = Int(timeComponents[0]),
              let minutes = Int(timeComponents[1]) else { 
            print("⚠️ Invalid time components in convertTimeToDate: \(timeStr)")
            return Date() 
        }
        
        // Validate hours and minutes
        guard hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59 else {
            print("⚠️ Invalid time values in convertTimeToDate: \(timeStr)")
            return Date()
        }
        
        var date = referenceDate ?? Date()
        if !date.isValid {
            print("⚠️ Invalid reference date in convertTimeToDate")
            date = Date()
        }
        
        var adjustedHours = hours
        if period == "PM" && hours != 12 {
            adjustedHours += 12
        } else if period == "AM" && hours == 12 {
            adjustedHours = 0
        }
        
        // Validate adjusted hours
        guard adjustedHours >= 0 && adjustedHours <= 23 else {
            print("⚠️ Invalid adjusted hours in convertTimeToDate: \(adjustedHours)")
            return Date()
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        if let newDate = calendar.date(bySettingHour: adjustedHours, minute: minutes, second: 0, of: date) {
            guard newDate.isValid else {
                print("⚠️ Generated invalid date in convertTimeToDate")
                return Date()
            }
            return newDate
        } else {
            print("⚠️ Failed to create date in convertTimeToDate")
            return Date()
        }
    }
    
    // MARK: - Date Helpers
    static func getMonthDay(_ date: Date) -> (month: String, day: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: date)
        let day = String(Calendar.current.component(.day, from: date))
        return (month: month, day: day)
    }
    
    // MARK: - Prayer Data Lookup
    static func findTodayPrayers(_ data: [MonthData], month: String, day: String) -> PrayerTime? {
        guard let monthData = data.first(where: { $0.month.lowercased() == month.lowercased() }) else {
            return nil
        }
        
        return monthData.prayers.first(where: { $0.day == day })
    }
    
    // MARK: - Time Formatting
    static func formatTimeString(_ timeStr: String) -> String {
        return timeStr.hasPrefix("0") ? String(timeStr.dropFirst()) : timeStr
    }
    
    static func formatDateToTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let timeString = formatter.string(from: date)
        return timeString.hasPrefix("0") ? String(timeString.dropFirst()) : timeString
    }
    
    // MARK: - Time Difference Calculation
    static func getTimeDifferenceInMs(_ startTime: Date, _ endTime: Date) -> TimeInterval {
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: endTime)
        
        let startMs = (startComponents.hour ?? 0) * 3600 + (startComponents.minute ?? 0) * 60 + (startComponents.second ?? 0)
        let endMs = (endComponents.hour ?? 0) * 3600 + (endComponents.minute ?? 0) * 60 + (endComponents.second ?? 0)
        
        if endMs < startMs {
            return TimeInterval((endMs + 86400) - startMs)
        } else {
            return TimeInterval(endMs - startMs)
        }
    }
    
    // MARK: - Progress Calculation
    static func calculateProgressPercentage(_ currentTime: Date, _ currentPrayerTime: Date, _ nextPrayerTime: Date) -> Double {
        let elapsedTime = getTimeDifferenceInMs(currentPrayerTime, currentTime)
        let totalInterval = getTimeDifferenceInMs(currentPrayerTime, nextPrayerTime)
        
        let percentage = (elapsedTime / totalInterval) * 100
        return max(0, min(100, percentage))
    }
    
    // MARK: - Countdown Calculation
    static func getTimeRemaining(_ currentTime: Date, _ targetTime: Date) -> (hours: Int, minutes: Int)? {
        let diff = getTimeDifferenceInMs(currentTime, targetTime)
        if diff < 0 { return nil }
        
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        
        return (hours: hours, minutes: minutes)
    }
    
    // MARK: - Timeline Creation
    static func createTimeline(_ data: [MonthData]) -> [PrayerTimelineItem] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        let yesterdayDate = getMonthDay(yesterday)
        let todayDate = getMonthDay(today)
        let tomorrowDate = getMonthDay(tomorrow)
        
        let yesterdayPrayers = findTodayPrayers(data, month: yesterdayDate.month, day: yesterdayDate.day)
        let todayPrayers = findTodayPrayers(data, month: todayDate.month, day: todayDate.day)
        let tomorrowPrayers = findTodayPrayers(data, month: tomorrowDate.month, day: tomorrowDate.day)
        
        var timeline: [PrayerTimelineItem] = []
        
        if let yesterdayIsha = yesterdayPrayers?.isha {
            timeline.append(PrayerTimelineItem(
                name: .isha,
                date: convertTimeToDate(yesterdayIsha, referenceDate: yesterday),
                time: yesterdayIsha
            ))
        }
        
        if let todayPrayers = todayPrayers {
            timeline.append(PrayerTimelineItem(
                name: .fajr,
                date: convertTimeToDate(todayPrayers.fajr, referenceDate: today),
                time: todayPrayers.fajr
            ))
            timeline.append(PrayerTimelineItem(
                name: .sunrise,
                date: convertTimeToDate(todayPrayers.sunrise, referenceDate: today),
                time: todayPrayers.sunrise
            ))
            timeline.append(PrayerTimelineItem(
                name: .dhuhr,
                date: convertTimeToDate(todayPrayers.dhuhr, referenceDate: today),
                time: todayPrayers.dhuhr
            ))
            timeline.append(PrayerTimelineItem(
                name: .asr,
                date: convertTimeToDate(todayPrayers.asr, referenceDate: today),
                time: todayPrayers.asr
            ))
            timeline.append(PrayerTimelineItem(
                name: .maghrib,
                date: convertTimeToDate(todayPrayers.maghrib, referenceDate: today),
                time: todayPrayers.maghrib
            ))
            timeline.append(PrayerTimelineItem(
                name: .isha,
                date: convertTimeToDate(todayPrayers.isha, referenceDate: today),
                time: todayPrayers.isha
            ))
        }
        
        if let tomorrowFajr = tomorrowPrayers?.fajr {
            timeline.append(PrayerTimelineItem(
                name: .fajr,
                date: convertTimeToDate(tomorrowFajr, referenceDate: tomorrow),
                time: tomorrowFajr
            ))
        }
        
        return timeline
    }
}

