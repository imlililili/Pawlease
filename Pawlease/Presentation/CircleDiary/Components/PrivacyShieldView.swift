import SwiftUI

/// Replaces a timed Diary entry's real body text while screen recording,
/// AirPlay/mirroring, or backgrounding is detected. This is the strongest
/// protection documented Apple APIs allow — it cannot prevent or detect a
/// screenshot before it happens (see `ScreenCaptureStateProviding`).
struct PrivacyShieldView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "eye.slash.fill")
                .font(.title3)
            Text("Hidden while your screen may be visible to someone else")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Content hidden for privacy while your screen is being captured or the app is backgrounded")
    }
}
