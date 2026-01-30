//
//  QuizView.swift
//  Terrain
//
//  Quiz screen for onboarding - one question per screen
//

import SwiftUI

struct QuizView: View {
    @Bindable var coordinator: OnboardingCoordinator

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Progress with section context
            VStack(spacing: theme.spacing.xs) {
                // Section label gives context ("Your Temperature", "Your Energy", etc.)
                Text(sectionLabel(for: coordinator.currentQuestionIndex))
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.accent)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ProgressView(value: coordinator.quizProgress)
                    .tint(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.lg)

                Text("Question \(coordinator.currentQuestionIndex + 1) of \(coordinator.filteredQuestions.count)")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }

            Spacer()

            // Question
            if let question = coordinator.currentQuestion {
                VStack(spacing: theme.spacing.xl) {
                    Text(question.title)
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.lg)

                    // Options
                    VStack(spacing: theme.spacing.sm) {
                        ForEach(question.options, id: \.id) { option in
                            TerrainSelectionOption(
                                title: option.label,
                                isSelected: coordinator.selectedOptionForCurrentQuestion == option.id,
                                action: {
                                    coordinator.answerQuestion(
                                        questionId: question.id,
                                        optionId: option.id
                                    )
                                }
                            )
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }

            Spacer()

            // Navigation buttons
            HStack(spacing: theme.spacing.md) {
                // Back button
                if coordinator.currentQuestionIndex > 0 {
                    TerrainSecondaryButton(
                        title: "Back",
                        action: {
                            withAnimation(theme.animation.standard) {
                                showContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                coordinator.previousQuestion()
                                withAnimation(theme.animation.standard) {
                                    showContent = true
                                }
                            }
                        }
                    )
                }

                // Next/Complete button
                if coordinator.currentQuestionIndex < coordinator.filteredQuestions.count - 1 {
                    TerrainPrimaryButton(
                        title: "Next",
                        action: {
                            withAnimation(theme.animation.standard) {
                                showContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                coordinator.nextQuestion()
                                withAnimation(theme.animation.standard) {
                                    showContent = true
                                }
                            }
                        },
                        isEnabled: coordinator.selectedOptionForCurrentQuestion != nil
                    )
                } else {
                    TerrainPrimaryButton(
                        title: "Reveal My Type",
                        action: {
                            coordinator.calculateTerrain()
                            coordinator.nextStep()
                        },
                        isEnabled: coordinator.selectedOptionForCurrentQuestion != nil
                    )
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)
        }
        .onAppear {
            withAnimation(theme.animation.standard) {
                showContent = true
            }
        }
        .onChange(of: coordinator.currentQuestionIndex) { _, _ in
            showContent = true
        }
    }

    /// Maps question index to a friendly section name so 13 questions feel like 5 short sections
    private func sectionLabel(for index: Int) -> String {
        let totalQuestions = coordinator.filteredQuestions.count
        // Adaptive sectioning based on total question count
        // Base 13 questions: Temperature (0-2), Energy (3-4), Body (5-7,9), Cravings (8), Mind (10-12)
        // With menstrual question: adds to Body section
        if totalQuestions <= 13 {
            switch index {
            case 0...2: return "Your Temperature"
            case 3...4: return "Your Energy"
            case 5...7: return "Your Body"
            case 8: return "Your Cravings"
            case 9: return "Your Body"
            case 10...12: return "Your Mind"
            default: return "Your Body"
            }
        } else {
            // 14 questions (menstrual comfort selected)
            switch index {
            case 0...2: return "Your Temperature"
            case 3...4: return "Your Energy"
            case 5...8: return "Your Body"
            case 9: return "Your Cravings"
            case 10: return "Your Body"
            case 11...13: return "Your Mind"
            default: return "Your Body"
            }
        }
    }
}

#Preview {
    let coordinator = OnboardingCoordinator()
    return QuizView(coordinator: coordinator)
        .environment(\.terrainTheme, TerrainTheme.default)
}
