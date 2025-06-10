import AVFoundation
import AudioKit
import AudioKitEX
import AudioKitUI
import SwiftData
import SwiftUI
import SwiftWhisper

@Observable
class AudioRecorderService {
    var audio: Audio?

    private var engine = AudioEngine()
    private var mic: AudioEngine.InputNode?
    private var recorder: NodeRecorder?
    private var file: AVAudioFile?
    private var mixer = Mixer()
    private var stopTimer: Timer?
    var onStop: (() -> Void)?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )
    }

    func startRecording() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [
                    .duckOthers,
                    .interruptSpokenAudioAndMixWithOthers,
                ]
            )
            try AVAudioSession.sharedInstance().setActive(true)

            // Safely unwrap the engine's input node
            guard let inputNode = engine.input else {
                print("⛔️ No input node available – cannot start recording.")
                return
            }
            mic = inputNode

            // Now initialize the recorder with the non-nil mic
            recorder = try NodeRecorder(node: inputNode)

            try recorder?.record()

            // Also guard before force-unwrapping mic again for the Fader
            engine.output = Fader(inputNode, gain: 0)
            try engine.start()

            stopTimer = Timer.scheduledTimer(
                withTimeInterval: 120,
                repeats: false
            ) { _ in
                self.stopRecording()
            }
        } catch {
            print("Recording start error: \(error)")
        }
    }

    func stopRecording() {
        recorder?.stop()
        engine.stop()
        stopTimer?.invalidate()
        file = recorder?.audioFile
        saveAudioData()

        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )

        onStop?()
    }

    func cancelRecording() {
        recorder?.stop()
        engine.stop()
        stopTimer?.invalidate()
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )
    }

    private func saveAudioData() {
        guard
            let fileURL = file?.url,
            let blob = try? Data(contentsOf: fileURL)
        else { return }

        let newAudio = Audio(data: blob)
        audio = newAudio
    }
}
