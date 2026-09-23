import SwiftUI
import WidgetKit

struct PetStatusMediumView: View {
    let display: PetStatusDisplay

    private var snapshot: WidgetSnapshot { display.snapshot }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                Text(PetSpeciesArtwork.emoji(forSpeciesKey: snapshot.petSpeciesKey))
                    .font(.system(size: 36))
            }
            .frame(width: 60, height: 60)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(snapshot.petName)
                        .font(.title3.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Image(systemName: display.status.systemImageName)
                        .foregroundStyle(display.status.tintColor)
                }

                Text(display.status.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                ContributorProgressBar(current: snapshot.contributorCount, required: snapshot.requiredContributorCount)

                HStack {
                    Label("\(snapshot.currentStreak)-day streak", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                    Spacer()
                    Text("\(snapshot.contributorCount)/\(snapshot.requiredContributorCount) today")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                LastUpdatedCaption(lastUpdated: snapshot.lastUpdated, now: display.date)
            }
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

#Preview("Medium – Survived", as: .systemMedium) {
    PawleaseWidget()
} timeline: {
    PetStatusEntry(date: .now, display: .preview(survived: true))
}

#Preview("Medium – Waiting", as: .systemMedium) {
    PawleaseWidget()
} timeline: {
    PetStatusEntry(date: .now, display: .preview(survived: false))
}
