//
//  SymptomHeatmapView.swift
//  Terrain
//
//  An 8x14 grid (8 symptom categories x 14 days), like GitHub's contribution chart.
//  Each cell is colored by whether the symptom was reported that day.
//  Tapping a day column opens an edit sheet to adjust that day's symptoms.
//

import SwiftUI
import SwiftData

struct SymptomHeatmapView: View {
    let dailyLogs: [DailyLog]
    var windowDays: Int = 14

    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    /// The day being edited (nil = no sheet shown)
    @State private var editingDate: EditableDay?

    /// The symptom categories we track, in display order.
    /// Icons come from QuickSymptom.icon — never hardcode SF Symbol names here.
    private let categories: [(label: String, symptom: QuickSymptom)] = [
        ("Sleep", .poorSleep),
        ("Digestion", .bloating),
        ("Stress", .stressed),
        ("Tired", .tired),
        ("Headache", .headache),
        ("Cramps", .cramps),
        ("Stiff", .stiff),
        ("Cold", .cold)
    ]

    /// Column headers: abbreviated day labels
    private var dayLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            return String(formatter.string(from: date).prefix(1))
        }
    }

    /// Convert a day index to a calendar date
    private func dateForIndex(_ dayIndex: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(windowDays - 1 - dayIndex), to: today) ?? today
    }

    /// Find the DailyLog for a given day index
    private func logForDayIndex(_ dayIndex: Int) -> DailyLog? {
        let calendar = Calendar.current
        let dayStart = dateForIndex(dayIndex)
        return dailyLogs.first { calendar.startOfDay(for: $0.date) == dayStart }
    }

    /// Pre-computed map: (symptom, dayIndex) → had symptom?
    private func hasSymptom(_ symptom: QuickSymptom, onDayIndex dayIndex: Int) -> Bool {
        guard let log = logForDayIndex(dayIndex) else { return false }
        return log.quickSymptoms.contains(symptom)
    }

    /// Whether we have any log data for a given day index
    private func hasData(onDayIndex dayIndex: Int) -> Bool {
        logForDayIndex(dayIndex) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Symptom Heatmap")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            if dailyLogs.isEmpty {
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 28))
                        .foregroundColor(theme.colors.textTertiary)

                    Text("Check in daily to build your symptom pattern map")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
            } else {
                VStack(spacing: 2) {
                    // Day column headers
                    HStack(spacing: 2) {
                        // Spacer for row label column
                        Color.clear
                            .frame(width: 60, height: 12)

                        ForEach(0..<windowDays, id: \.self) { dayIndex in
                            Text(dayLabels[dayIndex])
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(theme.colors.textTertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Grid rows
                    ForEach(Array(categories.enumerated()), id: \.offset) { _, category in
                        HStack(spacing: 2) {
                            // Row label
                            HStack(spacing: 2) {
                                Image(systemName: category.symptom.icon)
                                    .font(.system(size: 8))
                                Text(category.label)
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(theme.colors.textTertiary)
                            .frame(width: 60, alignment: .leading)

                            // Cells — tappable to edit that day
                            ForEach(0..<windowDays, id: \.self) { dayIndex in
                                let hasData = hasData(onDayIndex: dayIndex)
                                let hasSymptom = hasSymptom(category.symptom, onDayIndex: dayIndex)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cellColor(hasData: hasData, hasSymptom: hasSymptom))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .onTapGesture {
                                        editingDate = EditableDay(date: dateForIndex(dayIndex))
                                        HapticManager.light()
                                    }
                            }
                        }
                    }
                }

                // Tap hint
                Text("Tap a cell to edit that day")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, theme.spacing.xxs)
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .sheet(item: $editingDate) { editableDay in
            HeatmapEditSheet(date: editableDay.date, dailyLogs: dailyLogs)
        }
    }

    private func cellColor(hasData: Bool, hasSymptom: Bool) -> Color {
        if !hasData {
            return theme.colors.backgroundSecondary.opacity(0.5) // no data = very faint
        }
        if hasSymptom {
            return theme.colors.warning.opacity(0.6) // symptom present = warm highlight
        }
        return theme.colors.success.opacity(0.2) // no symptom = gentle green
    }
}

// MARK: - EditableDay (avoids global Date: Identifiable conformance)

/// Wrapper so we can use .sheet(item:) without adding Identifiable to Date globally.
struct EditableDay: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSinceReferenceDate }
}

// MARK: - Heatmap Edit Sheet

/// A compact sheet to toggle symptoms for a specific day.
struct HeatmapEditSheet: View {
    let date: Date
    let dailyLogs: [DailyLog]

    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSymptoms: Set<QuickSymptom> = []
    @State private var moodSliderValue: Double = 5.0
    @State private var hasMoodEntry: Bool = false

    private var log: DailyLog? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return dailyLogs.first { calendar.startOfDay(for: $0.date) == dayStart }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.lg) {
                Text(formattedDate)
                    .font(theme.typography.headlineSmall)
                    .foregroundColor(theme.colors.textPrimary)

                // Mood rating slider
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("How were you feeling?")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    HStack(alignment: .center, spacing: theme.spacing.sm) {
                        Text("1")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)

                        Slider(
                            value: $moodSliderValue,
                            in: 1...10,
                            step: 1
                        ) {
                            Text("Mood rating")
                        }
                        .tint(theme.colors.accent)
                        .onChange(of: moodSliderValue) { _, _ in
                            if !hasMoodEntry {
                                hasMoodEntry = true
                            }
                            HapticManager.selection()
                        }
                        .accessibilityValue("\(Int(moodSliderValue)) out of 10")

                        Text("10")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }

                    Text("\(Int(moodSliderValue))")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.colors.accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, theme.spacing.lg)

                Divider()
                    .padding(.horizontal, theme.spacing.lg)

                LazyVGrid(columns: columns, spacing: theme.spacing.xs) {
                    ForEach(QuickSymptom.allCases) { symptom in
                        Button {
                            toggleSymptom(symptom)
                        } label: {
                            HStack(spacing: theme.spacing.xs) {
                                Image(systemName: symptom.icon)
                                    .font(.system(size: 14))
                                Text(symptom.displayName)
                                    .font(theme.typography.labelSmall)
                            }
                            .foregroundColor(selectedSymptoms.contains(symptom) ? theme.colors.textInverted : theme.colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.sm)
                            .background(selectedSymptoms.contains(symptom) ? theme.colors.accent : theme.colors.backgroundSecondary)
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacing.lg)

                Spacer()
            }
            .padding(.top, theme.spacing.lg)
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .task(id: date) {
            if let log = log {
                selectedSymptoms = Set(log.quickSymptoms)
                if let mood = log.moodRating {
                    moodSliderValue = Double(mood)
                    hasMoodEntry = true
                } else {
                    moodSliderValue = 5.0
                    hasMoodEntry = false
                }
            } else {
                selectedSymptoms = []
                moodSliderValue = 5.0
                hasMoodEntry = false
            }
        }
    }

    private func toggleSymptom(_ symptom: QuickSymptom) {
        if selectedSymptoms.contains(symptom) {
            selectedSymptoms.remove(symptom)
        } else {
            selectedSymptoms.insert(symptom)
        }
        HapticManager.selection()
    }

    private func saveChanges() {
        let moodToSave = hasMoodEntry ? Int(moodSliderValue) : nil

        if let log = log {
            log.quickSymptoms = Array(selectedSymptoms)
            log.moodRating = moodToSave
            log.updatedAt = Date()
        } else {
            let newLog = DailyLog(date: date, quickSymptoms: Array(selectedSymptoms), moodRating: moodToSave)
            modelContext.insert(newLog)
        }
        try? modelContext.save()
        HapticManager.success()
    }
}
