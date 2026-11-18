import SwiftUI

struct EditorView: View {
    @ObservedObject var model: EditorModel
    @FocusState private var newTaskFocused: Bool
    @FocusState private var editFocused: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { model.shift(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                VStack(spacing: 2) {
                    Text(model.selectedDate.formatted(.dateTime.year().month().day().weekday(.wide)))
                        .font(.system(size: 19, weight: .bold, design: .default))
                    Text("MY CALENDAR")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { model.shift(1) } label: { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                TextField("+ 새 숙제 입력", text: $model.newTask)
                    .textFieldStyle(.roundedBorder)
                    .focused($newTaskFocused)
                    .onSubmit { model.addTask(); newTaskFocused = true }
                Button("추가") { model.addTask() }
                    .disabled(model.newTask.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            List {
                ForEach(model.tasks) { task in
                    HStack(spacing: 9) {
                        Button { model.toggle(task.id) } label: {
                            Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                                .foregroundStyle(task.isDone ? .secondary : .primary)
                        }
                        .buttonStyle(.plain)
                        if model.editingID == task.id {
                            TextField("숙제 이름", text: $model.editingText)
                                .textFieldStyle(.plain)
                                .focused($editFocused)
                                .onSubmit { model.commitEdit() }
                                .onExitCommand { model.cancelEdit() }
                        } else {
                            Text(task.title)
                                .strikethrough(task.isDone)
                                .foregroundStyle(task.isDone ? .secondary : .primary)
                                .contentShape(Rectangle())
                                .onTapGesture { model.beginEdit(task); editFocused = true }
                        }
                        Spacer()
                        Button(role: .destructive) { model.delete(task.id) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 3)
                }
            }
            .listStyle(.inset)
        }
        .padding(18)
    }
}
