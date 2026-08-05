# Desktop Todo

## 1. Product Positioning

**One sentence:** A simple todo list that always stays on your desktop.

**Keywords:**

- Always Visible
- Lightweight
- Beautiful

This is not a productivity system, GTD tool, or Notion replacement. It is a focused todo list that stays visible on the desktop.

## 2. MVP Scope: V1.0

### 2.1 Todo List

Core task actions:

- Create tasks
- Edit tasks
- Delete tasks
- Mark tasks complete

Example list:

```text
Today

[ ] Read paper
[ ] Reply email
[x] Buy coffee
[ ] Finish report
```

### 2.2 Quick Add

Users can add a task by:

- Clicking the final `+ Add Task` row
- Pressing `Cmd + N`
- Typing directly into the new task field

### 2.3 Auto Save

There is no manual save action. Task and setting changes are saved automatically with SwiftData as the user types or edits.

### 2.4 Drag Sorting

Task order is part of the core experience. SwiftUI `.onMove()` can support manual reordering.

```text
[=] Read paper
[=] Meeting
[=] Gym
```

### 2.5 Desktop Mode

Desktop mode is the defining product feature.

Window behavior:

- Optional hidden Dock icon
- Translucent window background
- Optional always-on-top mode
- Optional non-focus-stealing behavior

Example placement:

```text
+-------------+
| Today       |
| [ ] Paper   |
| [ ] Gym     |
| [ ] Meeting |
+-------------+
```

### 2.6 Launch At Login

The app should be able to open automatically when the user logs into macOS.

### 2.7 Menu Bar

Menu bar state should show progress, such as `3 / 7`.

Clicking the menu bar item opens a compact task list:

```text
Today

[ ] Paper
[ ] Review
[ ] Meeting
```

## 3. Settings

Keep settings minimal.

### 3.1 General

- Launch at Login
- Always on Top
- Show in Menu Bar

### 3.2 Transparency

- 100%
- 90%
- 80%

### 3.3 Theme

- System
- Light
- Dark

## 4. UI Direction

The interface should feel native to macOS.

Visual guidelines:

- Font: SF Pro
- Background: Material
- Corner radius: 16
- Shadow: subtle

Example layout:

```text
Today
----------------
[ ] Read paper
[ ] Reply reviewer
[x] Meeting
----------------
+ Add Task
```

## 5. Technical Approach

Use Apple official frameworks only. The project should not need third-party dependencies.

| Module | Technology |
| --- | --- |
| UI | SwiftUI |
| Data | SwiftData |
| Settings | AppStorage |
| Widget | WidgetKit, later |
| Menu Bar | MenuBarExtra |
| Login Launch | SMAppService |
| Window Management | AppKit + SwiftUI |

## 6. Proposed Project Structure

```text
DesktopTodo/
├── App/
│   └── DesktopTodoApp.swift
├── Models/
│   └── Task.swift
├── Persistence/
│   └── ModelContainer.swift
├── Views/
│   ├── TodoListView.swift
│   ├── TaskRow.swift
│   ├── AddTaskView.swift
│   └── SettingsView.swift
├── Managers/
│   └── WindowManager.swift
├── Components/
│   ├── CheckBox.swift
│   └── BlurBackground.swift
└── Assets/
```

This structure keeps app entry points, data models, persistence, views, platform managers, reusable components, and assets separate.
