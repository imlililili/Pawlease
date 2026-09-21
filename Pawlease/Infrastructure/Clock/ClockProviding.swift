import Foundation

/// Abstracts "now" so date-dependent Use Cases are deterministic and
/// testable via an injected clock instead of calling `Date()` directly.
protocol ClockProviding: Sendable {
    var now: Date { get }
}
