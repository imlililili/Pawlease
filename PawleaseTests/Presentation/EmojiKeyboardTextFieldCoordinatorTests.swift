import Testing
import UIKit
@testable import Pawlease

/// Regression coverage for Bug 1 (emoji reaction freeze/crash). The
/// confirmed root cause was a two-way responder/text feedback loop:
/// `updateUIView` called `resignFirstResponder()` synchronously, which
/// synchronously re-entered `textFieldDidEndEditing`, which wrote back into
/// the same SwiftUI binding mid-update — reported by SwiftUI as
/// `AttributeGraph: cycle detected through attribute ...`.
///
/// These tests exercise `EmojiKeyboardTextField.Coordinator` directly via
/// `UITextFieldDelegate` calls — the same calls UIKit makes when a real
/// emoji is picked from the system keyboard — without needing the actual
/// keyboard, so they run reliably in CI/Simulator automation.
@MainActor
struct EmojiKeyboardTextFieldCoordinatorTests {
    @Test
    func selectingOneEmojiCommitsExactlyOnce() async throws {
        var committedValues: [String] = []
        let coordinator = EmojiKeyboardTextField.Coordinator(
            onEmojiCommitted: { committedValues.append($0) },
            onDismiss: {}
        )
        let textField = EmojiTextField()
        textField.delegate = coordinator

        // A single tap on one emoji key delivers the whole grapheme cluster
        // as one `replacementString` — but even if the delegate were
        // consulted twice for the same character (compound/skin-tone
        // sequences, or a stray duplicate call), only the first counts.
        let emptyRange = NSRange(location: 0, length: 0)
        _ = coordinator.textField(textField, shouldChangeCharactersIn: emptyRange, replacementString: "😀")
        _ = coordinator.textField(textField, shouldChangeCharactersIn: emptyRange, replacementString: "😀")

        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(committedValues == ["😀"])
    }

    @Test
    func endingTheSessionAllowsExactlyOneNewCommitAfterwards() async throws {
        var committedValues: [String] = []
        let coordinator = EmojiKeyboardTextField.Coordinator(
            onEmojiCommitted: { committedValues.append($0) },
            onDismiss: {}
        )
        let textField = EmojiTextField()
        textField.delegate = coordinator
        let emptyRange = NSRange(location: 0, length: 0)

        _ = coordinator.textField(textField, shouldChangeCharactersIn: emptyRange, replacementString: "😀")
        try await Task.sleep(nanoseconds: 50_000_000)

        // What UIKit calls once `resignFirstResponder()` actually completes.
        coordinator.textFieldDidEndEditing(textField)

        _ = coordinator.textField(textField, shouldChangeCharactersIn: emptyRange, replacementString: "🌼")
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(committedValues == ["😀", "🌼"])
    }

    @Test
    func commitNeverFiresSynchronouslyOnTheCallingStack() {
        // This is the exact property that breaks the old cycle: nothing
        // downstream (the reaction submission, the resign call) can nest
        // inside the delegate callback that's currently on the stack —
        // it's scheduled for a later run-loop turn instead.
        var committedSynchronously = false
        let coordinator = EmojiKeyboardTextField.Coordinator(
            onEmojiCommitted: { _ in committedSynchronously = true },
            onDismiss: {}
        )
        let textField = EmojiTextField()
        textField.delegate = coordinator

        _ = coordinator.textField(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "😀")

        #expect(committedSynchronously == false)
    }

    @Test
    func dismissalNeverFiresSynchronouslyOnTheCallingStack() {
        var dismissedSynchronously = false
        let coordinator = EmojiKeyboardTextField.Coordinator(
            onEmojiCommitted: { _ in },
            onDismiss: { dismissedSynchronously = true }
        )
        let textField = EmojiTextField()
        textField.delegate = coordinator

        coordinator.textFieldDidEndEditing(textField)

        #expect(dismissedSynchronously == false)
    }

    @Test
    func theTypedCharacterIsNeverActuallyInsertedIntoTheField() {
        // Confirms this is a real button-driven control, not a visible
        // text field the user types into: UIKit is told `false`, so the
        // field's own text buffer never changes.
        let coordinator = EmojiKeyboardTextField.Coordinator(onEmojiCommitted: { _ in }, onDismiss: {})
        let textField = EmojiTextField()
        textField.delegate = coordinator

        let shouldInsert = coordinator.textField(
            textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "😀"
        )

        #expect(shouldInsert == false)
    }

    @Test
    func backspaceOnAnAlreadyEmptyFieldCommitsNothing() async throws {
        var committedValues: [String] = []
        let coordinator = EmojiKeyboardTextField.Coordinator(
            onEmojiCommitted: { committedValues.append($0) },
            onDismiss: {}
        )
        let textField = EmojiTextField()
        textField.delegate = coordinator

        _ = coordinator.textField(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "")
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(committedValues.isEmpty)
    }
}
