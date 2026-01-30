//
//  EvolutionTrendsView.swift
//  Terrain
//
//  Section F: 14-day rolling trends with sparklines, symptom heatmap,
//  routine effectiveness, streak card, and calendar.
//

import SwiftUI

struct EvolutionTrendsView: View {
    let trends: [TrendResult]
    let routineScores: [(name: String, score: Double)]
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int
    let dailyLogs: [DailyLog]

    @Environment(\.terrainTheme) private var theme

    @AppStorage("hasDismissedTrendsIntro") private var hasDismissedTrendsIntro = false

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Intro card for new users
            if !hasDismissedTrendsIntro {
                trendsIntroCard
            }

            // Sparkline trends section
            trendsSection

            // Symptom heatmap
            SymptomHeatmapView(dailyLogs: dailyLogs)

            // Routine effectiveness (only show if there's data)
            if !routineScores.isEmpty {
                RoutineEffectivenessCard(routineScores: routineScores)
            }

            // Streak card
            StreakCard(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                totalCompletions: totalCompletions
            )

            // Calendar
            CalendarView(dailyLogs: dailyLogs)
        }
    }

    private var trendsIntroCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(theme.colors.accent)
                    .font(.system(size: 16))
                Text("How Trends Work")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Button {
                    withAnimation(theme.animation.quick) {
                        hasDismissedTrendsIntro = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text("We track patterns from your daily check-ins. After a few days, you'll see trends emerge across sleep, digestion, stress, and more.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)

            HStack(spacing: theme.spacing.md) {
                Label("Green = improving", systemImage: "arrow.up.circle.fill")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.success)
                Label("Orange = watch", systemImage: "arrow.down.circle.fill")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.warning)
                Label("Gray = no data", systemImage: "minus.circle.fill")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("14-Day Trends")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            if trends.isEmpty {
                // Empty state
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundColor(theme.colors.textTertiary)

                    Text("Check in for a few more days to see your trends")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.lg)
            } else {
                ForEach(Array(trends.enumerated()), id: \.offset) { _, trend in
                    TrendSparklineCard(trend: trend)
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}
