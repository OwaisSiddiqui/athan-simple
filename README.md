# Athan Simple

A SwiftUI iOS app that calculates and displays Muslim prayer times based on your current location, with a Home Screen widget for quick glance updates.

## Features

- Current prayer, next prayer, and time-to-next (countdown/progress)
- Customizable calculation settings (calculation method, madhab, high-latitude rule, shafaq, and per-prayer adjustments)
- A widget powered by cached prayer times shared from the app via an App Group

## How it works

The app:

1. Uses `CoreLocation` to get the user's location
2. Uses the `Adhan` library to calculate prayer times
3. Saves the latest prayer times + settings to the App Group `group.com.siddiqui.AthanSimple` for the widget

## Setup

1. Open `AthanSimple.xcodeproj` in Xcode
2. Build and run the app on a device
3. Grant Location permission when prompted (required for prayer time calculations)
4. Add the widget (`AthanSimpleWidget`) from the Home Screen widget gallery

## Project structure

- `AthanSimple/`: main app (SwiftUI views, prayer calculation service, settings)
- `AthanSimpleWidget/`: WidgetKit extension
- `AppIcon.icon/`: app icon assets

## Notes

- This repo includes a `.gitignore` to prevent committing Xcode build artifacts (for example `*.xcarchive`) and user-specific workspace files.

## License

License: TBD
