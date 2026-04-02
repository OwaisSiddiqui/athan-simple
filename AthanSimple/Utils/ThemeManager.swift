import SwiftUI
import Combine

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme?
    
    init() {
        // Initialize with system theme
        self.colorScheme = nil
    }
    
    func toggleTheme() {
        switch colorScheme {
        case .none:
            colorScheme = .dark
        case .dark:
            colorScheme = .light
        case .light:
            colorScheme = nil
        @unknown default:
            colorScheme = .dark
        }
    }
    
    var currentTheme: String {
        switch colorScheme {
        case .none:
            return "system"
        case .dark:
            return "dark"
        case .light:
            return "light"
        @unknown default:
            return "system"
        }
    }
}
