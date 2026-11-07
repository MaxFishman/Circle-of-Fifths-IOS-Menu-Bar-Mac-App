import SwiftUI

struct ContentView: View {
    @State private var selectedProfile: KeyProfile = TheoryData.circle[0]
    @State private var selectedMode: KeyMode = .major
    @State private var playbackType: ChordPlaybackType = .triad
    @StateObject private var tonePlayer = TonePlayer()
    @StateObject private var favorites = FavoritesStore()
    private let denseColumns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            controls

            CircleWheelView(
                profiles: TheoryData.circle,
                selectedProfile: selectedProfile,
                selectedMode: selectedMode,
                onSelectMajor: { profile in
                    selectedProfile = profile
                    selectedMode = .major
                    playCurrentTonicChord()
                },
                onSelectMinor: { profile in
                    selectedProfile = profile
                    selectedMode = selectedMode.isMinor ? selectedMode : .naturalMinor
                    playCurrentTonicChord()
                }
            )
            .frame(height: 220)

            PianoKeyboardStrip(highlightedNotes: selectedProfile.notes(for: selectedMode)) { note in
                tonePlayer.playNote(note)
            }
            .frame(height: 62)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    compactInfoGrid
                    if let error = tonePlayer.error {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                    if let error = favorites.error {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                    scaleNotesSection
                    progressionsSection
                    favoritesSection
                    interactiveChordSection(
                        title: "Diatonic triads",
                        entries: selectedProfile.diatonicTriadEntries(for: selectedMode)
                    )
                    interactiveChordSection(
                        title: "Diatonic seventh chords",
                        entries: selectedProfile.diatonicSeventhEntries(for: selectedMode)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(2)
        .onAppear {
            playCurrentTonicChord()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Circle of Fifths")
                .font(.title3.weight(.semibold))
            Text("Click keys on the wheel to hear chords and inspect scales, harmony, and progressions.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Picker("Mode", selection: Binding(
                get: { selectedMode },
                set: { selectedMode = $0; playCurrentTonicChord() }
            )) {
                ForEach(KeyMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 150)

            Picker("Playback", selection: Binding(
                get: { playbackType },
                set: { playbackType = $0; playCurrentTonicChord() }
            )) {
                ForEach(ChordPlaybackType.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.menu)

            Button("Play") {
                playCurrentTonicChord()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button {
                favorites.toggle(profile: selectedProfile, mode: selectedMode)
            } label: {
                Image(systemName: favorites.contains(profile: selectedProfile, mode: selectedMode) ? "star.fill" : "star")
            }
            .help("Toggle favorite key")
            .accessibilityLabel("Toggle favorite key")
        }
        .controlSize(.small)
    }

    private var compactInfoGrid: some View {
        LazyVGrid(columns: denseColumns, alignment: .leading, spacing: 6) {
            compactInfoCell(title: "Selected", value: "\(selectedProfile.displayKey(for: selectedMode)) \(selectedMode.rawValue)")
            compactInfoCell(title: "Relative", value: selectedProfile.relativeInfo(for: selectedMode))
            compactInfoCell(title: "Signature", value: selectedProfile.keySignature)
            compactInfoCell(title: "Playback", value: playbackType.rawValue)
        }
    }

    private func compactInfoCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var scaleNotesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes in scale").font(.subheadline.weight(.semibold))
            HStack {
                ForEach(selectedProfile.notes(for: selectedMode), id: \.self) { note in
                    Button(note) { tonePlayer.playNote(note) }
                        .controlSize(.small)
                        .accessibilityLabel("Play \(note)")
                }
            }
        }
    }

    private var progressionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Common progressions").font(.subheadline.weight(.semibold))
            ForEach(selectedProfile.progressions(for: selectedMode)) { progression in
                HStack {
                    Button {
                        tonePlayer.playProgression(progression.chords, arpeggio: playbackType == .arpeggio)
                    } label: {
                        Label(progression.description, systemImage: "play.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Button {
                        favorites.toggle(profile: selectedProfile, mode: selectedMode, progressionID: progression.id)
                    } label: {
                        Image(systemName: favorites.contains(profile: selectedProfile, mode: selectedMode, progressionID: progression.id) ? "star.fill" : "star")
                    }
                    .buttonStyle(.plain)
                    .help("Toggle favorite progression")
                    .accessibilityLabel("Toggle favorite \(progression.name) progression")
                }
                .font(.caption)
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Favorites").font(.subheadline.weight(.semibold))
            if favorites.favorites.isEmpty {
                Text("Use the stars to save keys and progressions.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(favorites.favorites) { favorite in
                if let profile = TheoryData.circle.first(where: { $0.majorKey == favorite.majorKey }) {
                    HStack {
                        Button {
                            selectedProfile = profile
                            selectedMode = favorite.mode
                            if let id = favorite.progressionID,
                               let progression = profile.progressions(for: favorite.mode).first(where: { $0.id == id }) {
                                tonePlayer.playProgression(progression.chords, arpeggio: playbackType == .arpeggio)
                            } else {
                                playCurrentTonicChord()
                            }
                        } label: {
                            let name = favorite.progressionID.flatMap { id in
                                profile.progressions(for: favorite.mode).first { $0.id == id }?.name
                            }
                            Text("\(profile.displayKey(for: favorite.mode)) \(favorite.mode.rawValue)\(name.map { " - \($0)" } ?? "")")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Button {
                            favorites.remove(favorite)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .help("Remove favorite")
                        .accessibilityLabel("Remove favorite")
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func interactiveChordSection(title: String, entries: [ChordEntry]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: denseColumns, alignment: .leading, spacing: 4) {
                ForEach(entries, id: \.self) { entry in
                    Button {
                        tonePlayer.playChord(root: entry.root, quality: entry.quality, arpeggio: playbackType == .arpeggio)
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(entry.numeral): \(entry.symbol)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption2)
                                .foregroundStyle(.accent)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
    }

    private func playCurrentTonicChord() {
        let root = selectedProfile.tonic(for: selectedMode)
        if playbackType == .tonic {
            tonePlayer.playNote(root)
            return
        }
        let quality = selectedProfile.tonicChordQuality(for: selectedMode, playback: playbackType)
        tonePlayer.playChord(root: root, quality: quality, arpeggio: playbackType == .arpeggio)
    }
}

struct CircleWheelView: View {
    let profiles: [KeyProfile]
    let selectedProfile: KeyProfile
    let selectedMode: KeyMode
    let onSelectMajor: (KeyProfile) -> Void
    let onSelectMinor: (KeyProfile) -> Void

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let outerRadius = min(proxy.size.width, proxy.size.height) * 0.43
            let innerRadius = outerRadius * 0.64

            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.24), lineWidth: 2)
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .position(center)

                Circle()
                    .stroke(Color.secondary.opacity(0.28), lineWidth: 1.5)
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
                    .position(center)

                ForEach(Array(profiles.enumerated()), id: \.element.id) { idx, profile in
                    let angle = Angle.degrees(Double(idx) * 30.0 - 90.0)

                    keyButton(
                        title: profile.majorKey,
                        isSelected: selectedMode == .major && selectedProfile == profile,
                        action: { onSelectMajor(profile) }
                    )
                    .position(point(on: outerRadius, angle: angle, center: center))

                    keyButton(
                        title: profile.relativeMinor,
                        isSelected: selectedMode.isMinor && selectedProfile == profile,
                        action: { onSelectMinor(profile) },
                        compact: true
                    )
                    .position(point(on: innerRadius, angle: angle, center: center))
                }

                VStack(spacing: 2) {
                    Text(selectedMode == .major ? "Major" : "Minor Mode")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(selectedProfile.displayKey(for: selectedMode))
                        .font(.headline.weight(.bold))
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .position(center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func point(on radius: CGFloat, angle: Angle, center: CGPoint) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle.radians) * radius,
            y: center.y + sin(angle.radians) * radius
        )
    }

    private func keyButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        compact: Bool = false
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, compact ? 7 : 9)
                .padding(.vertical, compact ? 4 : 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.primary.opacity(compact ? 0.07 : 0.12))
                )
        }
        .buttonStyle(.plain)
    }
}

struct PianoKeyboardStrip: View {
    let highlightedNotes: [String]
    let onPlay: (String) -> Void

    init(highlightedNotes: [String], onPlay: @escaping (String) -> Void) {
        self.highlightedNotes = highlightedNotes
        self.onPlay = onPlay
    }

    private let whiteKeys = ["C", "D", "E", "F", "G", "A", "B"]
    private let blackKeys: [(note: String, indexAfterWhite: Int)] = [
        ("C#", 0),
        ("D#", 1),
        ("F#", 3),
        ("G#", 4),
        ("A#", 5)
    ]

    var body: some View {
        GeometryReader { proxy in
            let whiteWidth = proxy.size.width / CGFloat(whiteKeys.count)
            let blackWidth = whiteWidth * 0.62

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(whiteKeys, id: \.self) { key in
                        Button {
                            onPlay(displayName(for: key))
                        } label: {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(isHighlighted(key) ? Color.accentColor.opacity(0.25) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                                )
                                .overlay(alignment: .bottom) {
                                    Text(displayName(for: key))
                                        .font(.caption2)
                                        .foregroundStyle(.black)
                                        .padding(.bottom, 2)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Play \(displayName(for: key))")
                    }
                }

                ForEach(blackKeys, id: \.note) { black in
                    Button {
                        onPlay(displayName(for: black.note))
                    } label: {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isHighlighted(black.note) ? Color.accentColor : Color.black.opacity(0.84))
                            .overlay(alignment: .bottom) {
                                if isHighlighted(black.note) {
                                    Text(displayName(for: black.note))
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .padding(.bottom, 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(width: blackWidth, height: proxy.size.height * 0.6)
                    .offset(x: whiteWidth * CGFloat(black.indexAfterWhite + 1) - blackWidth / 2)
                    .accessibilityLabel("Play \(displayName(for: black.note))")
                }
            }
        }
        .padding(.horizontal, 1)
    }

    private func isHighlighted(_ note: String) -> Bool {
        let highlightedPitchClasses = Set(highlightedNotes.compactMap(Note.pitchClass))
        guard let candidate = Note.pitchClass(note) else { return false }
        return highlightedPitchClasses.contains(candidate)
    }

    private func displayName(for note: String) -> String {
        highlightedNotes.first { Note.pitchClass($0) == Note.pitchClass(note) } ?? note
    }
}
