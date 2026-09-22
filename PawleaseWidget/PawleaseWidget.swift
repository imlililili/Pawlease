//
//  PawleaseWidget.swift
//  PawleaseWidget
//
//  Created by Emily on 22/9/2026.
//

import WidgetKit
import SwiftUI

/// Dispatches to a size-specific layout. Both layouts read only from
/// `PetStatusDisplay` — never Core Data, CloudKit, a repository, a Use
/// Case, or a managed object.
struct PawleaseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PetStatusEntry

    var body: some View {
        switch family {
        case .systemMedium:
            PetStatusMediumView(display: entry.display)
        default:
            PetStatusSmallView(display: entry.display)
        }
    }
}

struct PawleaseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.petStatus, provider: PetStatusProvider()) { entry in
            PawleaseWidgetEntryView(entry: entry)
                // The whole widget is one tap target that opens the app —
                // no interactive buttons, no per-row links.
                .widgetURL(URL(string: "pawlease://home"))
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Pet Status")
        .description("See your Circle's shared pet, streak, and today's contributor progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
