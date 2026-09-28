import SwiftUI

/// Today's photo-first Moment surface. Every member's contribution occupies
/// the same square stage; paging keeps it distinct from the text-only Diary
/// feed that will live below it.
struct TodayFeedView: View {
    let moments: [DailyMoment]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Today's Moments")
                    .font(.headline)
                Spacer()
                Text("\(moments.count) shared")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TabView {
                ForEach(moments) { moment in
                    NavigationLink(value: moment.id) {
                        MomentSquareCard(moment: moment)
                    }
                    .buttonStyle(.plain)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: moments.count > 1 ? .automatic : .never))
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

private struct MomentSquareCard: View {
    let moment: DailyMoment

    var body: some View {
        ZStack(alignment: .bottom) {
            photo

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(moment.authorNameSnapshot)
                        .font(.headline)
                    if !moment.caption.value.isEmpty {
                        Text(moment.caption.value)
                            .font(.body)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Text(moment.createdAt, style: .time)
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens comments and reactions")
    }

    @ViewBuilder
    private var photo: some View {
        if let image = UIImage(data: moment.photo.imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .overlay { Image(systemName: "photo").font(.largeTitle) }
        }
    }

    private var accessibilityLabel: String {
        if moment.caption.value.isEmpty {
            return "Photo from \(moment.authorNameSnapshot)"
        }
        return "Photo from \(moment.authorNameSnapshot): \(moment.caption.value)"
    }
}
