import SwiftUI
import WidgetKit

@main
struct MyCalendarEditorApp: App {
    @StateObject private var model = EditorModel()

    var body: some Scene {
        WindowGroup {
            EditorView(model: model)
                .frame(minWidth: 520, minHeight: 620)
                .onOpenURL { url in
                    if let raw = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "date" })?.value,
                       let date = ISO8601DateFormatter.calendarDate.date(from: raw) {
                        model.selectedDate = date
                    }
                }
        }
        .commands { }
    }
}

@MainActor final class EditorModel: ObservableObject {
    @Published var selectedDate = Calendar.current.startOfDay(for: Date())
    @Published var entries = CalendarData.load()
    @Published var newTask = ""
    @Published var editingID: UUID?
    @Published var editingText = ""

    var key: String { CalendarData.dateKey(selectedDate) }
    var tasks: [CalendarTask] { entries[key]?.tasks ?? [] }

    func addTask() {
        let title = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        update { $0.tasks.append(CalendarTask(title: title)) }
        newTask = ""
    }
    func beginEdit(_ task: CalendarTask) { editingID = task.id; editingText = task.title }
    func commitEdit() {
        guard let id = editingID else { return }
        let title = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty { delete(id) }
        else { update { if let i = $0.tasks.firstIndex(where: { $0.id == id }) { $0.tasks[i].title = title } } }
        editingID = nil; editingText = ""
    }
    func cancelEdit() { editingID = nil; editingText = "" }
    func toggle(_ id: UUID) { update { if let i = $0.tasks.firstIndex(where: { $0.id == id }) { $0.tasks[i].isDone.toggle() } } }
    func delete(_ id: UUID) { update { $0.tasks.removeAll { $0.id == id } } }
    func shift(_ amount: Int) { selectedDate = Calendar.current.date(byAdding: .month, value: amount, to: selectedDate) ?? selectedDate }
    private func update(_ change: (inout DayEntry) -> Void) {
        var entry = entries[key] ?? DayEntry(); change(&entry); entries[key] = entry
        CalendarData.save(entries)
        WidgetCenterReload.reload()
    }
}

enum WidgetCenterReload {
    static func reload() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

private extension ISO8601DateFormatter {
    static var calendarDate: ISO8601DateFormatter {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]; return f
    }
}
