import Foundation

/// The smallest semantic handoff from an accepted `CKShare` needed to
/// locate which Circle was just joined, without guessing.
///
/// The app's single-Circle-per-device assumption
/// (`CircleRepository.fetchDefaultCircle()`) is not reliable here: a
/// friend's device may already have its own local demo Circle seeded
/// (older, so it sorts first) by the time an invitation is accepted. `nil`
/// means the Data layer could not resolve the accepted share's root record
/// to a local Circle (e.g. the shared store hasn't finished merging yet) —
/// callers must treat that as "cannot proceed" rather than falling back to
/// any other Circle.
struct AcceptedCircleHandoff: Sendable, Equatable {
    let circleID: UUID?
}
