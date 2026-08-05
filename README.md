## 产品定位

一句话：

A simple todo list that always stays on your desktop.

三个关键词：

Always Visible（始终可见）
Lightweight（轻量）
Beautiful（美观）

不是效率系统。

不是 GTD。

不是 Notion。

就是一张一直放在桌面的 Todo List。

MVP 功能（V1.0）

我建议只做下面这些。

① Todo 列表
Today

□ Read paper

□ Reply email

☑ Buy coffee

□ Finish report

支持：

新建
编辑
删除
勾选完成
② 快速新增

点击最后一行

+ Add Task

或者快捷键：

⌘ N

直接输入。

③ 自动保存

不用 Save。

每输入一个字：

SwiftData

自动保存。

④ 拖拽排序
☰ Read paper

☰ Meeting

☰ Gym

SwiftUI 已经支持：

.onMove()

这是 Todo 的核心体验之一。

⑤ Desktop Mode

这是整个产品最大的特点。

窗口：

✅ 无 Dock Icon（可选）

✅ 半透明

✅ Always On Top（可选）

✅ 不抢焦点（可选）

可以一直放在桌面右侧：

┌─────────────┐

 Today

 □ Paper

 □ Gym

 □ Meeting

└─────────────┘
⑥ 开机启动

用户打开电脑：

Todo 自动出现。

这是桌面工具应该有的。

⑦ Menu Bar

菜单栏：

✔ 3 / 7

点一下：

Today

□ Paper

□ Review

□ Meeting

不用打开主窗口。

设置（不用很多）
General

✓ Launch at Login

✓ Always on Top

✓ Show in Menu Bar

Transparency

○ 100%

○ 90%

○ 80%

Theme

○ System

○ Light

○ Dark

就够了。

UI

建议像 macOS 原生。

Today

────────────────

○ Read paper

○ Reply reviewer

✓ Meeting

────────────────

+ Add Task

字体：

SF Pro

背景：

Material

圆角：

16

阴影：

轻一点。

技术方案

全部使用苹果官方框架。

模块	技术
UI	SwiftUI
数据	SwiftData
设置	AppStorage
Widget	WidgetKit（后续）
菜单栏	MenuBarExtra
登录启动	SMAppService
窗口管理	AppKit + SwiftUI

整个项目不需要任何第三方依赖。

项目结构
DesktopTodo/
│
├── App/
│     DesktopTodoApp.swift
│
├── Models/
│     Task.swift
│
├── Persistence/
│     ModelContainer.swift
│
├── Views/
│     TodoListView.swift
│     TaskRow.swift
│     AddTaskView.swift
│     SettingsView.swift
│
├── Managers/
│     WindowManager.swift
│
├── Components/
│     CheckBox.swift
│     BlurBackground.swift
│
└── Assets/

这样维护起来会很舒服。
