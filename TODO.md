# TODO - Terrain iOS App

Last updated: 2025-01-28

## High Priority (Wire Existing UI to Data)

### Learn Tab - Wire to Content Pack
**File**: `Terrain/Features/Learn/LearnView.swift`
**Status**: UI complete with mock data
**Task**:
- Replace hardcoded `topics` array with `@Query` from SwiftData
- Load lessons from `base-content-pack.json` via ContentPackService
- Add navigation to lesson detail view
- Show lesson body blocks (paragraph, bullets, callout)

### Ingredients Tab - Wire to Content Pack
**File**: `Terrain/Features/Ingredients/IngredientsView.swift`
**Status**: UI complete with mock data
**Task**:
- Replace mock ingredients with `@Query` from SwiftData
- Implement search filtering on ingredient names
- Implement category filtering
- Add ingredient detail view with:
  - Why it helps (plain + TCM)
  - How to use (quick uses)
  - Cautions
  - Cultural context
- Wire "Add to Cabinet" functionality to UserCabinet model

### Right Now Tab - Wire Quick Suggestions
**File**: `Terrain/Features/RightNow/RightNowView.swift`
**Status**: UI complete with static suggestions
**Task**:
- Create suggestion engine based on user's terrain + time of day
- Pull routines/ingredients from content pack that match need
- Implement "Avoid Timer" feature (avoid cold drinks for N hours)

## Medium Priority (Content & Features)

### Expand Content Pack
**File**: `Terrain/Resources/ContentPacks/base-content-pack.json`
**Current**: 13 ingredients, 2 routines, 1 movement, 6 lessons, 3 terrain profiles
**Task**:
- Add remaining 5 terrain profiles (Cold+Balanced, Neutral+Deficient, Neutral+Excess, Warm+Balanced, Warm+Deficient)
- Add 10+ more routines covering different terrain types
- Add 5+ more movements (evening wind-down, stress relief, etc.)
- Add lessons for each Learn topic category

### Programs Feature
**Files**: `Terrain/Core/Models/Content/Program.swift` (model exists)
**Status**: Model defined, no UI
**Task**:
- Create ProgramsView to browse available programs
- Create ProgramDetailView showing day-by-day plan
- Create ActiveProgramView for tracking progress through a program
- Add program enrollment to UserProfile

### Daily Log Persistence
**Files**: `Terrain/Features/Today/DailyCheckInSheet.swift`, `Terrain/Core/Models/User/DailyLog.swift`
**Status**: UI works but doesn't save to SwiftData
**Task**:
- Save check-in responses to DailyLog model
- Update ProgressRecord with completion data
- Show historical check-in data in Progress tab

## Low Priority (Polish & Backend)

### Supabase Integration
**Task**:
- Set up Supabase project
- Create tables matching SwiftData models
- Implement SyncService for bidirectional sync
- Add authentication flow

### Weather Integration
**Task**:
- Integrate Apple WeatherKit
- Cache weather in DailyLog
- Adjust recommendations based on weather (cold day → warming routines)

### TestFlight Deployment
**Prerequisites**: Apple Developer Program ($99/year)
**Task**:
- Configure signing & capabilities in Xcode
- Create App Store Connect record
- Archive and upload to TestFlight
- Set up internal testing group

### Accessibility
**Task**:
- Audit VoiceOver support
- Add accessibility labels to custom components
- Test with Dynamic Type
- Ensure color contrast meets WCAG AA

## Bugs / Known Issues

- None currently tracked

## Completed (This Session - 2025-01-28)

- [x] Fix compilation errors (ProgressView rename, LocalizedString DTO, MediaType)
- [x] Implement "Retake Quiz" button with confirmation dialog
- [x] Add smooth animations to Movement Player (frame transitions, pulsing play button)
- [x] Persist notification preferences to UserProfile
- [x] Expand content pack (8 new ingredients, 5 new lessons)
- [x] Create Xcode project for simulator builds
- [x] Update CLAUDE.md with current project status
- [x] Create this TODO.md

## Reference Files

- `PRD - TCM App.rtf` - Full product requirements
- `Content Schema JSON.rtf` - JSON schema for content packs
- `Terrain Scoring Table.rtf` - Quiz scoring algorithm
- `Copy for Terrain Types.rtf` - Copy for all terrain types
