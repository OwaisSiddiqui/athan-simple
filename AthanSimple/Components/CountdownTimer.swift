import SwiftUI

// MARK: - Countdown Timer Component
struct CountdownTimer: View {
    let currentTime: Date
    let targetTime: Date
    
    var body: some View {
        let timeRemaining = PrayerUtils.getTimeRemaining(currentTime, targetTime)
        
        if let timeRemaining = timeRemaining {
            Text(timeRemaining.hours > 0 ? 
                 "\(timeRemaining.hours)h \(timeRemaining.minutes)m" : 
                 "\(timeRemaining.minutes)m")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        } else {
            Text("Loading...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

