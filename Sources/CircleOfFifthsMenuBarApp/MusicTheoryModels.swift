import Foundation

enum KeyMode: String, CaseIterable {
    case major = "Major"
    case naturalMinor = "Natural Minor"
    case harmonicMinor = "Harmonic Minor"
    case melodicMinor = "Melodic Minor"

    var isMinor: Bool {
        self != .major
    }
}

enum ChordPlaybackType: String, CaseIterable {
    case triad = "Triad"
    case seventh = "Seventh"
}

enum ChordQuality {
    case major
    case minor
    case diminished
    case augmented
    case dominant7
    case major7
    case minor7
    case halfDiminished7
    case diminished7
    case minorMajor7
    case augmentedMajor7

    var intervals: [Int] {
        switch self {
        case .major:
            return [0, 4, 7]
        case .minor:
            return [0, 3, 7]
        case .diminished:
            return [0, 3, 6]
        case .augmented:
            return [0, 4, 8]
        case .dominant7:
            return [0, 4, 7, 10]
        case .major7:
            return [0, 4, 7, 11]
        case .minor7:
            return [0, 3, 7, 10]
        case .halfDiminished7:
            return [0, 3, 6, 10]
        case .diminished7:
            return [0, 3, 6, 9]
        case .minorMajor7:
            return [0, 3, 7, 11]
        case .augmentedMajor7:
            return [0, 4, 8, 11]
        }
    }
}

struct ChordEntry: Hashable {
    let numeral: String
    let symbol: String
    let root: String
    let quality: ChordQuality
}

struct KeyProfile: Identifiable, Hashable {
    var id: String { majorKey }

    let majorKey: String
    let relativeMinor: String
    let keySignature: String
    let majorScale: [String]
    let naturalMinorScale: [String]

    func displayKey(for mode: KeyMode) -> String {
        mode == .major ? majorKey : relativeMinor
    }

    func tonic(for mode: KeyMode) -> String {
        switch mode {
        case .major:
            return majorKey
        default:
            return relativeMinor.replacingOccurrences(of: "m", with: "")
        }
    }

    func notes(for mode: KeyMode) -> [String] {
        switch mode {
        case .major:
            return majorScale
        case .naturalMinor:
            return naturalMinorScale
        case .harmonicMinor:
            return raisedMinorScale(raiseSixth: false, raiseSeventh: true)
        case .melodicMinor:
            return raisedMinorScale(raiseSixth: true, raiseSeventh: true)
        }
    }

    func relativeInfo(for mode: KeyMode) -> String {
        if mode == .major {
            return "Relative minor: \(relativeMinor)"
        }
        return "Relative major: \(majorKey)"
    }

    func commonChords(for mode: KeyMode) -> [String] {
        let notes = notes(for: mode)
        switch mode {
        case .major:
            let one = chord(notes[0], quality: "")
            let four = chord(notes[3], quality: "")
            let five = chord(notes[4], quality: "")
            let six = chord(notes[5], quality: "m")
            return [
                "I-IV-V: \(one) - \(four) - \(five)",
                "ii-V-I: \(chord(notes[1], quality: "m")) - \(five) - \(one)",
                "I-vi-IV-V: \(one) - \(six) - \(four) - \(five)"
            ]
        case .naturalMinor:
            let one = chord(notes[0], quality: "m")
            let three = chord(notes[2], quality: "")
            let six = chord(notes[5], quality: "")
            let seven = chord(notes[6], quality: "")
            return [
                "i-VI-III-VII: \(one) - \(six) - \(three) - \(seven)",
                "i-iv-v: \(one) - \(chord(notes[3], quality: "m")) - \(chord(notes[4], quality: "m"))",
                "i-VII-VI-VII: \(one) - \(seven) - \(six) - \(seven)"
            ]
        case .harmonicMinor:
            return [
                "i-iv-V: \(chord(notes[0], quality: "m")) - \(chord(notes[3], quality: "m")) - \(chord(notes[4], quality: ""))",
                "ii dim-V-i: \(chord(notes[1], quality: "dim")) - \(chord(notes[4], quality: "")) - \(chord(notes[0], quality: "m"))",
                "i-VI-III+: \(chord(notes[0], quality: "m")) - \(chord(notes[5], quality: "")) - \(chord(notes[2], quality: "+"))"
            ]
        case .melodicMinor:
            return [
                "i-IV-V: \(chord(notes[0], quality: "m")) - \(chord(notes[3], quality: "")) - \(chord(notes[4], quality: ""))",
                "ii-V-i: \(chord(notes[1], quality: "m")) - \(chord(notes[4], quality: "")) - \(chord(notes[0], quality: "m"))",
                "i-III+-VI dim: \(chord(notes[0], quality: "m")) - \(chord(notes[2], quality: "+")) - \(chord(notes[5], quality: "dim"))"
            ]
        }
    }

    func diatonicTriads(for mode: KeyMode) -> [String] {
        diatonicTriadEntries(for: mode).map { "\($0.numeral): \($0.symbol)" }
    }

    func diatonicSevenths(for mode: KeyMode) -> [String] {
        diatonicSeventhEntries(for: mode).map { "\($0.numeral): \($0.symbol)" }
    }

    func diatonicTriadEntries(for mode: KeyMode) -> [ChordEntry] {
        let notes = notes(for: mode)
        switch mode {
        case .major:
            return [
                entry("I", notes[0], .major),
                entry("ii", notes[1], .minor),
                entry("iii", notes[2], .minor),
                entry("IV", notes[3], .major),
                entry("V", notes[4], .major),
                entry("vi", notes[5], .minor),
                entry("vii", notes[6], .diminished)
            ]
        case .naturalMinor:
            return [
                entry("i", notes[0], .minor),
                entry("ii", notes[1], .diminished),
                entry("III", notes[2], .major),
                entry("iv", notes[3], .minor),
                entry("v", notes[4], .minor),
                entry("VI", notes[5], .major),
                entry("VII", notes[6], .major)
            ]
        case .harmonicMinor:
            return [
                entry("i", notes[0], .minor),
                entry("ii", notes[1], .diminished),
                entry("III+", notes[2], .augmented),
                entry("iv", notes[3], .minor),
                entry("V", notes[4], .major),
                entry("VI", notes[5], .major),
                entry("vii", notes[6], .diminished)
            ]
        case .melodicMinor:
            return [
                entry("i", notes[0], .minor),
                entry("ii", notes[1], .minor),
                entry("III+", notes[2], .augmented),
                entry("IV", notes[3], .major),
                entry("V", notes[4], .major),
                entry("vi", notes[5], .diminished),
                entry("vii", notes[6], .diminished)
            ]
        }
    }

    func diatonicSeventhEntries(for mode: KeyMode) -> [ChordEntry] {
        let notes = notes(for: mode)
        switch mode {
        case .major:
            return [
                entry("Imaj7", notes[0], .major7),
                entry("iim7", notes[1], .minor7),
                entry("iiim7", notes[2], .minor7),
                entry("IVmaj7", notes[3], .major7),
                entry("V7", notes[4], .dominant7),
                entry("vim7", notes[5], .minor7),
                entry("viim7b5", notes[6], .halfDiminished7)
            ]
        case .naturalMinor:
            return [
                entry("im7", notes[0], .minor7),
                entry("iim7b5", notes[1], .halfDiminished7),
                entry("IIImaj7", notes[2], .major7),
                entry("ivm7", notes[3], .minor7),
                entry("vm7", notes[4], .minor7),
                entry("VImaj7", notes[5], .major7),
                entry("VII7", notes[6], .dominant7)
            ]
        case .harmonicMinor:
            return [
                entry("imMaj7", notes[0], .minorMajor7),
                entry("iim7b5", notes[1], .halfDiminished7),
                entry("III+maj7", notes[2], .augmentedMajor7),
                entry("ivm7", notes[3], .minor7),
                entry("V7", notes[4], .dominant7),
                entry("VImaj7", notes[5], .major7),
                entry("vii dim7", notes[6], .diminished7)
            ]
        case .melodicMinor:
            return [
                entry("imMaj7", notes[0], .minorMajor7),
                entry("ii7", notes[1], .dominant7),
                entry("III+maj7", notes[2], .augmentedMajor7),
                entry("IV7", notes[3], .dominant7),
                entry("V7", notes[4], .dominant7),
                entry("vim7b5", notes[5], .halfDiminished7),
                entry("viim7b5", notes[6], .halfDiminished7)
            ]
        }
    }

    func tonicChordQuality(for mode: KeyMode, playback: ChordPlaybackType) -> ChordQuality {
        switch mode {
        case .major:
            return playback == .triad ? .major : .major7
        case .naturalMinor:
            return playback == .triad ? .minor : .minor7
        case .harmonicMinor:
            return playback == .triad ? .minor : .minorMajor7
        case .melodicMinor:
            return playback == .triad ? .minor : .minorMajor7
        }
    }

    private func chord(_ root: String, quality: String) -> String {
        return "\(root)\(quality)"
    }

    private func entry(_ numeral: String, _ root: String, _ quality: ChordQuality) -> ChordEntry {
        ChordEntry(numeral: numeral, symbol: symbol(for: root, quality: quality), root: root, quality: quality)
    }

    private func symbol(for root: String, quality: ChordQuality) -> String {
        switch quality {
        case .major:
            return root
        case .minor:
            return root + "m"
        case .diminished:
            return root + "dim"
        case .augmented:
            return root + "+"
        case .dominant7:
            return root + "7"
        case .major7:
            return root + "maj7"
        case .minor7:
            return root + "m7"
        case .halfDiminished7:
            return root + "m7b5"
        case .diminished7:
            return root + "dim7"
        case .minorMajor7:
            return root + "mMaj7"
        case .augmentedMajor7:
            return root + "+maj7"
        }
    }

    private func raisedMinorScale(raiseSixth: Bool, raiseSeventh: Bool) -> [String] {
        var result = naturalMinorScale
        let shouldPreferFlats = majorKey.contains("b") || keySignature.contains("flat")

        if raiseSixth, result.count > 5 {
            result[5] = raisedNote(result[5], preferFlats: shouldPreferFlats)
        }

        if raiseSeventh, result.count > 6 {
            result[6] = raisedNote(result[6], preferFlats: shouldPreferFlats)
        }

        return result
    }

    private func raisedNote(_ note: String, preferFlats: Bool) -> String {
        guard let pc = pitchClass(for: note) else { return note }
        return noteName(for: (pc + 1) % 12, preferFlats: preferFlats)
    }

    private func pitchClass(for note: String) -> Int? {
        let normalized = note.replacingOccurrences(of: "m", with: "")
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

        let clean = aliases[normalized] ?? normalized
        let semitonesFromC: [String: Int] = [
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

        return semitonesFromC[clean]
    }

    private func noteName(for pitchClass: Int, preferFlats: Bool) -> String {
        let sharpNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let flatNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        return (preferFlats ? flatNames : sharpNames)[pitchClass]
    }
}

enum TheoryData {
    static let circle: [KeyProfile] = [
        KeyProfile(
            majorKey: "C",
            relativeMinor: "Am",
            keySignature: "No sharps or flats",
            majorScale: ["C", "D", "E", "F", "G", "A", "B"],
            naturalMinorScale: ["A", "B", "C", "D", "E", "F", "G"]
        ),
        KeyProfile(
            majorKey: "G",
            relativeMinor: "Em",
            keySignature: "1 sharp: F#",
            majorScale: ["G", "A", "B", "C", "D", "E", "F#"],
            naturalMinorScale: ["E", "F#", "G", "A", "B", "C", "D"]
        ),
        KeyProfile(
            majorKey: "D",
            relativeMinor: "Bm",
            keySignature: "2 sharps: F#, C#",
            majorScale: ["D", "E", "F#", "G", "A", "B", "C#"],
            naturalMinorScale: ["B", "C#", "D", "E", "F#", "G", "A"]
        ),
        KeyProfile(
            majorKey: "A",
            relativeMinor: "F#m",
            keySignature: "3 sharps: F#, C#, G#",
            majorScale: ["A", "B", "C#", "D", "E", "F#", "G#"],
            naturalMinorScale: ["F#", "G#", "A", "B", "C#", "D", "E"]
        ),
        KeyProfile(
            majorKey: "E",
            relativeMinor: "C#m",
            keySignature: "4 sharps: F#, C#, G#, D#",
            majorScale: ["E", "F#", "G#", "A", "B", "C#", "D#"],
            naturalMinorScale: ["C#", "D#", "E", "F#", "G#", "A", "B"]
        ),
        KeyProfile(
            majorKey: "B",
            relativeMinor: "G#m",
            keySignature: "5 sharps: F#, C#, G#, D#, A#",
            majorScale: ["B", "C#", "D#", "E", "F#", "G#", "A#"],
            naturalMinorScale: ["G#", "A#", "B", "C#", "D#", "E", "F#"]
        ),
        KeyProfile(
            majorKey: "F#",
            relativeMinor: "D#m",
            keySignature: "6 sharps: F#, C#, G#, D#, A#, E#",
            majorScale: ["F#", "G#", "A#", "B", "C#", "D#", "E#"],
            naturalMinorScale: ["D#", "E#", "F#", "G#", "A#", "B", "C#"]
        ),
        KeyProfile(
            majorKey: "Db",
            relativeMinor: "Bbm",
            keySignature: "5 flats: Bb, Eb, Ab, Db, Gb",
            majorScale: ["Db", "Eb", "F", "Gb", "Ab", "Bb", "C"],
            naturalMinorScale: ["Bb", "C", "Db", "Eb", "F", "Gb", "Ab"]
        ),
        KeyProfile(
            majorKey: "Ab",
            relativeMinor: "Fm",
            keySignature: "4 flats: Bb, Eb, Ab, Db",
            majorScale: ["Ab", "Bb", "C", "Db", "Eb", "F", "G"],
            naturalMinorScale: ["F", "G", "Ab", "Bb", "C", "Db", "Eb"]
        ),
        KeyProfile(
            majorKey: "Eb",
            relativeMinor: "Cm",
            keySignature: "3 flats: Bb, Eb, Ab",
            majorScale: ["Eb", "F", "G", "Ab", "Bb", "C", "D"],
            naturalMinorScale: ["C", "D", "Eb", "F", "G", "Ab", "Bb"]
        ),
        KeyProfile(
            majorKey: "Bb",
            relativeMinor: "Gm",
            keySignature: "2 flats: Bb, Eb",
            majorScale: ["Bb", "C", "D", "Eb", "F", "G", "A"],
            naturalMinorScale: ["G", "A", "Bb", "C", "D", "Eb", "F"]
        ),
        KeyProfile(
            majorKey: "F",
            relativeMinor: "Dm",
            keySignature: "1 flat: Bb",
            majorScale: ["F", "G", "A", "Bb", "C", "D", "E"],
            naturalMinorScale: ["D", "E", "F", "G", "A", "Bb", "C"]
        )
    ]
}
