import SwiftData
import SwiftUI

struct MenuBarLabelView: View {
    @Query private var tasks: [TodoTask]

    private let calendar = Calendar.current

    private var todayTasks: [TodoTask] {
        tasks.filter { task in
            task.isScheduled(on: .now, calendar: calendar)
        }
    }

    private var completedCount: Int {
        todayTasks.filter(\.isCompleted).count
    }

    var body: some View {
        Text("\(completedCount) / \(todayTasks.count)")
    }
}
