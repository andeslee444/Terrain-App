//
//  WeatherHealthBarView.swift
//  Terrain
//
//  Compact bar showing weather temperature and step count as subtle pills.
//  Positioned between DateBarView and HeadlineView on the Home tab.
//

import SwiftUI

struct WeatherHealthBarView: View {
    let temperatureCelsius: Double?
    let weatherCondition: String?
    let stepCount: Int?

    @Environment(\.terrainTheme) private var theme

    /// Whether there's any data to display
    private var hasData: Bool {
        temperatureCelsius != nil || stepCount != nil
    }

    var body: some View {
        if hasData {
            HStack(spacing: theme.spacing.sm) {
                // Weather pill
                if let tempC = temperatureCelsius {
                    HStack(spacing: theme.spacing.xxs) {
                        Text(weatherIcon)
                            .font(.system(size: 12))
                        Text(formattedTemperature(celsius: tempC))
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xxs)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.cornerRadius.full)
                }

                // Steps pill
                if let steps = stepCount {
                    HStack(spacing: theme.spacing.xxs) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.textSecondary)
                        Text(formattedSteps(steps))
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xxs)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.cornerRadius.full)
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }

    // MARK: - Formatting

    private var weatherIcon: String {
        switch weatherCondition {
        case "cold":        return "❄️"
        case "hot":         return "☀️"
        case "rainy":       return "🌧️"
        case "humid":       return "💧"
        case "dry":         return "🏜️"
        case "windy":       return "💨"
        case "clear":       return "☀️"
        default:            return "🌤️"
        }
    }

    /// Formats temperature using the user's locale preference (Fahrenheit or Celsius)
    private func formattedTemperature(celsius: Double) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0

        // Use locale to determine if user prefers Fahrenheit
        let usesMetric = Locale.current.measurementSystem == .metric
        if usesMetric {
            return formatter.string(from: measurement)
        } else {
            let fahrenheit = measurement.converted(to: .fahrenheit)
            return formatter.string(from: fahrenheit)
        }
    }

    /// Formats step count (e.g., 8234 -> "8.2k", 523 -> "523")
    private func formattedSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            let k = Double(steps) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(steps)"
    }
}

#Preview {
    VStack(spacing: 16) {
        WeatherHealthBarView(
            temperatureCelsius: 22.5,
            weatherCondition: "clear",
            stepCount: 8234
        )
        WeatherHealthBarView(
            temperatureCelsius: nil,
            weatherCondition: nil,
            stepCount: 523
        )
        WeatherHealthBarView(
            temperatureCelsius: 5.0,
            weatherCondition: "cold",
            stepCount: nil
        )
    }
    .environment(\.terrainTheme, TerrainTheme.default)
}
