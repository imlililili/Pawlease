import SwiftUI

/// Comment entry field: a 60-character cap with a live count, a Send button
/// disabled for empty or invalid text, and an accessible validation message
/// when a submission fails.
struct CommentComposer: View {
    @Binding var text: String
    let characterLimit: Int
    let isValid: Bool
    let isSubmitting: Bool
    let errorMessage: String?
    let onSubmit: () -> Void

    private var characterCountLabel: String {
        "\(text.count)/\(characterLimit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Comment error: \(errorMessage)")
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Add a comment…", text: $text, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Comment")

                Button(action: onSubmit) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .disabled(!isValid || isSubmitting)
                .accessibilityLabel("Send comment")
                .accessibilityHint(isValid ? "" : "Enter up to \(characterLimit) characters to send")
            }

            Text(characterCountLabel)
                .font(.caption)
                .foregroundStyle(isValid ? Color.secondary : Color.red)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("\(characterCountLabel) characters used")
        }
    }
}
