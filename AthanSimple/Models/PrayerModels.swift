import Foundation

// MARK: - Prayer Time Models
struct PrayerTime: Codable, Identifiable {
    let id = UUID()
    let day: String
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    
    enum CodingKeys: String, CodingKey {
        case day, fajr, sunrise, dhuhr, asr, maghrib, isha
    }
}

struct MonthData: Codable, Identifiable {
    let id = UUID()
    let month: String
    let prayers: [PrayerTime]
    
    enum CodingKeys: String, CodingKey {
        case month, prayers
    }
}

// MARK: - Prayer Name Type
enum PrayerName: String, CaseIterable {
    case fajr = "fajr"
    case sunrise = "sunrise"
    case dhuhr = "dhuhr"
    case asr = "asr"
    case maghrib = "maghrib"
    case isha = "isha"
    
    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
}

// MARK: - Prayer Time Item
struct PrayerTimeItem: Identifiable {
    let id = UUID()
    let name: String
    let time: String
    let prayerName: PrayerName
}

// MARK: - Prayer Timeline
struct PrayerTimeline {
    let current: PrayerTimelineItem?
    let next: PrayerTimelineItem?
}

struct PrayerTimelineItem {
    let name: PrayerName
    let date: Date
    let time: String
}

