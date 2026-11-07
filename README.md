# Circle of Fifths Menu Bar App (macOS)

A lightweight native macOS menu bar utility for exploring the Circle of Fifths.

When you click the menu bar icon, a popover opens with an interactive circle:

- Outer ring: major keys
- Inner ring: relative minor keys
- Click any key to hear it and view related music theory details

## Features

- Native menu bar app using SwiftUI `MenuBarExtra`
- Interactive visual Circle of Fifths
- Major, natural minor, harmonic minor, and ascending melodic minor scales
- Clickable piano keyboard and scale notes, with enharmonic scale spelling
- Tonic, triad, seventh chord, or arpeggio playback for the selected key
- Playable diatonic chords and common progressions
- Save favorite keys and common progressions locally between launches
- Music theory panel with:
- Major/minor key context
- Key signature
- Relative major/minor relationship
- Notes in the selected scale
- Common chord progressions
- Diatonic triads
- Diatonic seventh chords

Select a mode and playback style using the menus above the wheel. The playback
style applies to the selected key; chord and progression buttons play their
listed chords together, or as arpeggios when Arpeggio is selected. Click the
star beside a key or common progression to save it. Select a favorite to restore
its key and mode (and play the progression, if applicable), or use its trash
button to remove it. Favorites are stored in macOS user defaults.

Melodic minor uses the ascending form for the displayed notes and harmony.
The displayed key signature is the relative major/natural minor signature;
raised minor-scale notes are shown in the scale rather than the signature.

## Project Structure

- `Package.swift` - Swift package definition for macOS app target
- `Sources/CircleOfFifthsMenuBarApp/CircleOfFifthsMenuBarApp.swift` - app entry point and menu bar scene
- `Sources/CircleOfFifthsMenuBarApp/ContentView.swift` - circle UI and theory panels
- `Sources/CircleOfFifthsMenuBarApp/MusicTheoryModels.swift` - key data and chord/progression logic
- `Sources/CircleOfFifthsMenuBarApp/TonePlayer.swift` - AVFoundation sine-wave tone generator
- `Sources/CircleOfFifthsMenuBarApp/FavoritesStore.swift` - local favorite persistence
- `Tests/CircleOfFifthsMenuBarAppTests` - music theory and persistence tests

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

Max Fishman 2026
