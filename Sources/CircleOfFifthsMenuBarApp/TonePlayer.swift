import AVFoundation
import Foundation

@MainActor
final class TonePlayer: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    func playChord(root: String, quality: ChordQuality) {
        guard let rootFrequency = frequency(for: root) else { return }
        let frequencies = quality.intervals.map { rootFrequency * pow(2.0, Double($0) / 12.0) }
        let buffer = makeChordBuffer(frequencies: frequencies, duration: 0.5)

        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)

        if !player.isPlaying {
            player.play()
        }
    }

    private func makeChordBuffer(frequencies: [Double], duration: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else {
            return buffer
        }

        let voiceGain = 0.24 / max(1.0, Double(frequencies.count))

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let fade = min(1.0, Double(frame) / 500.0) * min(1.0, Double(Int(frameCount) - frame) / 500.0)
            let sample = frequencies.reduce(0.0) { partial, frequency in
                partial + sin(2.0 * Double.pi * frequency * t)
            } * voiceGain * fade
            channel[frame] = Float(sample)
        }

        return buffer
    }

    private func frequency(for note: String) -> Double? {
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

        let clean = aliases[note] ?? note
        let semitonesFromC4: [String: Int] = [
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

        guard let semitone = semitonesFromC4[clean] else { return nil }

        let midi = 60 + semitone
        return 440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }
}
