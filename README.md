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
frameworks (SwiftUI, Core Data, PhotosUI, and CloudKit for private Circle
sharing), using a strict layered architecture (MVVM + Use Cases + Semantic
Domain Models) so business rules stay independent of any UI or persistence
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

**Core Data**, via `NSPersistentCloudKitContainer`. Core Data was chosen over
SwiftData because `NSPersistentCloudKitContainer` + `CKShare` is the only
Apple-native path to private, per-Circle CloudKit sharing among 2–5 specific
people — SwiftData's CloudKit story (as of iOS 17) does not yet support
`CKShare`-based selective sharing. No third-party database or networking
library is used anywhere in the project.

## 13. CloudKit setup and sharing architecture

### Identifiers

```
App bundle identifier:  com.lili.Pawlease
CloudKit container:     iCloud.com.lili.Pawlease
Required Developer Team: 4BZG6CR5HT
```

### Capabilities configured in this repo

- `Pawlease/App/Pawlease.entitlements` declares
  `com.apple.developer.icloud-container-identifiers` (`iCloud.com.lili.Pawlease`),
  `com.apple.developer.icloud-services` (`CloudKit`), and `aps-environment`
  (`development`, required for the silent push that drives CloudKit
  background sync).
- `CODE_SIGN_ENTITLEMENTS` points the `Pawlease` target at that file (Debug
  and Release).
- `INFOPLIST_KEY_CKSharingSupported = YES` — required for the app to accept
  incoming `CKShare` invitations at all.
- `INFOPLIST_KEY_UIBackgroundModes = "remote-notification"` — the background
  mode that lets CloudKit deliver mirroring pushes while the app isn't in
  the foreground.

### What still requires manual Developer Portal / Xcode action

Building for a real device (`xcodebuild ... -destination 'generic/platform=iOS'`)
in this environment fails at the provisioning step with:

```
error: Provisioning profile "iOS Team Provisioning Profile: com.lili.Pawlease"
       doesn't include the Push Notifications capability.
error: Provisioning profile "iOS Team Provisioning Profile: com.lili.Pawlease"
       doesn't include the iCloud capability.
error: Provisioning profile "iOS Team Provisioning Profile: com.lili.Pawlease"
       doesn't support the iCloud.com.lili.Pawlease iCloud Container.
```

This confirms Team `4BZG6CR5HT` is real and reachable (Xcode already has an
auto-generated provisioning profile for `com.lili.Pawlease` under it), but
that profile predates this feature and doesn't yet include the iCloud/Push
capabilities or the `iCloud.com.lili.Pawlease` container. **To finish this**,
someone with access to that Developer Team must, once, in Xcode:

1. Open `Pawlease.xcodeproj` → select the `Pawlease` target → **Signing &
   Capabilities**.
2. Confirm **Team** is set to the account owning `4BZG6CR5HT` and **Automatically
   manage signing** is on.
3. Click **+ Capability** → add **iCloud** → check **CloudKit** → under
   **Containers**, add (or select, if it already exists) `iCloud.com.lili.Pawlease`.
4. Click **+ Capability** → add **Push Notifications**.
5. Click **+ Capability** → add **Background Modes** → check **Remote
   notifications** (this mirrors the `UIBackgroundModes` build setting
   already in the project; Xcode will not duplicate it).
6. Let Xcode regenerate the provisioning profile (automatic with "Automatically
   manage signing" on), then build for a real device or a signed simulator
   run.
7. In [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/),
   confirm the `iCloud.com.lili.Pawlease` container exists under that team
   in the **Development** environment (Xcode creates it automatically the
   first time step 3 succeeds, if it doesn't already exist).

No code change is needed for this — it is purely Developer Portal /
provisioning-profile state that can't be created from this environment
without an authenticated, interactive Xcode session.

### Private and Shared store architecture

`PersistenceController` (`Pawlease/Data/Persistence/PersistenceController.swift`)
configures `NSPersistentCloudKitContainer` with two persistent stores, matching
two named Core Data model configurations:

| Store | Configuration | CloudKit scope | Entities |
|---|---|---|---|
| `Private.sqlite` | `Private` | `.private` | `UserProfileEntity`, `PendingPostDraftEntity` — never shared, syncs privately across the signed-in user's own devices |
| `Shared.sqlite` | `Shared` | `.shared` | `CircleEntity`, `MemberEntity`, `PetEntity`, `DailyPostEntity`, `CommentEntity`, `PostReactionEntity`, `CommentReactionEntity` — the Circle graph |

Both descriptions enable persistent history tracking
(`NSPersistentHistoryTrackingKey`) and remote change notifications
(`NSPersistentStoreRemoteChangeNotificationPostOptionKey`). `viewContext.automaticallyMergesChangesFromParent = true`,
with `NSMergeByPropertyObjectTrumpMergePolicy` — local edits win on
conflicting properties, so an optimistically-saved local moment stays
visible even if a stale CloudKit import races it, while still merging in
new remote data for properties the local save didn't touch. Core Data
unique constraints are intentionally never used anywhere in the model, for
CloudKit compatibility.

**A known, honestly-documented limitation:** per Apple's `NSPersistentCloudKitContainer`
sharing model, a `.shared`-scope store is populated by *accepted invitations*
— it has no CloudKit zone of its own to originate brand-new records into.
This repo's `Shared` configuration is used for both "a Circle I own" and "a
Circle I joined," which follows this feature's literal, explicit design
brief but has **not been verified against real CloudKit** (see §17). A
production hardening pass would likely adopt Apple's dual-scope-same-
configuration pattern (one configuration loaded by both a `.private`-scope
store, for owned/not-yet-shared objects, and a `.shared`-scope store, for
joined ones) — see `CloudKitCircleSharingRepository.swift` for the code
comment tracking this.

### How CKShare invitations work

1. **Preparing an invitation** (`PrepareCircleInvitationUseCase` →
   `CloudKitCircleSharingRepository.prepareShare(circleID:)`): checks the
   iCloud account is `.available`, fetches the Circle's `NSManagedObject`
   on `viewContext` (required — `NSPersistentCloudKitContainer.share(_:to:)`
   takes live managed objects, matching Apple's own sample code), and
   checks for an existing `CKShare` via `fetchShares(matching:)`. If one
   exists it's reused (`PreparedCircleShare(isNewShare: false)`) — never
   duplicated. Otherwise `container.share([circleObject], to: nil)` creates
   one, its title is set to "Pawlease Circle", and it's saved via
   `CKContainer.privateCloudDatabase.save(share)`.
2. **Presenting the sheet**: the ViewModel only ever produces a `UUID`
   (`preparedCircleID`) — never a `CKShare`. `CircleSettingsView` reacts to
   that by asking the Infrastructure-layer `CloudSharingControllerProvider`
   (`Data/CloudKit/CloudKitSharingControllerProvider.swift`) for an actual
   `UICloudSharingController`, which it presents via a thin
   `UIViewControllerRepresentable`. This is Apple's native sharing UI,
   unmodified — no custom invitation screen replaces it.
3. **Reporting the outcome**: `UICloudSharingControllerDelegate` callbacks
   (`cloudSharingControllerDidSaveShare`, `cloudSharingControllerDidStopSharing`,
   `failedToSaveShareWithError`) are mapped to the Domain-safe
   `CloudSharingOutcome` enum (`.saved` / `.stoppedSharing` / `.failed` /
   `.cancelled`) before reaching the ViewModel. Sheet dismissal without any
   delegate callback firing is reported as `.cancelled`, distinct from a
   reported failure.
4. **Accepting an invitation**: `PawleaseAppDelegate.application(_:userDidAcceptCloudKitShareWith:)`
   stages the delivered `CKShare.Metadata` in `ShareAcceptanceCoordinator`
   (no acceptance logic in the AppDelegate itself). The next time the app
   becomes active, `PawleaseApp` checks for a staged invitation and calls
   `AcceptCircleInvitationUseCase`, which asks
   `CloudKitCircleSharingRepository.acceptPendingInvitation()` to call
   `NSPersistentCloudKitContainer.acceptShareInvitations(from:into:)`
   against the `Shared`-configuration store. Failure is reported (printed;
   surfaced to the UI on the next Circle Settings load) without touching
   any existing local Circle data.

### CloudKit error mapping

`CircleSharingErrorMapping.map(_:)` (`Data/CloudKit/CircleSharingErrorMapping.swift`)
is the single place `CKError.Code` is inspected — it maps network/rate-limit/
service-unavailable/zone/already-shared errors into the semantic
`CircleSharingError` enum. Nothing above the Data layer ever sees a
`CKError`. Rate-limited operations are surfaced as a retryable message, not
retried in a tight loop.

### CloudKit Dashboard (development environment)

Once the container exists (see the manual steps above), records can be
inspected at [icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard/)
under `iCloud.com.lili.Pawlease` → **Development**. All testing in this
phase targets the *Development* environment — no Production CloudKit
environment has been configured or used.

### Local development fallback

The app never requires iCloud to run:

- `PersistenceController.loadPersistentStores` only logs failures — it never
  calls `fatalError`. If a store fails to load (no account, no network, no
  provisioned container), the app still launches; screens show their
  existing loading/error/empty states rather than crashing.
- `CloudKitAccountStatusProvider.currentStatus()` catches every error from
  `CKContainer.accountStatus()` and returns `.unknown` rather than
  propagating it.
- `PersistenceController(mode: .inMemory)` — used by `PersistenceController.preview`
  and every test — uses temporary, on-disk-but-ephemeral SQLite stores with
  **no** `cloudKitContainerOptions` attached at all. Previews and tests never
  need an iCloud account, network access, or the CloudKit container to exist.

### Existing local data: migration note

Earlier phases used a single, unconfigured `NSPersistentContainer` store
(`Application Support/Pawlease.sqlite`). This phase's dual-store,
CloudKit-backed setup uses **new** files (`Application Support/Pawlease/Private.sqlite`
and `.../Shared.sqlite`) rather than migrating that file in place. Splitting
one unconfigured store into two CloudKit-scoped configurations in place is a
non-trivial, real data-migration operation; the data at risk here is only
the deterministic `SeedDemoCircleUseCase` demo Circle, which re-seeds
identically on first launch against the new stores. The **development reset
path** is exactly that: the legacy `Pawlease.sqlite` file is left untouched
on disk (never deleted automatically) and simply becomes unused. A real
production migration (if this were carrying genuine user data) would need
an explicit one-time `NSPersistentStore` migration pass, out of scope here.

## 14. App Group identifier

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

Not yet configured as an actual entitlement — that's deferred to the phase
that actually adds the Widget/Share Extension targets (see §21), since an
App Group entitlement with no extension target to justify it would just add
an unused capability to provision.

## 15. Setup instructions

1. Open `Pawlease.xcodeproj` in Xcode 26 or later.
2. Select the `Pawlease` scheme and any iOS 17+ simulator. The app builds
   and runs on a simulator **without** any CloudKit/Developer Portal setup —
   it falls back to local-only storage automatically.
3. Build and run (`⌘R`). The app seeds one local demo Circle — "The Pack,"
   3 members, 1 pet — on first launch. The current device simulates the
   first seeded member ("You").
4. To exercise real CloudKit sharing (not required for local development),
   complete the manual Developer Portal steps in §13 first, then run on a
   physical device or a simulator signed into a real iCloud account.
5. No API keys or secrets are required anywhere in this project.

## 16. Testing strategy

- **Swift Testing** for all Domain/Application/Data unit tests;
  **XCTest** only where UI testing requires it (`PawleaseUITests`).
- **Domain tests** (`PawleaseTests/Domain`) — pure value-object validation
  (`MomentCaptionTests`, `CommentBodyTests`, `CircleDayTests`), no
  repositories involved.
- **Application tests** (`PawleaseTests/Application`) — Use Cases exercised
  against lightweight in-memory fakes (`InMemory*Repository`) or fully
  configurable mocks (`Mock*Repository`, including
  `MockCloudAccountStatusProvider` and `MockCircleSharingRepository`) that
  support stubbed results, injected errors, captured arguments, and
  invocation counts. **No real CloudKit or Core Data involved** — this
  includes every CloudKit-sharing-related test (account status mapping,
  invitation preparation/reuse/failure, invitation acceptance).
- **Data tests** (`PawleaseTests/Data`) — integration tests against a real,
  temporary, on-disk (non-CloudKit) Core Data stack
  (`PersistenceController(mode: .inMemory)`), proving the schema, mappers,
  and repositories work end to end — including
  `PersistenceControllerMultiStoreTests`, which proves both the `Private`
  and `Shared` stores load and accept writes together without an iCloud
  account. These are clearly separate from, and not counted among, the
  mock-based unit tests.
- **UI tests** (`PawleaseUITests`) — a real interactive tap-through of the
  golden path (seeded Circle visible → open Composer → Publish gated on
  valid input → Cancel returns to Pet Home) plus a launch-performance test.

Run everything with:

```sh
xcodebuild -project Pawlease.xcodeproj -scheme Pawlease \
  -destination 'id=<simulator-udid>' test
```

## 17. Manual two-device test procedure

**This procedure has not yet been performed.** Everything above it (build,
automated tests, entitlements/capability wiring) has been verified in this
environment; real multi-user CloudKit sharing has not, because it requires
two physical (or simulator, at minimum) devices signed into two different
real iCloud accounts, which this environment cannot provide. Simulator-only
success is not sufficient proof of multi-user sharing, and this repo does
not claim it has been achieved.

1. Complete the manual Developer Portal steps in §13 on both devices'
   Development Team.
2. Device A signs into iCloud (Settings → [Name]).
3. Device A launches Pawlease, opens **Circle Settings** (gear icon on Pet
   Home).
4. Device A taps **Invite Friends** — this calls `PrepareCircleInvitationUseCase`
   then presents the native `UICloudSharingController` sheet.
5. Device A sends the invitation (Messages, Mail, or copy link) to the
   account signed into Device B.
6. Device B, signed into a **different** iCloud account, accepts the
   invitation from the Messages/Mail link.
7. Device B launches Pawlease. `PawleaseAppDelegate` stages the invitation
   metadata; on the next foreground, `AcceptCircleInvitationUseCase` imports
   it. Device B should see the shared Circle and pet on Pet Home.
8. Device A publishes a daily moment.
9. Device B publishes a daily moment.
10. Both devices should show `2/2` contributors and a survived Circle day
    once CloudKit sync completes (see the sync badge on Pet Home).
11. Device B opens the moment, adds a comment and a reaction.
12. Device A should see Device B's comment/reaction after CloudKit
    synchronization (pull-to-refresh, or automatically via the remote-change
    signal `PetHomeViewModel.observeCloudSync()` subscribes to).

Until this procedure is actually run and its outcome recorded, treat
CloudKit sharing as **implemented and unit-tested, but not verified
end-to-end**.

## 18. Known limitations

- **Two-device CloudKit sharing has not been manually verified** — see §17.
- **Provisioning is incomplete** — the iCloud/Push/Background Modes
  capabilities are configured in code but not yet registered against the
  App ID in the Developer Portal; see §13's manual steps.
- **`.shared`-scope store semantics** — see the note under §13's "Private
  and Shared store architecture."
- **No member removal** — Circle Settings shows the roster but does not
  support removing a member in this phase.
- **Sync status is coarse** — `CircleSyncStatus` reflects genuine
  `NSPersistentCloudKitContainer` import/export event evidence, but not
  per-record confirmation (the platform doesn't expose that granularity).
- **One active Circle per user** — creating or joining a second Circle is
  not supported in this MVP.
- Widget, Share Extension, memory calendar, and final pet artwork remain
  unimplemented — see §21.

## 19. Privacy explanation

Pawlease stores Circle data (moments, comments, reactions, membership) in
Apple's CloudKit **private** and **shared** databases only — never the
public database, and never on any non-Apple server. A Circle's data is only
visible to its invited members, via Apple's own `CKShare` participant model
(private sharing — never publicly discoverable or searchable). Photos are
stored as Core Data binary attributes with external storage, mirrored
through the same private/shared CloudKit zones as everything else — no
separate media hosting service is used. No analytics, tracking, or
third-party SDKs are present anywhere in the project.

## 20. Current implementation status

**Implemented:**

- `NSPersistentCloudKitContainer`-backed Core Data stack with `Private` and
  `Shared` configurations/stores, persistent history tracking, remote
  change notifications, and non-fatal store-load handling.
- Full schema for Circles, Members, Pets, Daily Posts, Comments, Post
  Reactions, and Comment Reactions; Semantic Domain Models, value objects,
  and repository protocols/implementations for all of it.
- Use Cases for seeding, publishing, feed unlocking, care-status/streak
  calculation, comments, reactions, iCloud account checking, Circle
  invitation preparation/acceptance, sharing-state loading, and
  remote-change-driven refresh.
- CloudKit sharing: `CKShare` creation/reuse, the native
  `UICloudSharingController` presented through a SwiftUI adapter, the
  `application(_:userDidAcceptCloudKitShareWith:)` acceptance lifecycle via
  an `AppDelegate` adaptor and a dedicated coordinator, and semantic
  CloudKit error mapping.
- Pet Home, Post Composer, Today Feed, Post Detail, and the new **Circle
  Settings** screen (Circle/pet name, member roster, iCloud account state,
  sharing state, Invite/Refresh, last-updated time), each with a dedicated
  MVVM ViewModel.
- A honest `CircleSyncStatus` badge on Pet Home, driven by real
  `NSPersistentCloudKitContainer` event notifications.
- Accessibility: Dynamic Type–friendly text styles, semantic colors,
  VoiceOver labels/hints, `ContentUnavailableView` for empty/locked/error
  states.

**Not yet done:** the manual Developer Portal capability registration and
the two-device manual verification (§13, §17); the Widget extension, Share
Extension, memory calendar, and final pet artwork — see §21.

## 21. Planned features

- **`feature/pet-widget`** — PawleaseWidget: current pet state, `1/2`
  contributor progress, whether the current member has posted, deep-link to
  the composer, reading a lightweight App Group snapshot rather than
  opening Core Data or CloudKit itself.
- **PawleaseShareExtension** — see §11.
- Two-device CloudKit sharing verification (§17), once the Developer Portal
  capabilities are registered (§13).
- Memory calendar (browsing past Circle days and their moments).
- Final pet artwork and stage-transition animations.
