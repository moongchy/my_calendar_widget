import SwiftUI
import WidgetKit

struct MyCalendarEntry: TimelineEntry {
    let date: Date
    let entries: [String: DayEntry]
}

struct MyCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> MyCalendarEntry { MyCalendarEntry(date: .now, entries: [:]) }
    func getSnapshot(in context: Context, completion: @escaping (MyCalendarEntry) -> Void) {
        completion(MyCalendarEntry(date: .now, entries: CalendarData.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MyCalendarEntry>) -> Void) {
        let entry = MyCalendarEntry(date: .now, entries: CalendarData.load())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900))))
    }
}

struct MyCalendarWidgetView: View {
    var entry: MyCalendarProvider.Entry
    @Environment(\.widgetFamily) private var family
    private let cal = Calendar(identifier: .gregorian)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        let month = cal.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
        VStack(spacing: 5) {
            HStack {
                Text("MY CALENDAR").font(.system(size: 10, weight: .black, design: .monospaced)).tracking(2)
                Spacer()
                Text(month.formatted(.dateTime.year().month(.wide))).font(.system(size: 17, weight: .black))
            }
            HStack(spacing: 2) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { i, day in
                    Text(day).font(.system(size: family == .systemExtraLarge ? 15 : 12, weight: .black))
                        .foregroundStyle(i == 0 ? .red : i == 6 ? .blue : .white)
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                        .background(i == 0 || i == 6 ? Color.clear : Color.black.opacity(0.82))
                }
            }
            let dates = monthDates(month)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                ForEach(Array(dates.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(minHeight: family == .systemExtraLarge ? 78 : 48)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .containerBackground(Color(red: 0.985, green: 0.989, blue: 0.996), for: .widget)
    }

    @ViewBuilder private func dayCell(_ date: Date) -> some View {
        let key = CalendarData.dateKey(date)
        let tasks = entry.entries[key]?.tasks ?? []
        let day = cal.component(.day, from: date)
        let wd = cal.component(.weekday, from: date)
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(day)").font(.system(size: family == .systemExtraLarge ? 20 : 14, weight: .black, design: .default))
                    .foregroundStyle(wd == 1 ? .red : wd == 7 ? .blue : .primary)
                Spacer(minLength: 0)
                if cal.isDateInToday(date) { Text("✳").font(.system(size: 12)).foregroundStyle(.red.opacity(0.48)) }
            }
            ForEach(tasks.prefix(family == .systemExtraLarge ? 3 : 2)) { task in
                Button(intent: ToggleCalendarTaskIntent(dateKey: key, taskID: task.id.uuidString)) {
                    HStack(spacing: 3) {
                        Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                            .font(.system(size: 9))
                        Text(task.title).font(.system(size: family == .systemExtraLarge ? 10 : 8))
                            .lineLimit(1).strikethrough(task.isDone)
                    }
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: family == .systemExtraLarge ? 78 : 48, alignment: .topLeading)
        .overlay(Rectangle().stroke(Color.black.opacity(0.35), lineWidth: 0.5))
        .widgetURL(URL(string: "mycalendar://edit?date=\(ISO8601DateFormatter.calendarDate.string(from: date))"))
    }

    private func monthDates(_ month: Date) -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: month),
              let range = cal.range(of: .day, in: .month, for: month) else { return Array(repeating: nil, count: 42) }
        let offset = cal.component(.weekday, from: interval.start) - 1
        return (0..<42).map { i in
            let d = i - offset + 1
            guard d > 0 && d <= range.count else { return nil }
            return cal.date(byAdding: .day, value: d - 1, to: interval.start)
        }
    }
}

struct MyCalendarWidget: Widget {
    let kind = "MyCalendarWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyCalendarProvider()) { entry in
            MyCalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("MyCalendar")
        .description("월간 달력과 숙제 체크")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@main struct MyCalendarWidgetBundle: WidgetBundle {
    var body: some Widget { MyCalendarWidget() }
}

private extension ISO8601DateFormatter {
    static var calendarDate: ISO8601DateFormatter {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]; return f
    }
}
