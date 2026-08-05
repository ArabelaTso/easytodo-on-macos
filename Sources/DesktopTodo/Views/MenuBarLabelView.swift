import SwiftData
import SwiftUI

struct MenuBarLabelView: View {
    @Query private var tasks: [TodoTask]

    private var completedCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var body: some View {
        Text("\(completedCount) / \(tasks.count)")
    }
}
