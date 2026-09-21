import SwiftUI

struct TodayFeedView: View {
    let moments: [DailyMoment]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Moments")
                .font(.headline)

            ForEach(moments) { moment in
                MomentRow(moment: moment)
            }
        }
    }
}

private struct MomentRow: View {
    let moment: DailyMoment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(moment.authorNameSnapshot)
                        .font(.subheadline.bold())
                    if let mood = moment.moodEmoji {
                        Text(mood)
                    }
                    Spacer()
                    Text(moment.createdAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(moment.caption.value)
                    .font(.body)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(moment.authorNameSnapshot): \(moment.caption.value)")
    }

    private var thumbnail: some View {
        Group {
            if let uiImage = UIImage(data: moment.photo.thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(.secondary.opacity(0.2))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}
