import SwiftUI

/// Icon/color mapping for `PetStatusDisplayStatus` — presentation-only, so
/// it lives here (Widget target) rather than in `SharedKit`, keeping the
/// shared status type free of SwiftUI/`Color`.
extension PetStatusDisplayStatus {
    var systemImageName: String {
        switch self {
        case .survivedToday: "checkmark.circle.fill"
        case .waitingForAnotherFriend: "hourglass.circle.fill"
        case .needsCurrentMemberToPost: "camera.circle.fill"
        case .noSharedData: "questionmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .survivedToday: .green
        case .waitingForAnotherFriend: .orange
        case .needsCurrentMemberToPost: .accentColor
        case .noSharedData: .secondary
        }
    }
}
