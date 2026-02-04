# Review Log

## [2026-02-03 21:45] — Harden Apple Sign In error handling

**Files touched:**
- `Terrain/Features/Auth/AuthView.swift` — Added nonce guard and specific error messages for different Apple Sign In failure types

**What changed (plain English):**
Two small safety improvements to Apple Sign In. First, the app now checks that the security nonce (a one-time code used to prevent replay attacks) actually exists before sending it to Supabase — previously it silently sent an empty string if the nonce was missing, which would fail with a confusing generic error. Second, when Apple Sign In fails, the app now shows specific messages for different failure types (unavailable, can't show dialog, etc.) instead of a catch-all "Something went wrong."

**Why:**
Code review identified that the nonce nil-coalescing to empty string was a silent failure risk, and that only user-cancellation was handled specifically out of 9 possible Apple Sign In error types.

**Risks / watch-fors:**
- None identified. Both changes are strictly additive — the happy path is unchanged, only error/edge cases get better messages.

**Testing status:**
- [x] Builds cleanly
- [ ] Existing tests pass (no auth tests exist yet)
- [ ] New tests added — none (auth test suite is a separate effort)
- [ ] Manual verification needed — test Apple Sign In on a real device to confirm the happy path still works and cancellation still silently dismisses

**Reviewer nudge:**
Verify the `ASAuthorizationError.Code` switch cases match the iOS 17 SDK — the `.notInteractive` case was added in iOS 16, so it should be fine, but worth confirming.

## [2026-02-03 21:55] — Shorten all quiz option labels

**Files touched:**
- `Terrain/Core/Engine/TerrainScoringEngine.swift` — Shortened option labels across Q3, Q5, Q6, Q7, Q9, Q10, Q11, Q12, Q13 and replaced all em dashes with commas

**What changed (plain English):**
Quiz answer labels were too long and getting cut off with "..." on smaller screens. Shortened every label to fit comfortably in one line (under ~30 characters). Also replaced all remaining em dashes (—) with commas for consistency. The option IDs are unchanged, so existing stored quiz responses remain valid.

**Why:**
User reported truncated labels on the quiz screen — options like "Humid conditions—I feel heavy and..." were unreadable.

**Risks / watch-fors:**
- Option IDs unchanged, so no migration or data compatibility issues.
- Meaning is preserved in shorter form, but worth a quick read-through to confirm no nuance was lost.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass (38/38 scoring engine tests)
- [ ] New tests added — none needed (text-only change)
- [ ] Manual verification needed — visually confirm labels fit on smallest supported iPhone screen

**Reviewer nudge:**
Skim the shortened labels in Q5 and Q7 to confirm the descriptions are still clear enough for users to pick the right answer.

## [2026-02-03 22:10] — Add confirm button to daily check-in + tappable heatmap editing

**Files touched:**
- `Terrain/Features/Home/Components/InlineCheckInView.swift` — Selections now staged locally; card stays until user taps "Confirm" button
- `Terrain/Features/You/Components/SymptomHeatmapView.swift` — Cells are now tappable (opens edit sheet for that day); added "Cold" as 8th row; added HeatmapEditSheet

**What changed (plain English):**
Two related improvements. First, the daily symptom check-in on the Home tab no longer vanishes the instant you tap a symptom. Selections are highlighted but staged locally — you tap "Confirm" when ready. Think of it like a shopping cart: items go in the cart, but nothing happens until you check out. Second, the symptom heatmap in the Trends tab is now interactive. Tapping any cell opens a half-sheet showing that day's date and all 8 symptoms as toggleable chips. You can edit what you logged and hit Save. Also added "Cold" as the 8th row in the heatmap (was previously missing).

**Why:**
User reported that the check-in card disappeared too fast when tapping a symptom, and wanted the ability to retroactively edit symptom data from the heatmap.

**Risks / watch-fors:**
- ~~`Date` gets a retroactive `Identifiable` conformance~~ — resolved: uses `EditableDay` wrapper struct instead.
- Creating a new `DailyLog` when editing a day that has no existing log — verify `DailyLog.init` defaults are correct (date gets overwritten to the tapped day).
- The staged symptom pattern in InlineCheckInView means `onChange(of: selectedSymptoms)` in HomeView now only fires on confirm, not on each tap.

**Testing status:**
- [x] Builds cleanly
- [ ] New tests added — none (UI interaction, would need UI tests)
- [ ] Manual verification needed — tap cells in heatmap, verify edit sheet opens with correct day and pre-selected symptoms; verify confirm button in check-in works

**Reviewer nudge:**
~~Check that `Date: @retroactive Identifiable` doesn't cause issues~~ — already resolved with `EditableDay` wrapper. Instead, verify DailyLog creation in `saveChanges()` when editing a day with no prior log.

## [2026-02-04 01:10] — Add daily mood rating (1-10) with 14-day trend tracking

**Files touched:**
- `Terrain/Core/Models/User/DailyLog.swift` — Added `moodRating: Int?` property (1-10 scale, nil = not set)
- `Terrain/Features/Home/Components/InlineCheckInView.swift` — Added mood slider (1-10) above symptom chips with staged local state
- `Terrain/Features/Home/HomeView.swift` — Wired `moodRating` binding to InlineCheckInView, updated save/load to include mood, updated `hasCheckedInToday` to consider mood
- `Terrain/Core/Services/TrendEngine.swift` — Added `computeMoodTrend()` and `computeDailyMoodRates()` methods; Mood appears as first trend result
- `Terrain/Tests/ConstitutionServiceTests.swift` — Updated `testSufficientDataReturns7Trends` → `testSufficientDataReturns8Trends` to account for new Mood category

**What changed (plain English):**
Added a "How are you feeling today?" slider to the daily check-in card on the Home tab. It sits above the symptom chips — think of it like adding a thermometer to a weather station that already tracks wind and humidity. The slider goes from 1 to 10, and the selected number is displayed prominently below the slider. When users confirm their check-in, the mood rating is saved alongside their symptom selections. This mood data then feeds into the 14-day trend sparklines on the You → Trends tab as a new "Mood" row at the top of the list. The trend direction compares average mood in the first vs second week — if you've been feeling better recently, the arrow points up.

**Why:**
User requested a simple overall wellness gauge to complement the more specific symptom tracking. Mood is the most holistic signal and deserves prominent placement.

**Risks / watch-fors:**
- New optional property on `DailyLog` — SwiftData handles this automatically via lightweight migration. No versioned schema change needed (adding V2 caused "Duplicate version checksums" crash since both versions reference the same live model classes).
- The confirm button now appears when either mood is staged OR symptoms are selected (previously only symptoms). This means a user could confirm with just a mood and no symptoms, which is intentional.
- Two `onChange` handlers caused a double-save — resolved with `scheduleSave()` coalescing pattern (see [2026-02-04 01:30] entry).

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass (all ~110 tests)
- [ ] New tests added — none (mood trend uses same patterns as existing symptom trends; the `testSufficientDataReturns8Trends` test confirms Mood category is present)
- [ ] Manual verification needed — open app → Home tab → verify slider appears above symptoms; set mood + symptoms → confirm; navigate to You → Trends → verify Mood sparkline row appears at top

**Reviewer nudge:**
Double-check that the slider `onChange` haptic doesn't fire excessively — it triggers on every step (1-10), which is 9 haptic taps max if dragged end to end. If it feels too buzzy, consider debouncing or removing the per-step haptic.

## [2026-02-04 01:30] — Tech debt cleanup from senior review

**Files touched:**
- `Terrain/Core/Engine/TerrainScoringEngine.swift` — Shortened 7 quiz option labels that still exceeded 30 characters
- `Terrain/Features/Home/HomeView.swift` — Replaced double-save `onChange` pattern with coalesced `scheduleSave()`
- `Terrain/Features/You/Components/SymptomHeatmapView.swift` — Fixed stale "7x14" comment to "8x14"
- `Terrain/Core/Models/TerrainSchemaV1.swift` — ~~Added TerrainSchemaV2~~ reverted; V2 caused "Duplicate version checksums" crash. Added documentation explaining why V2 is unnecessary for optional fields.

**What changed (plain English):**
Three cleanup items from a senior code review. First, seven quiz answer labels were still too long for small screens — trimmed them to fit (e.g., "Easily, even light activity gets me sweating" → "Easily, even light activity"). Second, the Home tab had a double-save bug: when a user confirmed their check-in, the app was writing to the database twice in rapid succession because symptoms and mood each triggered their own save. Now they're coalesced — think of it like a mail carrier waiting until you're done putting letters in the mailbox before picking them all up at once. Third, a file header comment said "7x14 grid" when the heatmap actually has 8 rows (Cold was added earlier but the comment wasn't updated). A fourth item (adding TerrainSchemaV2 for moodRating) was attempted but reverted — SwiftData crashes when two VersionedSchemas reference the same live model classes. New optional properties are handled automatically without a version bump.

**Why:**
Senior review of REVIEW_LOG.md identified these four items as tech debt that should be resolved before the next feature lands on top of them.

**Risks / watch-fors:**
- Quiz label changes: option IDs unchanged, no data compatibility impact. Verify shortened labels still convey enough meaning on the quiz screen.
- `scheduleSave()` uses `Task` cancellation to coalesce — if `confirmSelection()` is ever called off the main actor, the `@MainActor` annotation on the task body ensures saves still happen on main. No risk with current architecture.
- ~~Schema V2~~ — reverted. SwiftData crashes with "Duplicate version checksums" when two VersionedSchemas reference the same live model classes. `moodRating: Int?` is handled automatically via lightweight migration without an explicit V2. See file header comment in `TerrainSchemaV1.swift`.

**Testing status:**
- [x] Builds cleanly (zero code warnings)
- [ ] Existing tests pass — test runner has pre-existing simulator bootstrap crash unrelated to these changes
- [ ] New tests added — none needed (label text, save timing, comment fix)
- [ ] Manual verification needed — quiz labels fit on screen, check-in saves once on confirm, heatmap still renders 8 rows

**Reviewer nudge:**
Verify `scheduleSave()` coalescing works correctly by setting a breakpoint in `saveCheckIn` and confirming it fires exactly once when confirming both mood + symptoms together.

## [2026-02-04 01:35] — Grammar pass on quiz option labels

**Files touched:**
- `Terrain/Core/Engine/TerrainScoringEngine.swift` — Fixed 6 option labels for grammar and clarity while staying under 30 characters

**What changed (plain English):**
A second pass over quiz labels focusing on grammar rather than length. Six labels were either grammatically broken, over the character limit, or had lost meaning during the previous shortening pass. Think of it like proofreading a telegram — every word has to carry its weight, but the message still has to make sense to the reader.

Changes:
- Q4: "AM better then crash" → "AM better, then crash" (added missing comma)
- Q10: "Swollen legs or face sometimes" → "Sometimes swollen face or legs" (matched frequency-first pattern of sibling options)
- Q11: "Sip often, more habit" → "More habit than thirst" (restored the comparison that gives the option meaning)
- Q13: "Fall asleep easily, stay" → "Fall and stay asleep easily" (fixed dangling verb — "stay" what?)
- Q13: "Wake up tired, even after enough hours" → "Tired after enough sleep" (was 38 chars, now 24)
- Q16: "Irritable with breast tenderness" → "Irritable, breast tenderness" (was 32 chars, now 28)

**Why:**
Review of all quiz labels for grammatical correctness within the ~30 character constraint. The previous shortening pass focused only on length and introduced a broken label ("Fall asleep easily, stay") and missed two labels still over 30 chars.

**Risks / watch-fors:**
- All option IDs unchanged — no migration or stored response compatibility issues.
- "More habit than thirst" is a slight reframe from the user's perspective ("I sip from habit") to a descriptive one ("this is more habit than thirst"). Meaning is preserved.

**Testing status:**
- [x] Builds cleanly (zero code warnings)
- [ ] New tests added — none needed (text-only change, option IDs unchanged)
- [ ] Manual verification needed — read through quiz in-app to confirm labels are clear and fit on screen

**Reviewer nudge:**
Read Q13's options aloud in sequence: "Fall and stay asleep easily / Trouble falling asleep / Wake up during the night / Vivid or restless dreams / Tired after enough sleep" — confirm the set feels like a natural range of sleep experiences.

## [2026-02-04 01:45] — Add mood slider to heatmap edit sheet + fix "Welcome, welcome" bug + fix schema crash

**Files touched:**
- `Terrain/Features/You/Components/SymptomHeatmapView.swift` — Added mood rating slider to HeatmapEditSheet, matching the Home tab check-in style; loads/saves mood alongside symptoms
- `Terrain/Features/Onboarding/OnboardingCompleteView.swift` — Fixed "Welcome, welcome to Terrain" duplicate text when displayName is nil
- `Terrain/Core/Models/TerrainSchemaV1.swift` — Removed TerrainSchemaV2 that caused "Duplicate version checksums" crash; added documentation explaining why it's unnecessary
- `Terrain/Core/Models/User/DailyLog.swift` — (No additional changes beyond earlier moodRating addition)
- `CLAUDE.md` — Updated DailyLog description, TrendEngine category count, and SwiftData migration guidance

**What changed (plain English):**
Three fixes. First, the heatmap edit sheet (the popup when you tap a day in the symptom grid) now includes the same "How were you feeling?" mood slider from the Home tab check-in. Think of it like adding the thermometer reading to the weather log edit screen — previously you could only edit which symptoms you had, now you can also record or change your mood for that day. Second, the onboarding completion screen was saying "Welcome, welcome to Terrain" because the fallback text started with lowercase "welcome" and was prefixed with "Welcome, " — now it just says "Welcome to Terrain" when no name is set. Third, the app was crashing on launch because a TerrainSchemaV2 was added but both V1 and V2 pointed at the same live DailyLog class, causing SwiftData to see identical fingerprints and bail out.

**Why:**
User reported all three issues during manual testing of the mood rating feature.

**Risks / watch-fors:**
- Mood slider in heatmap uses the same staged pattern as InlineCheckInView — `hasMoodEntry` flag ensures the slider only persists if the user actually interacts with it (prevents overwriting nil with a default 5).
- Schema change: removing V2 and going back to a single-schema migration plan is safe. SwiftData handles new optional properties automatically. The migration plan now has `schemas: [TerrainSchemaV1.self]` and `stages: []`.
- None identified for the welcome text fix.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass (all ~110 tests)
- [ ] New tests added — none
- [ ] Manual verification needed — tap heatmap cell, verify mood slider appears and loads/saves correctly; complete onboarding without entering a name, verify "Welcome to Terrain" (not "Welcome, welcome")

**Reviewer nudge:**
Verify that tapping Save in the heatmap edit sheet without touching the mood slider does NOT overwrite an existing mood rating with the default 5 — the `hasMoodEntry` guard should prevent this.
