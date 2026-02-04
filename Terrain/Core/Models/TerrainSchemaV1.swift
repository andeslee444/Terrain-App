//
//  TerrainSchemaV1.swift
//  Terrain
//
//  Schema versioning infrastructure for SwiftData migrations.
//  V1: baseline schema — all 11 model types.
//
//  Note: Adding a new optional property (e.g. DailyLog.moodRating) does NOT
//  require a new VersionedSchema. SwiftData performs automatic lightweight
//  migration for new optional fields — existing rows get nil. A V2 schema
//  is only needed when renaming/deleting columns or performing custom data
//  transforms. A previous V2 was removed because both versions referenced
//  the same live model classes, causing "Duplicate version checksums" crash.
//

import Foundation
import SwiftData

enum TerrainSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            UserCabinet.self,
            DailyLog.self,
            ProgressRecord.self,
            ProgramEnrollment.self,
            Ingredient.self,
            Routine.self,
            Movement.self,
            Lesson.self,
            Program.self,
            TerrainProfile.self
        ]
    }
}

enum TerrainMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [TerrainSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
