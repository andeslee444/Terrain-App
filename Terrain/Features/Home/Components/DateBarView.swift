//
//  DateBarView.swift
//  Terrain
//
//  Date display with daily tone pill for the Home tab header
//

import SwiftUI

/// Displays the current date and daily tone indicator.
/// Example: "Wednesday · Jan 28" with a tappable "Balance Day · Dry air" pill.
struct DateBarView: View {
    let dailyTone: DailyTone
    var onToneTap: (() -> Void)? = nil

    @Environment(\.terrainTheme) private var theme

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            Text(dateString)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, theme.spacing.lg)
    }
}

#Preview {
    VStack(spacing: 20) {
        DateBarView(
            dailyTone: DailyTone(label: "Balance Day", environmentalNote: "Dry air")
        )

        DateBarView(
            dailyTone: DailyTone(label: "Low Flame Day")
        )
    }
    .padding(.vertical)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
