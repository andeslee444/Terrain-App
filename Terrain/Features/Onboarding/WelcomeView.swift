//
//  WelcomeView.swift
//  Terrain
//
//  Welcome screen for onboarding
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    var body: some View {
        VStack(spacing: theme.spacing.xxl) {
            Spacer()

            // Logo/Title
            VStack(spacing: theme.spacing.md) {
                Text("Terrain")
                    .font(theme.typography.displayLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Your body has a climate.")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // Single poetic subtitle — mystique over features
            Text("Take a 3-minute assessment.\nGet daily rituals rooted in\nTraditional Chinese Medicine.")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(theme.animation.reveal.delay(0.2), value: showContent)

            // What you'll get
            VStack(spacing: theme.spacing.md) {
                featureRow(emoji: "🌿", text: "Discover your body's unique pattern")
                featureRow(emoji: "☀️", text: "Get a personalized daily routine")
                featureRow(emoji: "🍵", text: "Learn which ingredients suit you")
            }
            .padding(.horizontal, theme.spacing.xl)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(theme.animation.reveal.delay(0.4), value: showContent)

            Spacer()

            // Continue button
            TerrainPrimaryButton(title: "Begin", action: onContinue)
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.6), value: showContent)

            // Terms
            Text("By continuing, you agree to our Terms of Service")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.6), value: showContent)
        }
        .padding(theme.spacing.lg)
        .onAppear {
            withAnimation(theme.animation.reveal) {
                showContent = true
            }
        }
    }
    private func featureRow(emoji: String, text: String) -> some View {
        HStack(spacing: theme.spacing.sm) {
            Text(emoji)
                .font(.title3)
            Text(text)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


#Preview {
    WelcomeView(onContinue: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
