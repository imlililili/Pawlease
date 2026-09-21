import Foundation
@testable import Pawlease

struct FakeClock: ClockProviding {
    let now: Date
}
