import SwiftUI

/// A button-driven emoji reaction control — a real `Button`, never a visible
/// text field. Tapping it requests focus on an invisible, one-shot
/// `EmojiKeyboardTextField`, which opens the system emoji keyboard; picking
/// one emoji commits and dismisses it in a single step.
struct DiaryReactionButton: View {
    let currentReactionEmoji: String?
    let onSubmit: (String) -> Void
    let onRemove: () -> Void

    @State private var isKeyboardActive = false
    @State private var inputMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button {
                    inputMessage = nil
                    isKeyboardActive = true
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

            if isKeyboardActive {
                Text("Choose one emoji from your keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let inputMessage {
                Text(inputMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Invisible and non-interactive: the keyboard is driven purely
            // by `isKeyboardActive`, never by direct interaction with this
            // representable itself.
            EmojiKeyboardTextField(
                isActive: $isKeyboardActive,
                onEmojiCommitted: { rawValue in
                    if let emoji = try? DiaryReactionEmoji(rawValue) {
                        inputMessage = nil
                        onSubmit(emoji.value)
                    } else {
                        inputMessage = "Please choose a single emoji."
                    }
                },
                onDismiss: {
                    isKeyboardActive = false
                }
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var buttonTitle: String {
        currentReactionEmoji.map { "Reacted \($0)" } ?? "React"
    }

    private var reactionButtonAccessibilityLabel: String {
        currentReactionEmoji.map { "Change reaction. Current reaction: \($0)" } ?? "React with an emoji"
    }
}
