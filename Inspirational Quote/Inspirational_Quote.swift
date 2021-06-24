//
//  Inspirational_Quote.swift
//  Inspirational Quote
//
//  Created by Anthony Li on 6/24/21.
//

import WidgetKit
import SwiftUI
import Intents

struct Quote: Decodable {
    var q: String
    var a: String
}

func getQuotes() async throws -> [Quote] {
    let (data, _) = try await URLSession(configuration: .ephemeral).data(from: URL(string: "https://zenquotes.io/api/today")!, delegate: nil)
    return try JSONDecoder().decode([Quote].self, from: data)
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        async {
            var entries: [SimpleEntry] = []

            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            let currentDate = Date()
            for hourOffset in 0 ..< 5 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let quotes = try! await getQuotes()
                let entry = SimpleEntry(date: entryDate, quote: quotes[0].q, author: quotes[0].a, configuration: configuration)
                entries.append(entry)
            }

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    var quote: String = "This is an inspirational quote"
    var author: String = "a"
    let configuration: ConfigurationIntent
}

struct Inspirational_QuoteEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.quote)
            Text(entry.author)
        }
    }
}

@main
struct Inspirational_Quote: Widget {
    let kind: String = "Inspirational_Quote"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Inspirational_QuoteEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct Inspirational_Quote_Previews: PreviewProvider {
    static var previews: some View {
        Inspirational_QuoteEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
