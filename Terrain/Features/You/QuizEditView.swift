//
//  QuizEditView.swift
//  Terrain
//
//  Edit-mode quiz retake. Pre-selects existing answers, allows the user to
//  change any response, then recalculates terrain without deleting the profile.
//  Think of it as editing a saved form rather than starting from scratch.
//

import SwiftUI
import SwiftData

struct QuizEditView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let userProfile: UserProfile

    @State private var currentIndex: Int = 0
    @State private var responses: [(questionId: String, optionId: String)] = []
    @State private var showContent = true
    @State private var showResult = false
    @State private var newResult: TerrainScoringEngine.ScoringResult?

    private let scoringEngine = TerrainScoringEngine()

    private var questions: [QuizQuestions.Question] {
        QuizQuestions.questions(for: Set(userProfile.goals))
    }

    private var currentQuestion: QuizQuestions.Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    private var selectedOptionForCurrent: String? {
        guard let question = currentQuestion else { return nil }
        return responses.first { $0.questionId == question.id }?.optionId
    }

    private var progress: Double {
        Double(currentIndex + 1) / Double(questions.count)
    }

    var body: some View {
        NavigationStack {
            if showResult, let result = newResult {
                QuizEditResultView(
                    oldTerrainId: userProfile.terrainProfileId,
                    newResult: result,
                    onDismiss: { dismiss() }
                )
            } else {
                VStack(spacing: theme.spacing.lg) {
                    // Progress + question dots
                    VStack(spacing: theme.spacing.xs) {
                        ProgressView(value: progress)
                            .tint(theme.colors.accent)
                            .padding(.horizontal, theme.spacing.lg)

                        // Tappable dot indicator
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.xxs) {
                                ForEach(0..<questions.count, id: \.self) { index in
                                    Circle()
                                        .fill(dotColor(for: index))
                                        .frame(width: 8, height: 8)
                                        .onTapGesture {
                                            navigateTo(index: index)
                                        }
                                        .accessibilityLabel("Question \(index + 1)\(index == currentIndex ? ", current" : "")")
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }

                        Text("Question \(currentIndex + 1) of \(questions.count)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }

                    Spacer()

                    // Question content
                    if let question = currentQuestion {
                        VStack(spacing: theme.spacing.xl) {
                            Text(question.title)
                                .font(theme.typography.headlineMedium)
                                .foregroundColor(theme.colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, theme.spacing.lg)

                            VStack(spacing: theme.spacing.sm) {
                                ForEach(question.options, id: \.id) { option in
                                    TerrainSelectionOption(
                                        title: option.label,
                                        isSelected: selectedOptionForCurrent == option.id,
                                        action: {
                                            answerQuestion(questionId: question.id, optionId: option.id)
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

                    // Navigation
                    HStack(spacing: theme.spacing.md) {
                        if currentIndex > 0 {
                            TerrainSecondaryButton(title: "Back") {
                                navigateWithAnimation { currentIndex -= 1 }
                            }
                        }

                        if currentIndex < questions.count - 1 {
                            TerrainPrimaryButton(title: "Next", action: {
                                navigateWithAnimation { currentIndex += 1 }
                            }, isEnabled: selectedOptionForCurrent != nil)
                        } else {
                            TerrainPrimaryButton(title: "Update My Terrain", action: {
                                recalculateAndShow()
                            }, isEnabled: selectedOptionForCurrent != nil)
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)
                }
                .navigationTitle("Edit Quiz")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            recalculateAndShow()
                        }
                        .foregroundColor(theme.colors.accent)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
            }
        }
        .onAppear { loadExistingResponses() }
    }

    // MARK: - Helpers

    private func loadExistingResponses() {
        if let stored = userProfile.quizResponses {
            responses = stored.map { (questionId: $0.questionId, optionId: $0.optionId) }
        }
    }

    private func answerQuestion(questionId: String, optionId: String) {
        responses.removeAll { $0.questionId == questionId }
        responses.append((questionId: questionId, optionId: optionId))
    }

    private func navigateTo(index: Int) {
        guard index != currentIndex, index >= 0, index < questions.count else { return }
        navigateWithAnimation { currentIndex = index }
    }

    private func navigateWithAnimation(action: @escaping () -> Void) {
        withAnimation(theme.animation.quick) { showContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            action()
            withAnimation(theme.animation.standard) { showContent = true }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index == currentIndex {
            return theme.colors.accent
        }
        let question = questions[index]
        let hasAnswer = responses.contains { $0.questionId == question.id }
        return hasAnswer ? theme.colors.accentLight : theme.colors.textTertiary.opacity(0.3)
    }

    private func recalculateAndShow() {
        let result = scoringEngine.calculateTerrain(from: responses)
        newResult = result

        // Update profile in-place (no deletion)
        userProfile.updateTerrain(
            from: result.vector,
            profileId: result.terrainProfileId,
            modifier: result.modifier
        )
        userProfile.quizResponses = responses.map {
            QuizResponse(questionId: $0.questionId, optionId: $0.optionId)
        }
        // Update lifestyle fields from responses
        userProfile.alcoholFrequency = responses.first(where: { $0.questionId == "q14_alcohol" })?.optionId
        userProfile.smokingStatus = responses.first(where: { $0.questionId == "q15_smoking" })?.optionId
        userProfile.quizVersion = 2

        withAnimation(theme.animation.reveal) {
            showResult = true
        }
    }
}
