# MacPomodoro (macOS Menu Bar App)

A macOS menu bar Pomodoro timer built with SwiftUI.

## Features

- Menu bar timer with quick popover UI
- Work / Short Break / Long Break sessions
- Configurable durations and long-break cadence
- Global keyboard shortcuts (customizable)
- Local notifications at session transitions
- Session notes for work blocks
- Stats:
  - Today: completed pomodoros, focus minutes
  - Last 7 days: bar chart
  - All-time: total pomodoros, focus hours, current/best streak
- CSV export of all sessions

## Requirements

- macOS 14.0+
- Xcode 15+ (recommended)

## Run Locally

1. Clone the repo
2. Open `Pomodoro.xcodeproj` in Xcode
3. Build and run the `Pomodoro` scheme

## Build

Release export script:

```bash
./build.sh
```

Output: `~/Desktop/MacPomodoroExport/MacPomodoro.app`

## How To Use

- Left-click menu bar tomato icon: open/close timer popover
- Right-click menu bar icon: quit app
- Timer tab: start/pause/reset/skip, add work note
- Stats tab: view stats, export CSV
- Prefs tab: durations, break cadence, sound, shortcuts

### Default Shortcuts

- Start: `⌃⌥⌘↑`
- Interrupt/Pause: `⌃⌥⌘←`
- Resume: `⌃⌥⌘→`

## Data

- Local-only storage
- SQLite DB: `~/Library/Application Support/Pomodoro/pomodoro.db`
- Preferences/shortcuts: `UserDefaults`
- No sync/analytics/tracking

## Stack

- Swift + SwiftUI (menu bar app)
- GRDB (SQLite persistence)
- Charts (weekly activity chart)
- UserNotifications (session-end alerts)
- Carbon Hotkeys (global shortcuts)

## Project Structure

- `Pomodoro/Views` - timer, stats, preferences UI
- `Pomodoro/Helpers` - hotkeys and notifications
- `Pomodoro/Persistence` - DB + CSV export
- `build.sh` - archive/export script


## Optional auto-start at login

` osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/MacPomodoro.app", hidden:false}'`

## Roadmap
- Custom sounds

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

This project was developed with significant AI assistance and is provided on an "AS IS" basis, without warranties or conditions of any kind.
