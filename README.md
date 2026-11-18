# MyCalendar (Widget + Editor prototype)

This project builds a macOS editor app with an embedded WidgetKit extension.
The widget displays the current month and supports interactive task completion.
Clicking a day opens the editor app at that date. In the editor, the top field
adds a task with Return; clicking an existing task title edits it inline; Return
commits and Escape cancels. Trash removes a task.

## Build on macOS

Requires macOS 14 or later and Xcode 15 or later.

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project MyCalendar.xcodeproj -scheme MyCalendarEditor -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO
```

GitHub Actions workflow: copy `.github-workflow-build-macos.yml` to
`.github/workflows/build-macos.yml`.

## Data

The app and widget use the App Group `group.com.moongchy.MyCalendar` and
`calendar.json`. If that file does not exist, the app attempts a one-time import
from `~/Library/Application Support/NamaneCalendar/calendar.json` and saves the
migrated entries to the new shared location.

The previous `notes` and `done` arrays are migrated into task items. Existing
circled-date flags are retained.

## Important testing notes

- This source package has not been compiled on macOS in this environment.
- The App Group identifier must be registered in the Apple Developer account
  for a properly signed/notarized distribution. For local unsigned testing the
  code falls back to the user's Application Support directory if the App Group
  container is unavailable.
- Widget refresh is controlled by WidgetKit and is not guaranteed to be
  instantaneous in every situation.
- The current prototype supports the system small/medium/large/extra-large
  families where available. macOS decides the actual widget size and placement.
