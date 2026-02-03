//
//  WeatherService.swift
//  Terrain
//
//  Fetches current weather via WeatherKit + CoreLocation and maps it to
//  the app's string-based weather conditions. Think of it as a translator
//  between Apple's detailed weather data and the simple weather buckets
//  that InsightEngine and SuggestionEngine understand.
//
//  Instantiated as @State in HomeView. Fetches once per calendar day
//  (UserDefaults date gate) so we don't hammer the API or drain battery.
//

import Foundation
import WeatherKit
import CoreLocation
import os.log

@MainActor @Observable
final class WeatherService: NSObject {

    // MARK: - Published State

    /// The mapped weather condition string (e.g. "cold", "hot", "rainy", "humid", "dry", "windy", "clear")
    private(set) var currentCondition: String?

    /// Temperature in Celsius from the latest fetch
    private(set) var temperatureCelsius: Double?

    /// Whether a fetch is in progress
    private(set) var isFetching = false

    // MARK: - Private

    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    private static let lastFetchDateKey = "WeatherService.lastFetchDate"

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Public API

    /// Fetch weather if we haven't already fetched today.
    /// Writes results directly to the provided DailyLog.
    /// Gracefully no-ops if location is denied or weather unavailable.
    func fetchWeatherIfNeeded(for dailyLog: DailyLog?) async {
        guard !isFetching else { return }
        guard shouldFetchToday() else {
            // Already fetched today — populate from log if available
            if let log = dailyLog {
                currentCondition = log.weatherCondition
                temperatureCelsius = log.temperatureCelsius
            }
            return
        }

        isFetching = true
        defer { isFetching = false }

        // 1. Request location
        guard let location = await requestLocation() else {
            TerrainLogger.weather.info("Location unavailable — skipping weather fetch")
            return
        }

        // 2. Fetch weather
        do {
            let weather = try await weatherService.weather(for: location)
            let current = weather.currentWeather

            let tempC = current.temperature.converted(to: .celsius).value
            let condition = mapCondition(current)

            self.temperatureCelsius = tempC
            self.currentCondition = condition

            // 3. Persist to DailyLog
            if let log = dailyLog {
                log.weatherCondition = condition
                log.temperatureCelsius = tempC
                log.updatedAt = Date()
            }

            // 4. Mark as fetched today
            markFetchedToday()

            TerrainLogger.weather.info("Weather fetched: \(condition), \(String(format: "%.1f", tempC))°C")
        } catch {
            TerrainLogger.weather.error("Weather fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Weather Condition Mapping

    /// Maps WeatherKit's detailed condition + temperature + humidity into
    /// our simplified string buckets that InsightEngine/SuggestionEngine understand.
    ///
    /// Priority order matters — rain overrides temperature, temperature overrides humidity, etc.
    private func mapCondition(_ weather: CurrentWeather) -> String {
        let tempC = weather.temperature.converted(to: .celsius).value

        // Check precipitation conditions first (most impactful)
        switch weather.condition {
        case .rain, .heavyRain, .drizzle, .thunderstorms, .tropicalStorm, .hurricane:
            return "rainy"
        case .snow, .heavySnow, .sleet, .freezingRain, .freezingDrizzle, .flurries, .blizzard:
            return "cold"
        case .blowingDust, .blowingSnow:
            return "windy"
        default:
            break
        }

        // Check wind
        if weather.wind.speed.converted(to: .kilometersPerHour).value >= 30 {
            return "windy"
        }

        // Check temperature extremes
        if tempC <= 5 { return "cold" }
        if tempC >= 32 { return "hot" }

        // Check humidity
        if weather.humidity >= 0.75 { return "humid" }
        if weather.humidity <= 0.25 { return "dry" }

        return "clear"
    }

    // MARK: - Date Gate

    private func shouldFetchToday() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: Self.lastFetchDateKey) as? Date else {
            return true
        }
        return !Calendar.current.isDateInToday(lastDate)
    }

    private func markFetchedToday() {
        UserDefaults.standard.set(Date(), forKey: Self.lastFetchDateKey)
    }

    // MARK: - Location

    /// Requests a single location fix. Returns nil if authorization is denied
    /// or if the fix times out.
    private func requestLocation() async -> CLLocation? {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Wait briefly for the user to respond
            try? await Task.sleep(for: .seconds(2))
            let newStatus = locationManager.authorizationStatus
            guard newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways else {
                return nil
            }
        case .denied, .restricted:
            return nil
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            return nil
        }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationContinuation?.resume(returning: locations.first)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            TerrainLogger.weather.error("Location error: \(error.localizedDescription)")
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }
}
