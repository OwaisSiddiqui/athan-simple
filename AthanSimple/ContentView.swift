//
//  ContentView.swift
//  AthanSimple
//
//  Created by Owais Siddiqui on 2025-10-05.
//

import SwiftUI
import CoreLocation
import Adhan

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var settings = SettingsModel()
    @StateObject private var prayerService: PrayerCalculationService
    @StateObject private var themeManager = ThemeManager()
    @State private var showingSettings = false
    @State private var timer: Timer?
    @State private var updateTrigger = false
    
    init() {
        let settings = SettingsModel()
        _settings = StateObject(wrappedValue: settings)
        _prayerService = StateObject(wrappedValue: PrayerCalculationService(settings: settings))
    }
    
    private var systemBackgroundColor: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var systemGray6Color: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(NSColor.controlColor)
        #endif
    }
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            VStack(spacing: 0) {
                // Header with location and date
                headerView
                
                if locationManager.isLoading || prayerService.isLoading {
                    Spacer()
                    ProgressView("Loading prayer times...")
                        .font(.headline)
                    Spacer()
                } else if let errorMessage = locationManager.errorMessage ?? prayerService.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Try Again") {
                            locationManager.startLocationUpdates()
                        }
                        #if os(iOS)
                        .buttonStyle(.borderedProminent)
                        #else
                        .buttonStyle(.bordered)
                        #endif
                    }
                    .padding()
                    Spacer()
                } else if let prayerTimes = prayerService.prayerTimes {
                    prayerTimesView(prayerTimes)
                        .id(updateTrigger) // Force refresh when timer updates
                } else {
                    welcomeView
                }
            }
            .preferredColorScheme(themeManager.colorScheme)
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
            .onChange(of: locationManager.location) { _, location in
                if let location = location {
                    prayerService.calculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.calculationMethod) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.madhab) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.highLatitudeRule) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.shafaq) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.fajrAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.sunriseAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.dhuhrAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.asrAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.maghribAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.ishaAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.rounding) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onAppear {
                startTimer()
                locationManager.startLocationUpdates()
            }
            .onDisappear {
                stopTimer()
            }
        }
        #else
        NavigationView {
            VStack(spacing: 0) {
                // Header with location and date
                headerView
                
                if locationManager.isLoading || prayerService.isLoading {
                    Spacer()
                    ProgressView("Loading prayer times...")
                        .font(.headline)
                    Spacer()
                } else if let errorMessage = locationManager.errorMessage ?? prayerService.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Try Again") {
                            locationManager.startLocationUpdates()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else if let prayerTimes = prayerService.prayerTimes {
                    prayerTimesView(prayerTimes)
                        .id(updateTrigger) // Force refresh when timer updates
                } else {
                    welcomeView
                }
            }
            .preferredColorScheme(themeManager.colorScheme)
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
            .onChange(of: locationManager.location) { _, location in
                if let location = location {
                    prayerService.calculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.calculationMethod) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.madhab) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.highLatitudeRule) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.shafaq) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.fajrAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.sunriseAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.dhuhrAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.asrAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.maghribAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.ishaAdjustment) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onChange(of: settings.rounding) { _, _ in
                if let location = locationManager.location {
                    prayerService.recalculatePrayerTimes(for: location)
                }
            }
            .onAppear {
                startTimer()
                locationManager.startLocationUpdates()
            }
            .onDisappear {
                stopTimer()
            }
        }
        #endif
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Update current and next prayer, then force UI update
            if prayerService.prayerTimes != nil {
                prayerService.updateCurrentAndNextPrayer()
                DispatchQueue.main.async {
                    updateTrigger.toggle()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 2) {
                Text(locationManager.city.isEmpty ? "Location" : locationManager.city)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(getCurrentDateString())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .frame(height: 48)
        .background(systemBackgroundColor)
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "location.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Athan Simple")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Getting your location to calculate accurate prayer times...")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private func prayerTimesView(_ prayerTimes: PrayerTimes) -> some View {
        VStack(spacing: 0) {
            // Current Prayer Section
            if let next = prayerService.nextPrayer {
                if let current = prayerService.currentPrayer {
                    currentPrayerSection(current: current, next: next)
                } else {
                    // No current prayer (e.g., after Isha), show next prayer info
                    nextPrayerSection(next: next)
                }
            }
            
            Spacer()
            
            // Prayer Times List
            ScrollView {
                LazyVStack(spacing: 12) {
                    prayerCard(prayer: .fajr, time: prayerService.getPrayerTimeString(for: .fajr), isCurrent: prayerService.currentPrayer == .fajr)
                    prayerCard(prayer: .sunrise, time: prayerService.getPrayerTimeString(for: .sunrise), isCurrent: prayerService.currentPrayer == .sunrise)
                    prayerCard(prayer: .dhuhr, time: prayerService.getPrayerTimeString(for: .dhuhr), isCurrent: prayerService.currentPrayer == .dhuhr)
                    prayerCard(prayer: .asr, time: prayerService.getPrayerTimeString(for: .asr), isCurrent: prayerService.currentPrayer == .asr)
                    prayerCard(prayer: .maghrib, time: prayerService.getPrayerTimeString(for: .maghrib), isCurrent: prayerService.currentPrayer == .maghrib)
                    prayerCard(prayer: .isha, time: prayerService.getPrayerTimeString(for: .isha), isCurrent: prayerService.currentPrayer == .isha)
                    
                    // Bottom
                    HStack {
                        HStack(spacing: 12) {
                            GearIcon {
                                showingSettings = true
                            }
                            
                            ThemeSwitcher(themeManager: themeManager)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func currentPrayerSection(current: PrayerName, next: PrayerName) -> some View {
        VStack(spacing: 0) {
            // Main current prayer section
            HStack {
                // Left side - Current prayer info
                VStack(alignment: .leading, spacing: 4) {
                    Text(prayerService.getPrayerName(for: current))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(prayerService.getPrayerTimeString(for: current))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                    // Right side - Next prayer and countdown
                    VStack(alignment: .center, spacing: 8) {
                        Text("Next \(prayerService.getPrayerName(for: next)) - \(prayerService.getPrayerTimeString(for: next))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if let timeRemaining = prayerService.getTimeUntilNextPrayer(),
                           timeRemaining > 0 {
                            Text(formatTimeRemaining(timeRemaining))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        } else if prayerService.isLoading {
                            Text("Calculating...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        } else {
                            Text("Next prayer time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    
                    // Progress bar
                    ProgressBar(
                        progress: prayerService.getProgressToNextPrayer() * 100
                    )
                    .frame(height: 9)
                }
                .frame(maxWidth: 170)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
        }
        .background(systemBackgroundColor)
        .padding(.horizontal, 20)
    }
    
    private func nextPrayerSection(next: PrayerName) -> some View {
        VStack(spacing: 0) {
            // Next prayer section (when no current prayer)
            HStack {
                // Left side - Next prayer info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Prayer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(prayerService.getPrayerName(for: next))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(prayerService.getPrayerTimeString(for: next))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                    // Right side - Countdown
                    VStack(alignment: .center, spacing: 8) {
                        Text("Time Remaining")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if let timeRemaining = prayerService.getTimeUntilNextPrayer(),
                           timeRemaining > 0 {
                            Text(formatTimeRemaining(timeRemaining))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        } else if prayerService.isLoading {
                            Text("Calculating...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        } else {
                            Text("Next prayer time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    
                    // Progress bar
                    ProgressBar(
                        progress: prayerService.getProgressToNextPrayer() * 100
                    )
                    .frame(height: 12)
                }
                .frame(maxWidth: 150)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
        }
        .background(systemBackgroundColor)
        .padding(.horizontal, 20)
    }
    
    private func prayerCard(prayer: PrayerName, time: String, isCurrent: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prayerService.getPrayerName(for: prayer))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCurrent ? .blue : .primary)
                
                Text(time)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isCurrent ? .blue.opacity(0.8) : .secondary)
            }
            
            Spacer()
            
            if isCurrent {
                Text("Current")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .cornerRadius(12)
                    .background(
                        Rectangle()
                            .fill(isCurrent ? Color.blue.opacity(0.1) : systemGray6Color)
                            #if os(iOS)
                            .clipShape(.capsule)
                            #else
                            .clipShape(Capsule())
                            #endif
                    )
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.blue.opacity(0.05) : systemGray6Color)
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
}

#Preview {
    ContentView()
}
