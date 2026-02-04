//
//  HealthService.swift
//  Terrain
//
//  Reads daily step count from HealthKit and caches it on DailyLog.
//  Follows the same pattern as WeatherService: fetch once per calendar day,
//  gracefully handle unavailable/denied, cache result locally.
//
//  Think of this as a pedometer bridge — it translates Apple's health data
//  into a single number that InsightEngine and SuggestionEngine can use
//  to adjust recommendations (e.g., "you've been sedentary, try gentle movement").
//

import Foundation
import HealthKit
import os.log

@MainActor @Observable
final class HealthService {

    // MARK: - Published State

    /// Today's step count (nil if unavailable or not yet fetched)
    private(set) var dailyStepCount: Int?

    /// Whether a fetch is in progress
    private(set) var isFetching = false

    // MARK: - Private

    private let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    private static let lastFetchDateKey = "HealthService.lastFetchDate"

    // MARK: - Public API

    /// Fetch step count if we haven't already fetched today.
    /// Writes result to the provided DailyLog for persistence.
    /// Gracefully no-ops on simulator or if authorization is denied.
    func fetchHealthDataIfNeeded(for dailyLog: DailyLog?) async {
        guard !isFetching else { return }
        guard let healthStore else {
            TerrainLogger.health.info("HealthKit unavailable — skipping step count fetch")
            // Populate from log if available
            dailyStepCount = dailyLog?.stepCount
            return
        }

        guard shouldFetchToday() else {
            // Already fetched today — populate from log
            dailyStepCount = dailyLog?.stepCount
            return
        }

        isFetching = true
        defer { isFetching = false }

        // Request authorization
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
        } catch {
            TerrainLogger.health.error("HealthKit authorization failed: \(error.localizedDescription)")
            return
        }

        // Query today's steps
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        do {
            let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let count = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    continuation.resume(returning: count)
                }
                healthStore.execute(query)
            }

            dailyStepCount = steps

            // Persist to DailyLog
            if let log = dailyLog {
                log.stepCount = steps
                log.updatedAt = Date()
            }

            markFetchedToday()
            TerrainLogger.health.info("Steps fetched: \(steps)")
        } catch {
            TerrainLogger.health.error("Step count query failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Date Gate

    private func shouldFetchToday() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: Self.lastFetchDateKey) as? Date else {
            return true
        }
        return !Calendar.current.isDateInToday(lastDate)
    }

    private func markFetchedToday() {
        UserDefaults.standard.set(Date(), forKey: Self.lastFetchDateKey)
    }
}
