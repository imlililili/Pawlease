import Foundation

struct SystemClock: ClockProviding {
    var now: Date { Date() }
}
