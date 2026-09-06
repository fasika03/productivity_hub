// This file is for a WidgetKit Widget Extension, which must be created in
// Xcode first (there's no way to add one by just copying files — see the
// README's "Home screen widget" section for the exact Xcode steps).
//
// Once you've created the extension (e.g. named "QuoteWidgetExtension"),
// replace the auto-generated Swift file's contents with everything below.
//
// Keep this quote list in sync with lib/data/quotes.dart if you add/edit quotes.

import WidgetKit
import SwiftUI

struct Quote {
    let text: String
    let author: String
}

let quotes: [Quote] = [
    Quote(text: "Discipline is choosing between what you want now and what you want most.", author: "Abraham Lincoln"),
    Quote(text: "The expert in anything was once a beginner.", author: "Helen Hayes"),
    Quote(text: "Small steps every day add up to big results.", author: "Unknown"),
    Quote(text: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar"),
    Quote(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier"),
    Quote(text: "Focus on progress, not perfection.", author: "Unknown"),
    Quote(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
    Quote(text: "Push yourself, because no one else is going to do it for you.", author: "Unknown"),
    Quote(text: "A little progress each day adds up to big results.", author: "Unknown"),
    Quote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson"),
    Quote(text: "Well done is better than well said.", author: "Benjamin Franklin"),
    Quote(text: "Study while others are sleeping; work while others are loafing.", author: "William A. Ward")
]

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: quotes[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(QuoteEntry(date: Date(), quote: quotes.randomElement()!))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let now = Date()
        var entries: [QuoteEntry] = []
        // One entry per hour for the next 6 hours, each showing a different
        // quote — iOS decides exactly when it actually redraws the widget
        // within that budget, similar to Android's update throttling.
        for hourOffset in 0..<6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            let quote = quotes.randomElement()!
            entries.append(QuoteEntry(date: entryDate, quote: quote))
        }
        let timeline = Timeline(entries: entries, policy: .after(entries.last!.date))
        completion(timeline)
    }
}

struct QuoteWidgetEntryView: View {
    var entry: QuoteProvider.Entry

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 43/255, blue: 36/255)
            VStack(alignment: .leading, spacing: 8) {
                Text("\u201C\(entry.quote.text)\u201D")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(Color(red: 242/255, green: 236/255, blue: 220/255))
                    .lineLimit(4)
                Text("\u2014 \(entry.quote.author)".uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(red: 200/255, green: 155/255, blue: 60/255))
            }
            .padding()
        }
    }
}

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Productivity Hub Quote")
        .description("A motivational quote, right on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
