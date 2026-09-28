import SwiftUI

/// A free-keyboard emoji reaction control — deliberately not a fixed emoji
/// picker. The user types any single emoji from the system keyboard (which
/// includes its own emoji keyboard); `DiaryReactionEmoji` validates it
/// before the Use Case ever sees it. Showing the current reaction as a
/// removable chip mirrors the fixed-set `ReactionPicker`'s
/// tap-again-to-remove behavior for Daily Moments.
struct DiaryReactionEntryField: View {
    let currentReactionEmoji: String?
    let onSubmit: (String) -> Void
    let onRemove: () -> Void

    @State private var text = ""

    var body: some View {
        HStack(spacing: 8) {
            if let currentReactionEmoji {
                Button(action: onRemove) {
                    Text(currentReactionEmoji)
                        .padding(6)
                        .background(Circle().fill(Color.accentColor.opacity(0.25)))
                }
                .accessibilityLabel("Remove your reaction")
            }

            TextField("React 🙂", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 90)
                .onSubmit(submit)
                .accessibilityLabel("Type an emoji to react")

            Button("React", action: submit)
                .font(.caption)
                .disabled(text.isEmpty)
        }
    }

    private func submit() {
        guard !text.isEmpty else { return }
        onSubmit(text)
        text = ""
    }
}
