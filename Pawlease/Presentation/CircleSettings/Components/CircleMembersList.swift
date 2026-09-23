import SwiftUI

struct CircleMembersList: View {
    let memberNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Members")
                .font(.headline)
            ForEach(memberNames, id: \.self) { name in
                Text(name)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Members: \(memberNames.joined(separator: ", "))")
    }
}
