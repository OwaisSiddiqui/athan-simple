import SwiftUI

// MARK: - Prayer Row Component
struct PrayerRow: View {
    let prayer: PrayerTimeItem
    let isCurrent: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prayer.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCurrent ? .primary : .primary)
                
                Text(PrayerUtils.formatTimeString(prayer.time))
                    .font(.system(size: 14))
                    .foregroundColor(isCurrent ? .secondary : .secondary)
            }
            
            Spacer()
            
            if isCurrent {
                Text("Current")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

