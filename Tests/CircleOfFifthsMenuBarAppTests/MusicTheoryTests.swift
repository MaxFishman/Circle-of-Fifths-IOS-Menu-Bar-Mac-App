import XCTest
@testable import CircleOfFifthsMenuBarApp

final class MusicTheoryTests: XCTestCase {
    func testAllScalesHaveExpectedIntervalsAndDiatonicSpellings() {
        let intervals: [KeyMode: [Int]] = [
            .major: [0, 2, 4, 5, 7, 9, 11],
            .naturalMinor: [0, 2, 3, 5, 7, 8, 10],
            .harmonicMinor: [0, 2, 3, 5, 7, 8, 11],
            .melodicMinor: [0, 2, 3, 5, 7, 9, 11]
        ]
        for profile in TheoryData.circle {
            for mode in KeyMode.allCases {
                let notes = profile.notes(for: mode)
                let pitches = notes.compactMap(Note.pitchClass)
                XCTAssertEqual(pitches.count, 7, "\(profile.majorKey) \(mode)")
                guard pitches.count == 7 else { continue }
                XCTAssertEqual(pitches.map { ($0 - pitches[0] + 12) % 12 }, intervals[mode])
                XCTAssertEqual(Set(notes.compactMap(\.first)).count, 7)
            }
        }
        let sharpKey = TheoryData.circle.first { $0.majorKey == "F#" }!
        XCTAssertEqual(sharpKey.notes(for: .melodicMinor), ["D#", "E#", "F#", "G#", "A#", "B#", "C##"])
        let flatKey = TheoryData.circle.first { $0.majorKey == "Db" }!
        XCTAssertEqual(flatKey.notes(for: .harmonicMinor).last, "A")
    }

    func testDiatonicChordsMatchScaleDegrees() {
        for profile in TheoryData.circle {
            for mode in KeyMode.allCases {
                let scale = profile.notes(for: mode).compactMap(Note.pitchClass)
                for entries in [profile.diatonicTriadEntries(for: mode), profile.diatonicSeventhEntries(for: mode)] {
                    for (degree, chord) in entries.enumerated() {
                        let pitches = chord.quality.intervals.map { (scale[degree] + $0) % 12 }
                        let expected = (0..<pitches.count).map { scale[(degree + $0 * 2) % 7] }
                        XCTAssertEqual(pitches, expected, "\(profile.majorKey) \(mode) \(chord.numeral)")
                    }
                }
            }
        }
    }

    func testProgressionsUseDiatonicTriads() {
        for profile in TheoryData.circle {
            for mode in KeyMode.allCases {
                let triads = profile.diatonicTriadEntries(for: mode)
                let progressions = profile.progressions(for: mode)
                XCTAssertEqual(progressions.count, 3)
                XCTAssertEqual(Set(progressions.map(\.id)).count, 3)
                XCTAssertEqual(profile.commonChords(for: mode), progressions.map(\.description))
                for progression in progressions {
                    XCTAssertFalse(progression.chords.isEmpty)
                    XCTAssertTrue(progression.chords.allSatisfy { triads.contains($0) })
                }
            }
        }
    }

    func testPitchClassesHandleEnharmonicsAndInvalidNotes() {
        XCTAssertEqual(Note.pitchClass("C##"), Note.pitchClass("D"))
        XCTAssertEqual(Note.pitchClass("B#"), Note.pitchClass("C"))
        XCTAssertEqual(Note.pitchClass("Cb"), Note.pitchClass("B"))
        XCTAssertNil(Note.pitchClass("C4"))
        XCTAssertNil(Note.pitchClass(""))
    }
}
