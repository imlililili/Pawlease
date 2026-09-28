import SwiftUI

/// A button-driven emoji reaction control. Tapping the visible button
/// focuses an invisible one-character receiver for the system keyboard.
struct DiaryReactionButton: View {
    let currentReactionEmoji: String?
    let onSubmit: (String) -> Void
    let onRemove: () -> Void

    @State private var keyboardInput = ""
    @State private var inputMessage: String?
    @State private var isKeyboardFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button {
                    inputMessage = nil
                    keyboardInput = ""
                    isKeyboardFocused = true
                } label: {
                    Label(buttonTitle, systemImage: "face.smiling")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .accessibilityLabel(reactionButtonAccessibilityLabel)
                .accessibilityHint("Opens the keyboard to choose one emoji")

                if currentReactionEmoji != nil {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Remove your reaction")
                }
            }

            if isKeyboardFocused {
                Text("Choose one emoji from your keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let inputMessage {
                Text(inputMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            EmojiKeyboardTextField(
                text: $keyboardInput,
                isFirstResponder: $isKeyboardFocused
            )
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onChange(of: keyboardInput) { _, newValue in
                    receiveKeyboardInput(newValue)
                }
        }
    }

    private var buttonTitle: String {
        currentReactionEmoji.map { "Reacted \($0)" } ?? "React"
    }

    private var reactionButtonAccessibilityLabel: String {
        currentReactionEmoji.map { "Change reaction. Current reaction: \($0)" } ?? "React with an emoji"
    }

    private func receiveKeyboardInput(_ rawValue: String) {
        guard !rawValue.isEmpty else { return }
        if let emoji = try? DiaryReactionEmoji(rawValue) {
            onSubmit(emoji.value)
            keyboardInput = ""
            inputMessage = nil
            isKeyboardFocused = false
        } else {
            keyboardInput = ""
            inputMessage = "Please choose a single emoji."
        }
    }
}
