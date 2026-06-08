import SwiftUI

struct ContentView: View {
    @State private var selectedProfile: KeyProfile = TheoryData.circle[0]
    @State private var selectedMode: KeyMode = .major
    @State private var playbackType: ChordPlaybackType = .triad
    @StateObject private var tonePlayer = TonePlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            .frame(height: 280)

            PianoKeyboardStrip(highlightedNotes: selectedProfile.notes(for: selectedMode))
                .frame(height: 86)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(title: "Selected key", value: "\(selectedProfile.displayKey(for: selectedMode)) \(selectedMode.rawValue)")
                    infoRow(title: "Key signature", value: selectedProfile.keySignature)
                    infoRow(title: "Relative", value: selectedProfile.relativeInfo(for: selectedMode))

                    section(title: "Notes in scale", items: [selectedProfile.notes(for: selectedMode).joined(separator: " - ")])
                    section(title: "Common chords", items: selectedProfile.commonChords(for: selectedMode))
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
        .onChange(of: playbackType) {
            playCurrentTonicChord()
        }
        .onChange(of: selectedMode) {
            playCurrentTonicChord()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Circle of Fifths")
                .font(.title2.weight(.semibold))
            Text("Click keys on the wheel to hear chords and inspect scales, harmony, and progressions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Picker("Mode", selection: $selectedMode) {
                ForEach(KeyMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 170)

            Picker("Playback", selection: $playbackType) {
                ForEach(ChordPlaybackType.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Button("Play") {
                playCurrentTonicChord()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title + ":")
                .font(.subheadline.weight(.semibold))
                .frame(width: 108, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private func section(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            ForEach(items, id: \.self) { item in
                Text("- " + item)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func interactiveChordSection(title: String, entries: [ChordEntry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            ForEach(entries, id: \.self) { entry in
                Button {
                    tonePlayer.playChord(root: entry.root, quality: entry.quality)
                } label: {
                    HStack(spacing: 6) {
                        Text("\(entry.numeral): \(entry.symbol)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundStyle(.accent)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
    }

    private func playCurrentTonicChord() {
        let root = selectedProfile.tonic(for: selectedMode)
        let quality = selectedProfile.tonicChordQuality(for: selectedMode, playback: playbackType)
        tonePlayer.playChord(root: root, quality: quality)
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
                        .font(.title3.weight(.bold))
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
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isHighlighted(key) ? Color.accentColor.opacity(0.25) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.black.opacity(0.18), lineWidth: 1)
                            )
                            .overlay(alignment: .bottom) {
                                Text(key)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 2)
                            }
                    }
                }

                ForEach(blackKeys, id: \.note) { black in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isHighlighted(black.note) ? Color.accentColor : Color.black.opacity(0.84))
                        .frame(width: blackWidth, height: proxy.size.height * 0.6)
                        .offset(x: whiteWidth * CGFloat(black.indexAfterWhite + 1) - blackWidth / 2)
                }
            }
        }
        .padding(.horizontal, 1)
    }

    private func isHighlighted(_ note: String) -> Bool {
        let highlightedPitchClasses = Set(highlightedNotes.compactMap(pitchClass(for:)))
        guard let candidate = pitchClass(for: note) else { return false }
        return highlightedPitchClasses.contains(candidate)
    }

    private func pitchClass(for note: String) -> Int? {
        let aliases: [String: String] = [
            "Db": "C#",
            "Eb": "D#",
            "Gb": "F#",
            "Ab": "G#",
            "Bb": "A#",
            "Cb": "B",
            "Fb": "E",
            "E#": "F",
            "B#": "C"
        ]

        let clean = aliases[note.replacingOccurrences(of: "m", with: "")] ?? note.replacingOccurrences(of: "m", with: "")
        let semitones: [String: Int] = [
            "C": 0,
            "C#": 1,
            "D": 2,
            "D#": 3,
            "E": 4,
            "F": 5,
            "F#": 6,
            "G": 7,
            "G#": 8,
            "A": 9,
            "A#": 10,
            "B": 11
        ]

        return semitones[clean]
    }
}
