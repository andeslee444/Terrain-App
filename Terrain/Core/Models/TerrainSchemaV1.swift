//
//  TerrainSchemaV1.swift
//  Terrain
//
//  Schema versioning infrastructure for SwiftData migrations.
//  This is the baseline schema — all 11 model types in their current form.
//  Future schema changes should add TerrainSchemaV2 etc. with migration stages.
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

    /// No migration stages yet — this is the v1 baseline.
    /// When you add TerrainSchemaV2, add a MigrationStage here.
    static var stages: [MigrationStage] {
        []
    }
}
