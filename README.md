<div align="center">
  <img src="logo/logo.png" alt="EasyTODO logo" width="96" />
  <h1>EasyTODO: A minimalist desktop todo list for macOS</h1>
  <h2><strong>An easy to use desktop todo list for macOS.</strong></h2>
  <p>
    <a href="https://github.com/ArabelaTso/easytodo-on-macos/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/ArabelaTso/easytodo-on-macos?style=for-the-badge&label=release&color=2da44e" /></a>
    <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-111827?style=for-the-badge&logo=apple&logoColor=white" />
    <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?style=for-the-badge&logo=swift&logoColor=white" />
    <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-native-0A84FF?style=for-the-badge" />
    <img alt="Local first" src="https://img.shields.io/badge/local--first-no%20cloud-2EA44F?style=for-the-badge" />
    <img alt="License" src="https://img.shields.io/badge/license-MIT-6E7781?style=for-the-badge" />
  </p>
  <p><code>capture -> prioritize -> complete -> stay in flow</code></p>
</div>

EasyTODO is a native macOS desktop todo app designed to stay visible, feel lightweight, and make capture fast. It removes the tedious setup common in task apps: no workspace setup, no cloud account, no project-management ceremony. Just today's tasks, always close at hand.

![EasyTODO feature demo](docs/assets/hero-demo.gif)

## Download

[Download the latest macOS DMG](https://github.com/ArabelaTso/easytodo-on-macos/releases/latest)

- Requires macOS 14 or later.
- Download `EasyTODO-*-macOS-arm64.dmg`, open it, then drag `EasyTODO.app` to `Applications`.
- If macOS blocks the first launch, right-click `EasyTODO.app` and choose `Open`.

## Why EasyTODO

Most todo apps make a simple thought feel like admin work: open a tab, pick a workspace, choose a project, fill metadata, then find the list again later. EasyTODO is built to remove that friction. It behaves like a polished desktop note that can float above your work, save locally, and accept new tasks without breaking your flow.

- **Desktop-first:** keep your list visible in a compact floating window or smaller desktop widget.
- **Fast capture:** add tasks from the bottom row, header popover, or global Quick Add.
- **Local-first:** SwiftData persists tasks on your Mac automatically.
- **Low friction:** fewer steps to capture, prioritize, complete, and review tasks.
- **Native macOS feel:** SwiftUI, AppKit window behavior, materials, and keyboard shortcuts.

## Preview

### Quick Add

![Quick Add demo](docs/assets/quick-add-demo.gif)

### Menu Bar

![Menu Bar demo](docs/assets/menu-bar-demo.gif)

## Features

### Task Management

- Add, complete, delete, reorder, and restore tasks.
- Double-click a task title to edit inline; clicking elsewhere saves the edit.
- Completed tasks are separated from active tasks and newest completions move to the top of the completed group.
- Delete confirmation helps avoid accidental removal; undo delete is available from the app command and context menu.

### Priority Colors

Tasks use four clean color markers instead of verbose labels:

| Color | Meaning |
| --- | --- |
| Red | Important and urgent |
| Yellow | Urgent but not important |
| Green | Important but not urgent |
| Gray | Neither urgent nor important |

New tasks default to green. The UI shows a single color dot picker and keeps the row color strip visible.

### Quick Add

- **Global Quick Add:** press `Command + "+"` (or `Command + Shift + "+"`) to open a translucent input on the current screen. If that shortcut is unavailable, EasyTODO falls back to `Option + Command + N`.
- **Header Quick Add:** click the `+` in the top-right of the main window to open a compact rounded input.
- **Bottom Add Row:** click `Add Task` at the bottom of the window and type directly.
- Press `Return` to save, or `Esc` to dismiss quick inputs.

### Calendar Planning

Click the date header to open the calendar planner. Tasks can be scheduled by day, and legacy unscheduled tasks are normalized to today so existing data remains visible.

### Desktop Window Controls

- Always-on-top mode.
- 100%, 80%, and 50% transparency levels.
- Window close, minimize, and zoom controls moved into a subtle context menu.
- Right-click the main window to adjust window behavior quickly.

### Feedback and Persistence

- Completion sound and a small fireworks effect when a task is completed.
- Autosave on edits, app deactivation, and termination.
- Data is stored in the user's Application Support directory via SwiftData.

### Menu Bar

EasyTODO can show progress in the macOS menu bar, such as `2 / 5`, and provide quick access to today's tasks.

### Desktop Widget

- Open a compact widget from the app menu, menu bar popover, or main window context menu.
- The widget floats above the desktop, joins all Spaces, and can be dragged by its background.
- It shows today's progress, active/done counts, and the first five tasks.
- Click a task in the widget to toggle completion; double-click the widget to reopen the full app.
- Use the widget context menu to open the main app or close the widget.

## Installation

### Requirements

- macOS 14 or later
- Xcode command line tools
- Swift Package Manager with Swift tools 6.0 support

### Run From Source

```sh
git clone git@github.com:ArabelaTso/easytodo-on-macos.git
cd easytodo-on-macos
swift run EasyTODO
```

### Build

```sh
swift build
```

### Build a Release Binary

```sh
swift build -c release
.build/release/EasyTODO
```

### Package a macOS App

```sh
./scripts/package_app.sh
./scripts/package_dmg.sh
```

- `package_app.sh` creates `dist/EasyTODO.app` and `dist/EasyTODO-macOS.zip`.
- `package_dmg.sh` creates `dist/EasyTODO-macOS.dmg` for drag-and-drop installation.
- To install locally, open the DMG and drag `EasyTODO.app` to `Applications`.

For quicker local use:

```sh
./scripts/open_app.sh
./scripts/install_app.sh
```

- `open_app.sh` packages the app if needed, then launches `dist/EasyTODO.app`.
- `install_app.sh` packages the app, copies it to `/Applications`, then launches it.

### Test

```sh
swift test
```

## Usage

1. Launch EasyTODO with `swift run EasyTODO`.
2. Add a task from the bottom `Add Task` row, the top-right `+`, or global Quick Add.
3. Use the color dot to set priority.
4. Check a task to complete it; EasyTODO plays a sound and shows a small celebration.
5. Open the desktop widget from the app menu, menu bar popover, or main window context menu when you want a smaller view.
6. Right-click the window to change always-on-top, transparency, or widget mode.
7. Open Settings to manage launch, menu bar, visibility, transparency, and theme.

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Command + +` | Global Quick Add |
| `Option + Command + N` | Fallback global Quick Add |
| `Command + N` | Focus new task entry |
| `Control + Z` | Undo last deleted task |
| `Return` | Save active quick input |
| `Esc` | Dismiss active quick input |

## Settings

| Setting | Options |
| --- | --- |
| Launch at Login | On / Off |
| Always on Top | On / Off |
| Show in Menu Bar | On / Off |
| Hide Dock Icon | On / Off when menu bar is enabled |
| Transparency | 100%, 90%, 80% |
| Theme | Light, Dark |

## Project Structure

```text
Sources/EasyTODO/
├── App/                 # App entry, settings keys, notifications
├── Components/          # Reusable UI pieces and visual effects
├── Managers/            # AppKit integration: windows, shortcuts, menu bar, login
├── Models/              # SwiftData models and task ordering
├── Persistence/         # SwiftData container setup and store migration
├── Resources/           # Bundled app logo
└── Views/               # Main list, task row, quick add, calendar, settings
Tests/EasyTODOTests/     # XCTest coverage
```

## Technology

| Area | Implementation |
| --- | --- |
| UI | SwiftUI |
| Persistence | SwiftData |
| Settings | AppStorage / UserDefaults |
| Window behavior | AppKit NSWindow / NSPanel |
| Menu bar | AppKit status item and popover |
| Desktop widget | Borderless AppKit NSPanel with SwiftUI content |
| Global shortcut | Carbon hot key registration |
| Login item | ServiceManagement |

## Release Notes

Chronological history, based on Git commits.

| Commit | Tag | Notes |
| --- | --- | --- |
| `1eb8947` | ![chore](https://img.shields.io/badge/-chore-6e7781?style=flat-square) | Initial repository setup. |
| `5bd2978` | ![docs](https://img.shields.io/badge/-docs-0969da?style=flat-square) | Added the first README introduction. |
| `fdd9267` | ![docs](https://img.shields.io/badge/-docs-0969da?style=flat-square) | Reformulated README into a structured product document. |
| `c86d54d` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Implemented the first native desktop todo app. |
| `992cd8f` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Refined the priority color picker. |
| `1d1d063` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Improved note-style window behavior and local persistence. |
| `5b28279` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Added completion sound and visual feedback effects. |
| `0e43f20` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Ordered completed tasks by completion sequence. |
| `d436ba5` | ![chore](https://img.shields.io/badge/-chore-6e7781?style=flat-square) | Renamed the app to EasyTODO. |
| `2921750` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Added calendar-based task scheduling. |
| `e58169e` | ![ui](https://img.shields.io/badge/-ui-bc4c00?style=flat-square) | Polished the window background and app icon. |
| `944662e` | ![ui](https://img.shields.io/badge/-ui-bc4c00?style=flat-square) | Removed the main window titlebar for a cleaner note shape. |
| `f2fca4a` | ![ui](https://img.shields.io/badge/-ui-bc4c00?style=flat-square) | Moved window controls into a context menu. |
| `d2593de` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Added the global Quick Add panel. |
| `4e30bdc` | ![ui](https://img.shields.io/badge/-ui-bc4c00?style=flat-square) | Removed the System theme option; kept Light and Dark. |
| `51d441e` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Added context controls for window behavior and delete undo. |
| `a7dca6a` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Added inline task title editing. |
| `02fca2f` | ![feature](https://img.shields.io/badge/-feature-2da44e?style=flat-square) | Added the top-right header quick task input. |
| `2ff65a7` | ![fix](https://img.shields.io/badge/-fix-c93c37?style=flat-square) | Fixed focus behavior for the bottom Add Task row. |

## Contributing

Contributions are welcome. Keep changes focused and native to macOS.

```sh
swift build
swift test
```

For UI changes, include a screenshot or short GIF. For persistence, ordering, or model changes, add or update XCTest coverage.

## License

This project is licensed under the terms in [LICENSE](LICENSE).
