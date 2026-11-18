import Foundation

struct CalendarTask: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

struct DayEntry: Codable, Equatable {
    var tasks: [CalendarTask]
    var circled: Bool

    init(tasks: [CalendarTask] = [], circled: Bool = false) {
        self.tasks = tasks
        self.circled = circled
    }

    private enum CodingKeys: String, CodingKey { case tasks, circled, notes, done }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        circled = try c.decodeIfPresent(Bool.self, forKey: .circled) ?? false
        if let current = try c.decodeIfPresent([CalendarTask].self, forKey: .tasks) {
            tasks = current
        } else {
            let notes = try c.decodeIfPresent([String].self, forKey: .notes) ?? []
            let done = try c.decodeIfPresent([Bool].self, forKey: .done) ?? []
            tasks = notes.enumerated().compactMap { index, note in
                let value = note.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { return nil }
                return CalendarTask(title: value, isDone: index < done.count ? done[index] : false)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tasks, forKey: .tasks)
        try c.encode(circled, forKey: .circled)
    }
}

enum CalendarData {
    static let appGroup = "group.com.moongchy.MyCalendar"
    static let fileName = "calendar.json"

    static var fileURL: URL {
        let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("MyCalendar", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent(fileName)
    }

    static func load() -> [String: DayEntry] {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: DayEntry].self, from: data) { return decoded }
        // One-time fallback: read the previous app's Application Support file.
        let oldURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NamaneCalendar", isDirectory: true)
            .appendingPathComponent("calendar.json")
        guard let oldData = try? Data(contentsOf: oldURL),
              let oldObject = try? JSONSerialization.jsonObject(with: oldData) as? [String: Any] else { return [:] }
        let rawCalendar = (oldObject["calendar"] as? [String: [String: Any]]) ?? (oldObject as? [String: [String: Any]]) ?? [:]
        var migrated: [String: DayEntry] = [:]
        for (key, raw) in rawCalendar {
            let notes = raw["notes"] as? [String] ?? []
            let done = raw["done"] as? [Bool] ?? []
            let tasks = notes.enumerated().compactMap { index, note -> CalendarTask? in
                let title = note.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return nil }
                return CalendarTask(title: title, isDone: index < done.count ? done[index] : false)
            }
            migrated[key] = DayEntry(tasks: tasks, circled: raw["circled"] as? Bool ?? false)
        }
        if !migrated.isEmpty { save(migrated) }
        return migrated
    }

    static func save(_ entries: [String: DayEntry]) {
        do {
            let data = try JSONEncoder.pretty.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("MyCalendar save failed: %@", error.localizedDescription)
        }
    }

    static func dateKey(_ date: Date) -> String {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
