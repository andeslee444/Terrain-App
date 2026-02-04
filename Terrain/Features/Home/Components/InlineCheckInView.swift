//
//  InlineCheckInView.swift
//  Terrain
//
//  Inline symptom chip selection for quick daily check-in
//

import SwiftUI

/// Inline check-in with toggleable symptom chips inside a card, and a "Nothing today" text button.
/// Uses a 2-column grid with icon+label rectangular chips to differentiate from identity pills.
/// Selections are staged locally — the card stays visible until the user taps "Confirm".
struct InlineCheckInView: View {
    @Binding var selectedSymptoms: Set<QuickSymptom>
    @Binding var moodRating: Int?
    let onSkip: () -> Void

    /// Symptoms sorted by relevance to the user's terrain type.
    /// Defaults to QuickSymptom.allCases if not provided.
    var sortedSymptoms: [QuickSymptom] = QuickSymptom.allCases.map { $0 }

    @Environment(\.terrainTheme) private var theme
    @State private var isSkipped = false
    /// Local staging set — selections stay here until the user confirms.
    @State private var stagedSymptoms: Set<QuickSymptom> = []
    /// Local staging for mood slider value (1-10, displayed as continuous slider)
    @State private var stagedMoodRating: Double = 5.0
    /// Whether the user has interacted with the mood slider
    @State private var hasStagedMood: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Mood rating section
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("How are you feeling today?")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .center, spacing: theme.spacing.sm) {
                    Text("1")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)

                    Slider(
                        value: $stagedMoodRating,
                        in: 1...10,
                        step: 1
                    ) {
                        Text("Mood rating")
                    }
                    .tint(theme.colors.accent)
                    .onChange(of: stagedMoodRating) { _, _ in
                        if !hasStagedMood {
                            hasStagedMood = true
                        }
                        HapticManager.selection()
                    }
                    .accessibilityValue("\(Int(stagedMoodRating)) out of 10")

                    Text("10")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }

                // Display selected number prominently
                Text("\(Int(stagedMoodRating))")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.colors.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityHidden(true) // slider already announces the value
            }

            Divider()
                .padding(.vertical, theme.spacing.xxs)

            // Symptom header
            Text("Anything affecting you today?")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            // 2-column symptom grid
            LazyVGrid(columns: columns, spacing: theme.spacing.xs) {
                ForEach(sortedSymptoms, id: \.self) { symptom in
                    SymptomChipButton(
                        symptom: symptom,
                        isSelected: stagedSymptoms.contains(symptom),
                        onTap: {
                            toggleSymptom(symptom)
                        }
                    )
                }
            }

            // Bottom row: "Nothing today" left, "Confirm" right
            HStack {
                Button(action: {
                    withAnimation(theme.animation.quick) {
                        isSkipped = true
                    }
                    HapticManager.light()
                    onSkip()
                }) {
                    Text("Nothing today")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isSkipped ? 0.5 : 1.0)

                Spacer()

                if !stagedSymptoms.isEmpty || hasStagedMood {
                    Button(action: confirmSelection) {
                        Text("Confirm")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textInverted)
                            .padding(.horizontal, theme.spacing.md)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.accent)
                            .cornerRadius(theme.cornerRadius.full)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .accessibilityLabel("Confirm symptom selection")
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, theme.spacing.lg)
        .onAppear {
            stagedSymptoms = selectedSymptoms
            if let existingMood = moodRating {
                stagedMoodRating = Double(existingMood)
                hasStagedMood = true
            }
        }
    }

    private func toggleSymptom(_ symptom: QuickSymptom) {
        withAnimation(theme.animation.quick) {
            if stagedSymptoms.contains(symptom) {
                stagedSymptoms.remove(symptom)
            } else {
                stagedSymptoms.insert(symptom)
            }
        }
        HapticManager.selection()
    }

    private func confirmSelection() {
        selectedSymptoms = stagedSymptoms
        if hasStagedMood {
            moodRating = Int(stagedMoodRating)
        }
        HapticManager.success()
    }
}

/// Individual symptom chip button — rectangular (not pill) with SF Symbol icon.
/// Uses cornerRadius.medium to visually differentiate from pill-shaped identity badges.
struct SymptomChipButton: View {
    let symptom: QuickSymptom
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: symptom.icon)
                    .font(.system(size: 14))

                Text(symptom.displayName.lowercased())
                    .font(theme.typography.labelSmall)
            }
            .foregroundColor(isSelected ? theme.colors.textInverted : theme.colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.sm)
            .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(theme.animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(symptom.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// Note: FlowLayout is defined in Features/Onboarding/TerrainRevealView.swift

#Preview {
    struct PreviewWrapper: View {
        @State private var symptoms: Set<QuickSymptom> = [.cold]
        @State private var mood: Int? = nil

        var body: some View {
            InlineCheckInView(
                selectedSymptoms: $symptoms,
                moodRating: $mood,
                onSkip: { print("Skipped") }
            )
        }
    }

    return PreviewWrapper()
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "FAFAF8"))
        .environment(\.terrainTheme, TerrainTheme.default)
}
