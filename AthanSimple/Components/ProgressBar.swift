import SwiftUI

// MARK: - Progress Bar Component
struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color(NSColor.tertiarySystemFill))
                    .frame(height: 9)
                
                // Progress
                Capsule()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * (progress / 100), height: 9)
                    .animation(.easeInOut(duration: 1.0), value: progress)
            }
        }
        .frame(height: 9)
    }
}

