# Pawlease

*Share your day. Keep your pet awake.*

## 1. Project overview

Pawlease is a private social app for a group of two to five close friends who
jointly care for one shared virtual pet. Each day, a member publishes one
photo moment; once they've shared their own moment, their friends' moments
for that day unlock. When at least two distinct members publish, the pet
survives the day and the group's streak continues. Missing a day never kills
the pet or deletes its history — it just puts the pet in a resting state
until someone revives it.

Pawlease is a portfolio-scale iOS application built entirely on Apple-native
frameworks (SwiftUI, Core Data, PhotosUI, and — in a later phase — CloudKit),
using a strict layered architecture (MVVM + Use Cases + Semantic Domain
Models) so business rules stay independent of any UI or persistence
framework.

## 2. Documented domain problem

Young adults who want to maintain close friendships across different study,
work, and living routines often lack a private, low-effort way to stay
involved in one another's everyday lives. Group chats depend on someone
continually restarting the conversation; public social platforms add broad
audiences, self-presentation pressure, and noisy feeds. As a result, ordinary
moments go unshared, and the effort of maintaining a friendship becomes
uneven across a group.

**Pawlease reduces everyday friendship-maintenance friction.** It is not a
tool for treating loneliness or any mental-health condition, and it makes no
such claim.

## 3. Primary stakeholder

> A young adult aged approximately 18–29 who wants to maintain a private
> friendship group of two to five people across different schedules or
> locations.

## 4. Real-world evidence

- Australian Institute of Health and Welfare — *Social isolation and
  loneliness*:
  https://www.aihw.gov.au/mental-health/topic-areas/health-wellbeing/social-isolation-and-loneliness
- Australian Bureau of Statistics — *General Social Survey: Summary Results,
  Australia, 2025*:
  https://www.abs.gov.au/statistics/people/people-and-communities/general-social-survey-summary-results-australia/2025
- Research on socially interactive technology and friendship quality
  (PubMed):
  https://pubmed.ncbi.nlm.nih.gov/28418718/

These sources motivate the product's framing — a private, structured,
low-pressure ritual for staying in touch — without positioning the app as an
intervention for loneliness or mental health.

## 5. Core product rules

1. A member may publish at most one valid daily photo moment per Circle day.
   Publishing again while already having a moment for that day **replaces**
   it (same identity, updated content) rather than creating a duplicate
   contributor.
2. A Circle day is computed from the Circle's own stored time-zone
   identifier, never the device's current time zone.
3. A member must publish their own moment before viewing friends' moments
   for the current Circle day.
4. At least two **distinct** members must publish for the pet to survive the
   day. Multiple posts from the same member still count as one contributor.
5. Missing a day resets the current streak but never deletes pet growth or
   past memories, and the pet is never permanently deleted.
6. Captions and comments are limited to 60 characters.
7. Comments are single-level (no nested replies) and cannot be edited —
   only soft-deleted by their own author. A removed comment keeps its id,
   author, and timestamp, and displays as "Comment removed."
8. A member may have at most one emoji reaction per target (a moment or a
   comment), drawn from a fixed set: ❤️ 😂 🥺 🔥 🐾. Selecting a different
   emoji replaces the reaction; selecting the same emoji again removes it.
9. Comments and reactions never affect contributor count, daily survival
   status, streak, or pet growth points.
10. Contributor count and survival state are always **derived** from posts,
    never a stored, mutable counter — so multiple devices can never
    disagree or double-increment shared state.

## 6. Architecture summary

```
Presentation → Application → Domain ← Data
```

- **Presentation** — SwiftUI Views and `@MainActor @Observable` ViewModels.
- **Application** — focused Use Cases, one responsibility each, depending
  only on Domain repository protocols.
- **Domain** — framework-independent semantic models, value objects,
  repository protocols, and domain errors. Imports only `Foundation`.
- **Data** — Core Data repository implementations and mappers that convert
  between `NSManagedObject` subclasses and Domain structs.
- **Infrastructure** — platform-facing helpers (a clock abstraction, photo
  processing) that sit alongside Data but are consumed by Presentation.

The Domain layer never imports SwiftUI, UIKit, Core Data, CloudKit, or
WidgetKit. The Presentation layer never imports Core Data or touches
`NSManagedObjectContext`/`NSManagedObject` — it only ever sees Use Cases and
Domain models. `NSManagedObject` instances never cross a concurrency
boundary; repositories map to immutable, `Sendable` Domain values inside
`context.perform` before returning.

## 7. MVVM explanation

Every major feature has a focused View and a dedicated `@MainActor
@Observable` ViewModel (`PetHomeViewModel`, `PostComposerViewModel`,
`PostDetailViewModel`). A ViewModel:

- invokes Use Cases and converts their results into presentation-ready
  `ViewState` structs (e.g. `PetHomeViewState`, `PostDetailViewState`);
- owns UI orchestration — loading/error states, sheet/navigation
  presentation, composer text and submission state;
- never fetches or saves Core Data directly, never contains CloudKit code,
  and never implements a core business rule (survival calculation, reaction
  replacement, comment authorization all live in Use Cases).

Views stay small and declarative, use `NavigationStack` and typed
navigation, `.task` for async loading, and `ContentUnavailableView` for
empty/locked/error states.

## 8. Use Case Layer explanation

Each Use Case represents one user intention and depends only on repository
protocols, so it is testable with plain mock objects and no Core Data:

| Use Case | Responsibility |
|---|---|
| `SeedDemoCircleUseCase` | Seeds one local demo Circle (3 members + 1 pet), idempotently |
| `LoadPetHomeUseCase` | Assembles the Pet Home snapshot: care status, activity state, streak |
| `PublishDailyMomentUseCase` | Validates and saves the current member's daily moment (replace-on-duplicate) |
| `CanViewTodayFeedUseCase` | Checks whether a member has posted today |
| `LoadTodayMomentsUseCase` | Loads today's moments, enforcing the post-to-unlock rule |
| `CalculateDailyCareStatusUseCase` | Pure: derives contributor count/survival from a day's moments |
| `CalculatePetStreakUseCase` | Pure: derives the current streak from a day-by-day survival history |
| `LoadMomentDetailUseCase` | Assembles a moment with its comments and all reactions |
| `AddCommentUseCase` | Validates and saves a new comment on a moment |
| `RemoveCommentUseCase` | Soft-deletes a comment, enforcing "own comments only" |
| `ReactToMomentUseCase` | Applies the create/replace/remove reaction rule to a moment |
| `ReactToCommentUseCase` | Applies the same rule to a comment |

## 9. Semantic Domain Model explanation

Core Data entities never leave the Data layer. Instead, the rest of the app
works with framework-independent value/struct types with domain
terminology:

`FriendCircle`, `CircleMember`, `SharedPet`, `DailyMoment`, `MomentComment`,
`MomentReaction`, `CommentReaction`, `CircleDay`, `MomentCaption`,
`CommentBody`, `MomentPhoto`, `ReactionEmoji`, `DailyCareStatus`,
`PetLifeStage`, `PetActivityState`.

Value objects validate themselves at construction (e.g. `MomentCaption` and
`CommentBody` both reject empty or >60-character text by throwing
`DomainValidationError`), so an invalid comment or caption is
unrepresentable once constructed. `ReactionEmoji` is a closed `enum` over
the five supported emoji rather than an arbitrary `String`, so an
unsupported reaction cannot be expressed at all.

## 10. Repository pattern

Domain repository protocols (`CircleRepository`, `MemberRepository`,
`PetRepository`, `MomentRepository`, `CommentRepository`,
`MomentReactionRepository`, `CommentReactionRepository`) are defined in the
Domain layer and implemented in the Data layer as `CoreData*Repository`
types. Each repository maps `NSManagedObject` ⇄ Domain struct and enforces
persistence-level invariants that don't belong in Core Data itself — for
example, "one reaction per member per target" is enforced by upserting on
`(target, member)` rather than by a Core Data unique constraint (Core Data
unique constraints are intentionally avoided everywhere, for CloudKit
compatibility). Repositories always do their work inside
`container.newBackgroundContext()` + `context.perform`, and only ever
return `Sendable` Domain values.

## 11. Chosen extensions and their workflow justification

Not yet implemented (see §16–17) but designed for from the start — the
Core Data schema, App Group identifier, and layering already anticipate
both.

### PawleaseWidget

- Shows the shared pet's current state.
- Shows today's contributor progress (e.g. `1/2`).
- Shows whether the current member has posted yet.
- Deep-links straight into the Post Composer.
- **Why:** the daily ritual only works if it's low-effort. A glanceable
  widget that shows "your friends are waiting on you" and jumps straight to
  the camera removes the friction of opening the app, finding Pet Home, and
  tapping through — directly supporting the product's core promise of
  reducing friendship-maintenance effort.

### PawleaseShareExtension

- Accepts a photo, URL, or text shared from another app.
- Creates a pending Pawlease draft instead of publishing directly.
- Opens the main app so the member can review the photo, add a caption and
  mood, and publish deliberately.
- **Why:** people already have the photo they want to share open in Photos,
  Safari, or another app. Without a share extension they'd have to save the
  item, switch to Pawlease, and find it again — extra steps that work
  against the "quick, low-effort" design goal. The extension never publishes
  directly to CloudKit itself; it only stages a draft, keeping publish-time
  validation and photo processing in one place (the main app).

## 12. Database choice

**Core Data**, via `NSPersistentContainer` today and `NSPersistentCloudKitContainer`
in a later phase. Core Data was chosen over SwiftData because
`NSPersistentCloudKitContainer` + `CKShare` is the only Apple-native path to
private, per-Circle CloudKit sharing among 2–5 specific people — SwiftData's
CloudKit story (as of iOS 17) does not yet support `CKShare`-based
selective sharing. No third-party database or networking library is used
anywhere in the project.

## 13. App Group identifier

```
group.com.lili.pawlease
```

Reserved now so the Widget and Share Extension (added in a later phase) can
share an App Group container with the main app for lightweight state:

- **Widget snapshot** — a small, precomputed read model (pet state, `1/2`
  progress, "you've posted today" flag) written by the main app after every
  relevant change, so the widget never has to open the full Core Data stack
  or perform CloudKit sync itself.
- **Pending Share Extension drafts** — a photo/URL/text payload staged by
  the Share Extension for the main app to pick up, review, and publish.

## 14. Setup instructions

1. Open `Pawlease.xcodeproj` in Xcode 26 or later.
2. Select the `Pawlease` scheme and any iOS 17+ simulator (or a physical
   device with a development team configured).
3. Build and run (`⌘R`). The app seeds one local demo Circle — "The Pack,"
   3 members, 1 pet — on first launch. The current device simulates the
   first seeded member ("You").
4. No API keys, secrets, or external services are required for this phase;
   everything is local-first Core Data.

## 15. Testing strategy

- **Swift Testing** for all Domain/Application/Data unit tests;
  **XCTest** only where UI testing requires it (`PawleaseUITests`).
- **Domain tests** (`PawleaseTests/Domain`) — pure value-object validation
  (`MomentCaptionTests`, `CommentBodyTests`, `CircleDayTests`), no
  repositories involved.
- **Application tests** (`PawleaseTests/Application`) — Use Cases exercised
  against either lightweight in-memory fakes (`InMemory*Repository`, used
  for the original Phase 1 flows) or fully configurable mocks
  (`Mock*Repository`, used for the comments/reactions feature) that support
  stubbed results, injected errors, captured arguments, and invocation
  counts. No Core Data or CloudKit involved.
- **Data tests** (`PawleaseTests/Data`) — integration tests against a real,
  **in-memory** Core Data stack (`PersistenceController(inMemory: true)`),
  proving the schema, mappers, and repositories work end to end. These are
  clearly separate from, and not counted among, the mock-based unit tests.
- **UI tests** (`PawleaseUITests`) — a real interactive tap-through of the
  golden path (seeded Circle visible → open Composer → Publish gated on
  valid input → Cancel returns to Pet Home) plus a launch-performance test.

Run everything with:

```sh
xcodebuild -project Pawlease.xcodeproj -scheme Pawlease \
  -destination 'id=<simulator-udid>' test
```

## 16. Current implementation status

**Implemented:**

- Local-first Core Data stack (`NSPersistentContainer`), full schema for
  Circles, Members, Pets, Daily Posts, Comments, Post Reactions, and Comment
  Reactions.
- Semantic Domain Models and value objects for every entity above.
- Repository protocols + Core Data repository implementations for all of
  the above.
- Use Cases for seeding, publishing, feed unlocking, care-status/streak
  calculation, comments, and reactions.
- Pet Home (seeded Circle, streak, `1/2` contributor progress, locked/
  unlocked feed), Post Composer (`PhotosPicker`, caption, mood, publish),
  Today Feed, and Post Detail (full photo, caption, mood, moment reactions,
  chronological comments with their own reactions, comment composer,
  soft-delete for your own comments) screens, each with a dedicated MVVM
  ViewModel.
- Accessibility: Dynamic Type–friendly text styles, semantic colors,
  VoiceOver labels/hints on the pet status, progress, photo button, and
  reaction controls, `ContentUnavailableView` for empty/locked/error states.

**Not yet implemented:** CloudKit sync, `CKShare`, the Widget extension, the
Share extension, the memory calendar, and final pet artwork/animations —
see §17.

## 17. Planned features

- **`feature/cloudkit-circle-sharing`** — switch to
  `NSPersistentCloudKitContainer` with private + shared stores, a `CKShare`
  proof of concept for 2–5 members, two-device sharing verification, and
  CloudKit account/error states.
- **PawleaseWidget** — see §11.
- **PawleaseShareExtension** — see §11.
- Memory calendar (browsing past Circle days and their moments).
- Final pet artwork and stage-transition animations.
