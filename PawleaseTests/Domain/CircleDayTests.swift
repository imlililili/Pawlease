import Testing
import Foundation
@testable import Pawlease

struct CircleDayTests {
    @Test func usesCirclesStoredTimeZoneNotDeviceTimeZone() {
        let date = TestFactories.date(year: 2026, month: 3, day: 15, hour: 10, timeZoneIdentifier: "UTC")

        let tokyoDay = CircleDay(date: date, timeZoneIdentifier: "Asia/Tokyo")

        #expect(tokyoDay.value == "2026-03-15")
    }

    @Test func sameInstantProducesDifferentDayKeysAcrossTimeZones() {
        // 2026-01-01 01:00 UTC
        let date = TestFactories.date(year: 2026, month: 1, day: 1, hour: 1, timeZoneIdentifier: "UTC")

        let tokyoDay = CircleDay(date: date, timeZoneIdentifier: "Asia/Tokyo") // UTC+9 -> 10:00 same day
        let losAngelesDay = CircleDay(date: date, timeZoneIdentifier: "America/Los_Angeles") // UTC-8 -> previous day

        #expect(tokyoDay.value == "2026-01-01")
        #expect(losAngelesDay.value == "2025-12-31")
        #expect(tokyoDay != losAngelesDay)
    }
}
