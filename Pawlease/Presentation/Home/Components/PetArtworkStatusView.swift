import SwiftUI
import UIKit

/// The large square hero area with its status pill (upper-left) and today's
/// contributor-progress pill (lower-right) overlaid, followed by the pet's
/// identity (small stage emoji + name) and a dynamic status explanation.
///
/// The hero itself shows **Today's Moment** — the most recent visible
/// current-day photo — never the pet emoji/icon as its primary content.
/// `latestVisibleMoment` is already privacy-gated by the caller: Pet Home
/// only loads `todayMoments` (and so only ever passes a non-nil moment here)
/// once the current member has posted, so a friend's current-day photo can
/// never leak into this view before that.
struct PetArtworkStatusView: View {
    let state: PetHomeViewState
    let latestVisibleMoment: DailyMoment?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                hero

                statusPill
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(14)

                contributorPill
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(14)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: PawleaseTheme.cardCornerRadius))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(heroAccessibilityLabel). \(state.activityStateLabel). \(state.contributorAccessibilityLabel).")

            HStack(spacing: 8) {
                PetArtworkView(stage: state.petStage)
                    .font(.title)
                    .accessibilityHidden(true)
                Text(state.petName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(PawleaseTheme.textPrimary)
            }

            Text(state.statusExplanation)
                .font(.subheadline)
                .foregroundStyle(PawleaseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let latestVisibleMoment, let uiImage = UIImage(data: latestVisibleMoment.photo.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: PawleaseTheme.cardCornerRadius)
                    .fill(PawleaseTheme.petArtworkBackground)
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(PawleaseTheme.textSecondary)
                    Text("Today's Moment")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PawleaseTheme.textSecondary)
                }
            }
        }
    }

    private var heroAccessibilityLabel: String {
        latestVisibleMoment != nil ? "Today's Moment photo" : "No photo shared yet today"
    }

    private var statusPill: some View {
        Label(state.activityStateLabel, systemImage: state.hasSurvivedToday ? "checkmark.circle.fill" : "moon.zzz.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(state.hasSurvivedToday ? Color.green : PawleaseTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    private var contributorPill: some View {
        Text(state.contributorPillLabel)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(PawleaseTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }
}
