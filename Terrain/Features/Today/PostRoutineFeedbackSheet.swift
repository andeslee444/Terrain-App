//
//  PostRoutineFeedbackSheet.swift
//  Terrain
//
//  Motivational completion sheet shown after finishing a routine or movement.
//  Encourages consistency with a "keep going" message and explains how it helps.
//

import SwiftUI

/// Post-completion sheet: celebrates the user and encourages consistency.
/// Shows routine name, a motivational message, and a terrain-specific "why it helps" note.
struct PostRoutineFeedbackSheet: View {
    let routineTitle: String
    let whyItHelps: String?
    let onDismiss: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Celebration icon
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.colors.success)
                        .padding(.top, theme.spacing.xl)

                    // Congrats message
                    VStack(spacing: theme.spacing.sm) {
                        Text("Great job!")
                            .font(theme.typography.headlineLarge)
                            .foregroundColor(theme.colors.textPrimary)

                        Text("Keep doing **\(routineTitle)** over the next 5 days to feel the difference.")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Why it helps — terrain-specific
                    if let why = whyItHelps, !why.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text("Why this helps you")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.accent)

                            Text(why)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(theme.spacing.md)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.cornerRadius.large)
                    }
                }
                .padding(.horizontal, theme.spacing.xl)
            }

            // Done button pinned at bottom
            TerrainPrimaryButton(title: "Done") {
                onDismiss()
                dismiss()
            }
            .padding(theme.spacing.xl)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PostRoutineFeedbackSheet(
        routineTitle: "Warm Start Congee",
        whyItHelps: "Warming your digestion in the morning helps your cold-deficient pattern hold steady energy through the day. Congee is easy to absorb, so your body spends less effort breaking it down.",
        onDismiss: { }
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
