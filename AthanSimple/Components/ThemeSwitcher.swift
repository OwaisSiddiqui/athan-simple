import SwiftUI

// MARK: - Theme Switcher Component
struct ThemeSwitcher: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            themeManager.toggleTheme()
        }) {
            Image(systemName: themeIcon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var themeIcon: String {
        switch themeManager.currentTheme {
        case "system":
            return "display"
        case "dark":
            return "moon.fill"
        case "light":
            return "sun.max.fill"
        default:
            return "display"
        }
    }
}

