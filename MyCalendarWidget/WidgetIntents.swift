import AppIntents
import WidgetKit

struct ToggleCalendarTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "숙제 완료 상태 변경"
    static var openAppWhenRun = false

    @Parameter(title: "날짜 키") var dateKey: String
    @Parameter(title: "숙제 ID") var taskID: String

    init() { dateKey = ""; taskID = "" }
    init(dateKey: String, taskID: String) { self.dateKey = dateKey; self.taskID = taskID }

    func perform() async throws -> some IntentResult {
        var entries = CalendarData.load()
        guard var entry = entries[dateKey],
              let id = UUID(uuidString: taskID),
              let index = entry.tasks.firstIndex(where: { $0.id == id }) else {
            return .result()
        }
        entry.tasks[index].isDone.toggle()
        entries[dateKey] = entry
        CalendarData.save(entries)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
