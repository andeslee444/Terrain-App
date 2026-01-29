# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Terrain** is a TCM (Traditional Chinese Medicine) daily rituals iOS app built with SwiftUI and SwiftData. The app determines a user's "Terrain" (body constitution) through a quiz, then delivers personalized daily routines.

**Status**: MVP implemented - onboarding, Today tab, and core features working
**Positioning**: "Co-Star clarity + Muji calm" for TCM lifestyle routines
**Target User**: Female-skewing, 19-35, astrology-influenced identity seeker, health-conscious
**Platform**: iOS 17+ (iPhone)

## Quick Start

```bash
# Open in Xcode and run on simulator
cd Terrain
open Terrain.xcodeproj
# Then press Cmd+R in Xcode

# Or build from command line
cd Terrain
xcodebuild -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug build

# Install on running simulator
xcrun simctl install booted build/Debug-iphonesimulator/Terrain.app
xcrun simctl launch booted com.terrain.app
```

## Repository Structure

```
TCM/
├── CLAUDE.md                    # This file - AI assistant guidance
├── Terrain/                     # iOS App (SwiftUI + SwiftData)
│   ├── Terrain.xcodeproj/       # Xcode project
│   ├── Package.swift            # SPM for library builds/tests
│   ├── App/                     # Entry point, MainTabView
│   ├── Core/
│   │   ├── Models/              # SwiftData models
│   │   │   ├── Content/         # Ingredient, Routine, Movement, Lesson, Program, TerrainProfile
│   │   │   ├── User/            # UserProfile, UserCabinet, DailyLog, ProgressRecord
│   │   │   └── Shared/          # LocalizedString, Tags, SafetyFlags, MediaAsset
│   │   ├── Engine/              # TerrainScoringEngine
│   │   └── Services/            # ContentPackService
│   ├── Features/
│   │   ├── Onboarding/          # 7-screen flow: Welcome → Goals → Quiz → Reveal → Safety → Notifications
│   │   ├── Today/               # Daily routine, movement player, check-in
│   │   ├── RightNow/            # Quick fixes (UI done, data not wired)
│   │   ├── Ingredients/         # Cabinet view (UI done, data not wired)
│   │   ├── Learn/               # Field Guide (UI done, data not wired)
│   │   └── Progress/            # Streaks, calendar, retake quiz
│   ├── DesignSystem/
│   │   ├── Theme/               # TerrainTheme (colors, typography, spacing, animation)
│   │   └── Components/          # TerrainButton, TerrainCard, TerrainTextField
│   ├── Resources/
│   │   └── ContentPacks/        # base-content-pack.json (13 ingredients, 6 lessons)
│   └── Tests/                   # Unit tests for scoring engine and content parsing
├── PRD - TCM App.rtf            # Product requirements document
├── Content Schema JSON.rtf      # JSON schema for content packs
├── Terrain Scoring Table.rtf    # Quiz scoring algorithm
└── Copy for Terrain Types.rtf   # Copy templates for terrain types
```

## What's Implemented

### Complete (Production-Ready)
- **Onboarding flow**: All 7 screens with animations
- **Terrain Scoring Engine**: 12 questions → 8 types + 5 modifiers (fully tested)
- **Terrain Reveal**: Animated reveal with superpower/trap/ritual
- **Today Tab**: Routine capsule, level selector (Full/Lite/Minimum)
- **Movement Player**: Frame-by-frame with timer, play/pause, auto-advance
- **Routine Detail Sheet**: Step-by-step with timers
- **Daily Check-In**: Symptoms, onset, energy tracking
- **Progress Tab**: Streaks, calendar, retake quiz button
- **Design System**: Muji-calm theme, all core components
- **Content Pack Loader**: JSON → SwiftData with DTOs
- **Notification Scheduling**: Morning/evening reminders

### UI Done, Data Not Wired
- **Right Now Tab**: 6 quick-need cards (structure only)
- **Ingredients Tab**: Search, filters, grid (mock data)
- **Learn Tab**: Topic categories, lesson cards (mock data)

### Not Started
- Supabase backend sync
- Weather API integration
- Programs (multi-day guided routines)
- Push notification service

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Min iOS | 17.0 | Required for SwiftData, Observation framework |
| Architecture | MVVM + Coordinators | Clean separation, testable |
| State | @Observable + @AppStorage | Modern Swift concurrency |
| Persistence | SwiftData | Native, simpler than Core Data |
| Content | Bundled JSON | Offline-first, fast startup |

## Terrain System

### 5 Scoring Axes
- `cold_heat`: -10 to +10 (cold ↔ heat)
- `def_excess`: -10 to +10 (deficient ↔ excess)
- `damp_dry`: -10 to +10 (damp ↔ dry)
- `qi_stagnation`: 0 to +10 (stuck energy)
- `shen_unsettled`: 0 to +10 (restless mind/sleep)

### 8 Primary Types
| Type | Nickname | Thresholds |
|------|----------|------------|
| Cold + Deficient | Low Flame | cold ≤ -3, def ≤ -3 |
| Cold + Balanced | Cool Core | cold ≤ -3, -2 ≤ def ≤ 2 |
| Neutral + Deficient | Low Battery | -2 ≤ cold ≤ 2, def ≤ -3 |
| Neutral + Balanced | Steady Core | -2 ≤ cold ≤ 2, -2 ≤ def ≤ 2 |
| Neutral + Excess | Busy Mind | -2 ≤ cold ≤ 2, def ≥ 3 |
| Warm + Balanced | High Flame | cold ≥ 3, -2 ≤ def ≤ 2 |
| Warm + Excess | Overclocked | cold ≥ 3, def ≥ 3 |
| Warm + Deficient | Bright but Thin | cold ≥ 3, def ≤ -3 |

### 5 Modifiers (priority: Shen > Stagnation > Damp/Dry)
- **Shen (Restless)**: shen_unsettled ≥ 4
- **Stagnation (Stuck)**: qi_stagnation ≥ 4
- **Damp (Heavy)**: damp_dry ≤ -3
- **Dry (Thirsty)**: damp_dry ≥ 3
- **None**: No threshold met

## Design System

### Colors (Muji Calm)
- Background: `#FAFAF8` (warm off-white)
- Text Primary: `#1A1A1A` (near-black)
- Accent: `#8B7355` (warm brown)
- Success: `#7A9E7E`, Warning: `#C9A96E`, Error: `#C97E7E`

### Spacing (8pt base)
`xxs(4) → xs(8) → sm(12) → md(16) → lg(24) → xl(32) → xxl(48) → xxxl(64)`

### Animation
- Quick: 0.15s (micro-interactions)
- Standard: 0.3s (transitions)
- Reveal: 0.5s (signature moments)

## Content Tone
- Muji-calm, chic, informational
- Short sentences, gentle confidence
- Never say "diagnosis" - use "profile," "terrain," "pattern"
- Surface human terms; expand with TCM via tooltips

## Testing

```bash
# Build for simulator (validates compilation)
cd Terrain
swift build --sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  --triple arm64-apple-ios17.0-simulator

# Run unit tests (requires Xcode)
xcodebuild test -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Next Steps (See TODO.md)

1. Wire Learn tab to content pack lessons
2. Wire Ingredients tab to content pack ingredients
3. Add more terrain profiles to content pack
4. Implement Programs feature
5. Set up Supabase for sync
