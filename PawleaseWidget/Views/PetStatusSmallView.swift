import SwiftUI
import WidgetKit

struct PetStatusSmallView: View {
    let display: PetStatusDisplay

    private var snapshot: WidgetSnapshot { display.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(PetSpeciesArtwork.emoji(forSpeciesKey: snapshot.petSpeciesKey))
                    .font(.system(size: 28))
                Spacer()
                Image(systemName: display.status.systemImageName)
                    .foregroundStyle(display.status.tintColor)
                    .font(.subheadline)
            }
            .accessibilityHidden(true)

            Text(snapshot.petName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(display.status.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 2)

            ContributorProgressBar(current: snapshot.contributorCount, required: snapshot.requiredContributorCount)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption2)
                Text("\(snapshot.currentStreak)d")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(snapshot.contributorCount)/\(snapshot.requiredContributorCount)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        "\(snapshot.petName). \(display.status.label). "
            + "\(snapshot.currentStreak) day streak. "
            + "\(snapshot.contributorCount) of \(snapshot.requiredContributorCount) friends have shared today."
    }
}

#Preview("Small – Survived", as: .systemSmall) {
    PawleaseWidget()
} timeline: {
    PetStatusEntry(date: .now, display: .preview(survived: true))
}

#Preview("Small – Waiting", as: .systemSmall) {
    PawleaseWidget()
} timeline: {
    PetStatusEntry(date: .now, display: .preview(survived: false))
}
