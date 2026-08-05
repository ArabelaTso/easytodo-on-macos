# Repository Guidelines

## Project Structure & Module Organization

This repository contains a Swift Package Manager macOS desktop todo app. `README.md` defines the product scope and run commands. `LICENSE` contains the project license.

The app structure is:

- `Sources/DesktopTodo/App/` for the SwiftUI app entry point.
- `Sources/DesktopTodo/Models/` for SwiftData models such as `TodoTask.swift`.
- `Sources/DesktopTodo/Persistence/` for model container setup.
- `Sources/DesktopTodo/Views/` for screens and rows such as `TodoListView.swift`.
- `Sources/DesktopTodo/Managers/` for AppKit integration such as window behavior.
- `Sources/DesktopTodo/Components/` for reusable UI pieces.
- `Tests/DesktopTodoTests/` for XCTest coverage.

## Build, Test, and Development Commands

Use SwiftPM commands from the repository root:

- `swift build` builds the native macOS app.
- `swift run DesktopTodo` launches the desktop app.
- `swift test` runs the XCTest suite.

Keep command examples updated when packaging changes, such as adding an Xcode project.

## Coding Style & Naming Conventions

Use SwiftUI and Apple framework conventions. Name types in `PascalCase` (`TodoTask`, `TaskRow`, `WindowManager`) and properties, methods, and bindings in `camelCase` (`isCompleted`, `launchAtLogin`). Keep views small and composable, with one primary type per Swift file. Use 4-space indentation for Swift files.

Avoid third-party dependencies unless the README's technical approach changes.

## Testing Guidelines

Add unit tests for model and persistence behavior, and UI tests for core flows when an app test host exists: creating, editing, completing, deleting, and reordering tasks. Name tests after behavior, for example `testTaskCanBeMarkedComplete`. Run `swift test` before opening a pull request.

## Commit & Pull Request Guidelines

Git history currently uses short, imperative commit messages such as `Update readme, add brief introduction`. Continue that style: start with a verb and describe the changed area.

Pull requests should include a concise summary, screenshots or screen recordings for UI changes, linked issues when available, and the commands used to validate the change.

## Agent-Specific Instructions

Keep generated documentation concise and aligned with the current repo state. Do not describe future app capabilities as complete unless source and tests support them.
