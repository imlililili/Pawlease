import SwiftUI
import UIKit

/// Invisible UIKit input bridge that prefers the system emoji input mode.
/// The emoji keyboard must already be enabled in the user's keyboard
/// settings — if it isn't, `EmojiTextField.textInputMode` falls back to
/// whatever keyboard is active, and an ordinary (non-emoji) character just
/// fails `DiaryReactionEmoji` validation upstream, same as any other invalid
/// input.
///
/// Deliberately **not** a two-way `text`/`isFirstResponder` binding pair.
/// An earlier version bound both directions and produced a feedback cycle:
/// UIKit's `.editingChanged` wrote a `text` binding → SwiftUI's
/// `.onChange(of:)` cleared that binding and flipped a first-responder
/// binding to `false` synchronously, inside the same update →
/// `updateUIView` reacted by calling `resignFirstResponder()`
/// *synchronously*, which synchronously re-entered `textFieldDidEndEditing`
/// → which wrote the first-responder binding again, mutating the same
/// attribute graph while it was still mid-update. That reentrancy is
/// exactly what `AttributeGraph: cycle detected through attribute ...`
/// reports, and it froze/crashed the Simulator.
///
/// This version is one-directional and asynchronous at every UIKit/SwiftUI
/// boundary crossing:
/// - `isActive` is a **command**, not a two-way responder mirror: SwiftUI
///   sets it to request focus/dismissal; the Coordinator never writes back
///   into `isActive` from `updateUIView` or from a delegate callback fired
///   synchronously within it.
/// - The field never actually inserts the typed grapheme — the delegate
///   intercepts it in `shouldChangeCharactersIn` and returns `false`, so a
///   real character is never visibly typed into the (already invisible)
///   field.
/// - Exactly one commit per focus session is guaranteed by the coordinator's
///   own `hasCommitted` flag, reset only when a new session begins —
///   independent of how many times SwiftUI re-renders this representable.
/// - Every `becomeFirstResponder()`/`resignFirstResponder()` call, and every
///   closure invocation back out to SwiftUI, is dispatched on a later
///   run-loop turn (`DispatchQueue.main.async`), so none of it can nest
///   inside the SwiftUI update pass or a UIKit delegate call that triggered
///   it — breaking the reentrancy that caused the cycle.
struct EmojiKeyboardTextField: UIViewRepresentable {
    @Binding var isActive: Bool
    let onEmojiCommitted: (String) -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEmojiCommitted: onEmojiCommitted, onDismiss: onDismiss)
    }

    func makeUIView(context: Context) -> EmojiTextField {
        let textField = EmojiTextField()
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.text = ""
        // SwiftUI's `.accessibilityHidden(true)` on the wrapping view isn't
        // reliably inherited by this UIKit text field once it becomes first
        // responder — UIKit's own accessibility/input-associated tree can
        // still surface it independently. Set it directly here too, so
        // "React" never exposes a second, separately-typeable text field to
        // accessibility clients (including XCUITest).
        textField.isAccessibilityElement = false
        return textField
    }

    func updateUIView(_ textField: EmojiTextField, context: Context) {
        // Keep the coordinator's closures current without ever writing back
        // into a SwiftUI-owned binding from here.
        context.coordinator.onEmojiCommitted = onEmojiCommitted
        context.coordinator.onDismiss = onDismiss

        // Idempotency guard: only react when the *requested* state actually
        // changes, never on every incidental re-render.
        guard isActive != context.coordinator.isPresentingKeyboard else { return }
        context.coordinator.isPresentingKeyboard = isActive

        if isActive {
            context.coordinator.hasCommitted = false
            textField.text = ""
            DispatchQueue.main.async {
                _ = textField.becomeFirstResponder()
            }
        } else if textField.isFirstResponder {
            DispatchQueue.main.async {
                _ = textField.resignFirstResponder()
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var onEmojiCommitted: (String) -> Void
        var onDismiss: () -> Void
        var isPresentingKeyboard = false
        fileprivate var hasCommitted = false

        init(onEmojiCommitted: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
            self.onEmojiCommitted = onEmojiCommitted
            self.onDismiss = onDismiss
        }

        /// Intercepts every keystroke/keyboard commit before it's actually
        /// inserted. Returning `false` means the field's own text buffer
        /// never changes — there is nothing for a `text` binding to mirror
        /// back into SwiftUI, so that half of the old feedback loop no
        /// longer exists.
        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard !string.isEmpty, !hasCommitted else { return false }
            hasCommitted = true
            let committed = string
            DispatchQueue.main.async { [weak self, weak textField] in
                self?.onEmojiCommitted(committed)
                textField?.resignFirstResponder()
            }
            return false
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            hasCommitted = false
            isPresentingKeyboard = false
            DispatchQueue.main.async { [weak self] in
                self?.onDismiss()
            }
        }
    }
}

final class EmojiTextField: UITextField {
    override var textInputContextIdentifier: String? { "" }

    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
            ?? super.textInputMode
    }
}
