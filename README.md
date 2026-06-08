# Circle of Fifths Menu Bar App (macOS)

A lightweight native macOS menu bar utility for exploring the Circle of Fifths.

When you click the menu bar icon, a popover opens with an interactive circle:

- Outer ring: major keys
- Inner ring: relative minor keys
- Click any key to hear its tonic and view related music theory details

## Features

- Native menu bar app using SwiftUI `MenuBarExtra`
- Interactive visual Circle of Fifths
- Audio playback for selected key tonic
- Music theory panel with:
- Major/minor key context
- Key signature
- Relative major/minor relationship
- Notes in the selected scale
- Common chord progressions
- Diatonic triads
- Diatonic seventh chords

## Project Structure

- `Package.swift` - Swift package definition for macOS app target
- `Sources/CircleOfFifthsMenuBarApp/CircleOfFifthsMenuBarApp.swift` - app entry point and menu bar scene
- `Sources/CircleOfFifthsMenuBarApp/ContentView.swift` - circle UI and theory panels
- `Sources/CircleOfFifthsMenuBarApp/MusicTheoryModels.swift` - key data and chord/progression logic
- `Sources/CircleOfFifthsMenuBarApp/TonePlayer.swift` - AVFoundation sine-wave tone generator

## Requirements

- macOS 14+
- Xcode 15+

## Run In Xcode

1. Open the folder in Xcode (`File > Open...` and select this repo).
2. Let Xcode resolve the Swift package.
3. Select the `CircleOfFifthsMenuBarApp` executable target.
4. Build and run.
5. Click the music-note icon in the macOS menu bar to open the app popover.

## Design Notes

- The app is intentionally compact and utility-like.
- The interface is optimized for quick key selection and immediate feedback.
- The code is split into focused files so you can easily expand with richer harmony modes, custom tunings, MIDI, or alternate scales.

## Suggested Next Enhancements

- Add harmonic/melodic minor mode toggles
- Add piano-keyboard visualization and clickable scale notes
- Add optional triad/arpeggio playback (instead of tonic only)
- Add user presets (favorite keys and progressions)
