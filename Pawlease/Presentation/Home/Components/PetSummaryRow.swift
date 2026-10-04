import SwiftUI

/// The two-column "CURRENT STREAK / CONTRIBUTORS" summary row, separated by
/// a thin vertical divider.
struct PetSummaryRow: View {
    let state: PetHomeViewState

    var body: some View {
        HStack(spacing: 0) {
            column(eyebrow: "CURRENT STREAK", value: state.streakLabel)
                .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(PawleaseTheme.divider)
                .frame(width: 1)
                .padding(.vertical, 4)

            column(eyebrow: "CONTRIBUTORS", value: state.progressLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, PawleaseTheme.sectionSpacing / 2)
        }
        .accessibilityElement(children: .combine)
    }

    private func column(eyebrow: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .tracking(0.4)
                .foregroundStyle(PawleaseTheme.textSecondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(PawleaseTheme.textPrimary)
        }
    }
}
