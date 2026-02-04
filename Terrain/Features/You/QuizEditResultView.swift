//
//  QuizEditResultView.swift
//  Terrain
//
//  Compact result shown after editing quiz answers.
//  Shows whether terrain changed or was confirmed.
//

import SwiftUI

struct QuizEditResultView: View {
    let oldTerrainId: String?
    let newResult: TerrainScoringEngine.ScoringResult
    let onDismiss: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    private var terrainChanged: Bool {
        oldTerrainId != newResult.terrainProfileId
    }

    private var oldNickname: String {
        guard let id = oldTerrainId,
              let type = TerrainScoringEngine.PrimaryType(rawValue: id) else {
            return "Unknown"
        }
        return type.nickname
    }

    private var newNickname: String {
        newResult.primaryType.nickname
    }

    var body: some View {
        VStack(spacing: theme.spacing.xxl) {
            Spacer()

            // Icon
            Image(systemName: terrainChanged ? "arrow.triangle.2.circlepath.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(terrainChanged ? theme.colors.accent : theme.colors.success)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)

            // Message
            VStack(spacing: theme.spacing.md) {
                Text(terrainChanged ? "Your terrain has shifted" : "Your terrain is confirmed")
                    .font(theme.typography.displayMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                if terrainChanged {
                    HStack(spacing: theme.spacing.sm) {
                        Text(oldNickname)
                            .font(theme.typography.headlineSmall)
                            .foregroundColor(theme.colors.textTertiary)
                            .strikethrough()

                        Image(systemName: "arrow.right")
                            .foregroundColor(theme.colors.accent)
                            .font(.system(size: 14))

                        Text(newNickname)
                            .font(theme.typography.headlineSmall)
                            .foregroundColor(theme.colors.accent)
                    }

                    Text("Your daily rituals will adapt to your updated profile.")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.xl)
                } else {
                    Text(newNickname)
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.accent)

                    Text("Your answers still point to the same terrain. Your rituals remain tuned to you.")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.xl)
                }
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)

            Spacer()

            TerrainPrimaryButton(title: "Done", action: onDismiss)
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.3), value: showContent)

            Spacer(minLength: theme.spacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}
