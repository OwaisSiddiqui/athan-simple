//
//  AthanSimpleWidget.swift
//  AthanSimpleWidget
//
//  Created by Owais Siddiqui on 2025-10-08.
//

import WidgetKit
import SwiftUI
import CoreLocation
import Adhan

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        return PrayerEntry(
            date: Date(),
            currentPrayer: "Fajr",
            currentPrayerTime: "5:30 AM",
            nextPrayer: "Dhuhr",
            nextPrayerTime: "12:15 PM",
            timeRemaining: "3h 45m",
            progress: 0.5,
            isLoading: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> ()) {
        let entry = PrayerEntry(
            date: Date(),
            currentPrayer: "Fajr",
            currentPrayerTime: "5:30 AM",
            nextPrayer: "Dhuhr",
            nextPrayerTime: "12:15 PM",
            timeRemaining: "3h 45m",
            progress: 0.5,
            isLoading: false
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> ()) {
        let currentDate = Date()
        var entries: [PrayerEntry] = []
        
        // First try to get cached prayer data
        if let prayerData = getCachedPrayerData() {
            let entry = createPrayerEntryFromCachedData(prayerData, date: currentDate)
            entries.append(entry)
            
            // Create entries for next 24 hours, updating every minute
            createMinuteTimelineEntries(entries: &entries, prayerData: prayerData, startDate: currentDate)
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
            return
        }
        
        // Fallback: Get location and calculate prayer times using Adhan directly
        let sharedDefaults = UserDefaults(suiteName: "group.com.siddiqui.AthanSimple") ?? UserDefaults.standard
        let locationData = sharedDefaults.data(forKey: "lastKnownLocation")
        
        var currentLocation: CLLocation?
        
        if let locationData = locationData,
           let location = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: locationData) {
            currentLocation = location
        }
        
        if let location = currentLocation {
            // Calculate prayer times using Adhan directly
            let coordinates = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            var params = CalculationMethod.muslimWorldLeague.params
            params.madhab = .hanafi
            params.highLatitudeRule = .middleOfTheNight
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
            guard let prayerTimes = PrayerTimes(coordinates: coordinates, date: dateComponents, calculationParameters: params) else {
                let entry = PrayerEntry(
                    date: currentDate,
                    currentPrayer: "Error",
                    currentPrayerTime: "",
                    nextPrayer: "Open App",
                    nextPrayerTime: "",
                    timeRemaining: "Error",
                    progress: 0.0,
                    isLoading: false
                )
                entries.append(entry)
                let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate))
                completion(timeline)
                return
            }
            
            let entry = createPrayerEntryFromAdhan(prayerTimes, date: currentDate)
            entries.append(entry)
            
            // Create entries for next 24 hours, updating every minute
            createMinuteTimelineEntriesForAdhan(entries: &entries, prayerTimes: prayerTimes, coordinates: coordinates, params: params, startDate: currentDate)
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        } else {
            // No location available
            let entry = PrayerEntry(
                date: currentDate,
                currentPrayer: "Location Required",
                currentPrayerTime: "",
                nextPrayer: "Open App",
                nextPrayerTime: "",
                timeRemaining: "Tap to set location",
                progress: 0.0,
                isLoading: false
            )
            entries.append(entry)
            
            let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate))
            completion(timeline)
        }
    }
    
    private func createPrayerEntryFromAdhan(_ prayerTimes: PrayerTimes, date: Date) -> PrayerEntry {
        let currentTime = date
        let calendar = Calendar.current
        
        // Determine current and next prayer based on Adhan prayer times
        let prayers: [(String, Date)] = [
            ("Fajr", prayerTimes.fajr),
            ("Sunrise", prayerTimes.sunrise),
            ("Dhuhr", prayerTimes.dhuhr),
            ("Asr", prayerTimes.asr),
            ("Maghrib", prayerTimes.maghrib),
            ("Isha", prayerTimes.isha)
        ]
        
        var currentPrayer = "No Current Prayer"
        var currentPrayerTime = ""
        var nextPrayer = "No Next Prayer"
        var nextPrayerTime = ""
        
        // Find current prayer
        for i in 0..<prayers.count {
            let (name, time) = prayers[i]
            if currentTime >= time {
                currentPrayer = name
                currentPrayerTime = formatTime(time)
            }
        }
        
        // Find next prayer
        for i in 0..<prayers.count {
            let (name, time) = prayers[i]
            if currentTime < time {
                nextPrayer = name
                nextPrayerTime = formatTime(time)
                break
            }
        }
        
        // If no next prayer found, it's tomorrow's Fajr
        if nextPrayer == "No Next Prayer" {
            nextPrayer = "Fajr"
            let tomorrowFajr = calendar.date(byAdding: .day, value: 1, to: prayerTimes.fajr) ?? prayerTimes.fajr
            nextPrayerTime = formatTime(tomorrowFajr)
        }
        
        // Calculate time remaining and progress like main app
        let nextPrayerTimeDate = prayers.first { currentTime < $0.1 }?.1 ?? calendar.date(byAdding: .day, value: 1, to: prayerTimes.fajr) ?? prayerTimes.fajr
        let timeRemaining = nextPrayerTimeDate.timeIntervalSince(currentTime)
        let timeRemainingText = formatTimeRemaining(timeRemaining)
        let progress = calculateProgressFromAdhan(prayerTimes: prayerTimes, currentTime: currentTime, nextPrayerTime: nextPrayerTimeDate)
        
        return PrayerEntry(
            date: date,
            currentPrayer: currentPrayer,
            currentPrayerTime: currentPrayerTime,
            nextPrayer: nextPrayer,
            nextPrayerTime: nextPrayerTime,
            timeRemaining: timeRemainingText,
            progress: progress,
            isLoading: false
        )
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func calculateProgressFromAdhan(prayerTimes: PrayerTimes, currentTime: Date, nextPrayerTime: Date) -> Double {
        // Copy exact logic from main app's getProgressToNextPrayer()
        let now = currentTime
        
        // Determine the start time for progress calculation
        let startTime: Date
        let prayers: [(String, Date)] = [
            ("Fajr", prayerTimes.fajr),
            ("Sunrise", prayerTimes.sunrise),
            ("Dhuhr", prayerTimes.dhuhr),
            ("Asr", prayerTimes.asr),
            ("Maghrib", prayerTimes.maghrib),
            ("Isha", prayerTimes.isha)
        ]
        
        // Find current prayer to determine start time
        var currentPrayerTime: Date?
        for i in 0..<prayers.count {
            let (_, time) = prayers[i]
            if currentTime >= time {
                currentPrayerTime = time
            }
        }
        
        if let current = currentPrayerTime {
            startTime = current
        } else {
            // No current prayer (e.g., after Isha), use Isha time as start
            startTime = prayerTimes.isha
        }
        
        let totalDuration = nextPrayerTime.timeIntervalSince(startTime)
        let elapsed = now.timeIntervalSince(startTime)
        
        guard totalDuration > 0 else { return 0.0 }
        
        let progress = elapsed / totalDuration
        return max(0.0, min(1.0, progress))
    }
    
    private func calculateProgressFromCachedData(prayerData: PrayerData, currentTime: Date, nextPrayerTime: Date) -> Double {
        // Copy exact logic from main app's getProgressToNextPrayer()
        let now = currentTime
        
        // Determine the start time for progress calculation
        let startTime: Date
        let prayers: [(String, Date)] = [
            ("Fajr", prayerData.fajr),
            ("Sunrise", prayerData.sunrise),
            ("Dhuhr", prayerData.dhuhr),
            ("Asr", prayerData.asr),
            ("Maghrib", prayerData.maghrib),
            ("Isha", prayerData.isha)
        ]
        
        // Find current prayer to determine start time
        var currentPrayerTime: Date?
        for i in 0..<prayers.count {
            let (_, time) = prayers[i]
            if currentTime >= time {
                currentPrayerTime = time
            }
        }
        
        if let current = currentPrayerTime {
            startTime = current
        } else {
            // No current prayer (e.g., after Isha), use Isha time as start
            startTime = prayerData.isha
        }
        
        let totalDuration = nextPrayerTime.timeIntervalSince(startTime)
        let elapsed = now.timeIntervalSince(startTime)
        
        guard totalDuration > 0 else { return 0.0 }
        
        let progress = elapsed / totalDuration
        return max(0.0, min(1.0, progress))
    }
    
    private func getCachedPrayerData() -> PrayerData? {
        let sharedDefaults = UserDefaults(suiteName: "group.com.siddiqui.AthanSimple") ?? UserDefaults.standard
        
        // Debug: Check if we can access the App Group
        print("Widget: Attempting to read from App Group: group.com.siddiqui.AthanSimple")
        print("Widget: Shared defaults available: \(sharedDefaults != UserDefaults.standard)")
        
        guard let data = sharedDefaults.data(forKey: "widgetPrayerData") else {
            print("Widget: No prayer data found in App Group")
            return nil
        }
        
        guard let prayerData = try? JSONDecoder().decode(PrayerData.self, from: data) else {
            print("Widget: Failed to decode prayer data")
            return nil
        }
        
        print("Widget: Successfully loaded prayer data, last updated: \(prayerData.lastUpdated)")
        
        // Check if data is recent (within last hour)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let isRecent = prayerData.lastUpdated > oneHourAgo
        print("Widget: Data is recent: \(isRecent)")
        
        return isRecent ? prayerData : nil
    }
    
    private func createPrayerEntryFromCachedData(_ prayerData: PrayerData, date: Date) -> PrayerEntry {
        let currentTime = date
        let calendar = Calendar.current
        
        // Determine current and next prayer based on cached data
        let prayers: [(String, Date)] = [
            ("Fajr", prayerData.fajr),
            ("Sunrise", prayerData.sunrise),
            ("Dhuhr", prayerData.dhuhr),
            ("Asr", prayerData.asr),
            ("Maghrib", prayerData.maghrib),
            ("Isha", prayerData.isha)
        ]
        
        var currentPrayer = "No Current Prayer"
        var currentPrayerTime = ""
        var nextPrayer = "No Next Prayer"
        var nextPrayerTime = ""
        
        // Find current prayer
        for i in 0..<prayers.count {
            let (name, time) = prayers[i]
            if currentTime >= time {
                currentPrayer = name
                currentPrayerTime = formatTime(time)
            }
        }
        
        // Find next prayer
        for i in 0..<prayers.count {
            let (name, time) = prayers[i]
            if currentTime < time {
                nextPrayer = name
                nextPrayerTime = formatTime(time)
                break
            }
        }
        
        // If no next prayer found, it's tomorrow's Fajr
        if nextPrayer == "No Next Prayer" {
            nextPrayer = "Fajr"
            let tomorrowFajr = calendar.date(byAdding: .day, value: 1, to: prayerData.fajr) ?? prayerData.fajr
            nextPrayerTime = formatTime(tomorrowFajr)
        }
        
        // Calculate time remaining and progress like main app
        let nextPrayerTimeDate = prayers.first { currentTime < $0.1 }?.1 ?? calendar.date(byAdding: .day, value: 1, to: prayerData.fajr) ?? prayerData.fajr
        let timeRemaining = nextPrayerTimeDate.timeIntervalSince(currentTime)
        let timeRemainingText = formatTimeRemaining(timeRemaining)
        let progress = calculateProgressFromCachedData(prayerData: prayerData, currentTime: currentTime, nextPrayerTime: nextPrayerTimeDate)
        
        return PrayerEntry(
            date: date,
            currentPrayer: currentPrayer,
            currentPrayerTime: currentPrayerTime,
            nextPrayer: nextPrayer,
            nextPrayerTime: nextPrayerTime,
            timeRemaining: timeRemainingText,
            progress: progress,
            isLoading: false
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func createMinuteTimelineEntries(entries: inout [PrayerEntry], prayerData: PrayerData, startDate: Date) {
        let calendar = Calendar.current
        
        // Create entries for next 24 hours, updating every minute
        for minute in 1...1440 { // 24 hours * 60 minutes
            if let futureDate = calendar.date(byAdding: .minute, value: minute, to: startDate) {
                let futureEntry = createPrayerEntryFromCachedData(prayerData, date: futureDate)
                entries.append(futureEntry)
            }
        }
    }
    
    private func createMinuteTimelineEntriesForAdhan(entries: inout [PrayerEntry], prayerTimes: PrayerTimes, coordinates: Coordinates, params: CalculationParameters, startDate: Date) {
        let calendar = Calendar.current
        
        // Create entries for next 24 hours, updating every minute
        for minute in 1...1440 { // 24 hours * 60 minutes
            if let futureDate = calendar.date(byAdding: .minute, value: minute, to: startDate) {
                let futureDateComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
                if let futurePrayerTimes = PrayerTimes(coordinates: coordinates, date: futureDateComponents, calculationParameters: params) {
                    let futureEntry = createPrayerEntryFromAdhan(futurePrayerTimes, date: futureDate)
                    entries.append(futureEntry)
                }
            }
        }
    }
    
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let currentPrayer: String
    let currentPrayerTime: String
    let nextPrayer: String
    let nextPrayerTime: String
    let timeRemaining: String
    let progress: Double
    let isLoading: Bool
}

// MARK: - Simple Progress Bar Component (matching main app)
struct WidgetProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 9)
                
                // Progress
                Capsule()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress, height: 9)
            }
        }
        .frame(height: 9)
    }
}

struct AthanSimpleWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Current prayer info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.currentPrayer)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if !entry.currentPrayerTime.isEmpty {
                    Text(entry.currentPrayerTime)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side - Next prayer and countdown (matching main app)
            VStack(alignment: .center, spacing: 8) {
                Text("Next \(entry.nextPrayer) - \(entry.nextPrayerTime)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                
                if !entry.timeRemaining.isEmpty {
                    Text(entry.timeRemaining)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // Simple progress bar like main app
                WidgetProgressBar(progress: entry.progress)
                    .frame(width: 120)
            }
            .frame(maxWidth: 170, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

struct AthanSimpleWidget: Widget {
    let kind: String = "AthanSimpleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AthanSimpleWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Shows current prayer and countdown to next prayer")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget Settings (simplified for widget use)
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

// MARK: - Prayer Data
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

#Preview(as: .systemMedium) {
    AthanSimpleWidget()
} timeline: {
    PrayerEntry(
        date: .now,
        currentPrayer: "Fajr",
        currentPrayerTime: "5:30 AM",
        nextPrayer: "Dhuhr",
        nextPrayerTime: "12:15 PM",
        timeRemaining: "3h 45m",
        progress: 0.5,
        isLoading: false
    )
    PrayerEntry(
        date: .now,
        currentPrayer: "No Current Prayer",
        currentPrayerTime: "",
        nextPrayer: "Maghrib",
        nextPrayerTime: "6:45 PM",
        timeRemaining: "1h 15m",
        progress: 0.7,
        isLoading: false
    )
}
