import Foundation

/// One member's free-keyboard-emoji reaction to a `DiaryEntry`.
struct DiaryReaction: Identifiable, Sendable, Equatable {
    let id: UUID
    let entryID: UUID
    let memberProfileID: UUID
    let emoji: DiaryReactionEmoji
    let createdAt: Date
}
