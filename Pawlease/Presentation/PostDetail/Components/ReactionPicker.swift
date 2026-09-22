import SwiftUI

/// The five fixed emoji choices. Tapping a different emoji than the current
/// selection replaces it; tapping the current selection again removes it —
/// both handled by the ViewModel via a Use Case, this View only reports taps.
struct ReactionPicker: View {
    let selectedEmoji: ReactionEmoji?
    let onSelect: (ReactionEmoji) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ReactionEmoji.allCases, id: \.self) { emoji in
                let isSelected = emoji == selectedEmoji
                Button {
                    onSelect(emoji)
                } label: {
                    Text(emoji.rawValue)
                        .font(.title3)
                        .padding(6)
                        .background(
                            Circle().fill(isSelected ? Color.accentColor.opacity(0.3) : .clear)
                        )
                }
                .accessibilityLabel(
                    isSelected
                        ? "Remove \(emoji.accessibilityName) reaction"
                        : "React with \(emoji.accessibilityName)"
                )
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
