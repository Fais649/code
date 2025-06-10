import AVFoundation
import AudioKit
import AudioKitEX
import AudioKitUI
import SwiftData
import SwiftUI
import SwiftWhisper

@Observable
class AudioPlayerService {
    var isPlaying = false
    var isPaused = false

    private var engine = AudioEngine()
    var player = AudioPlayer()
    private var file: AVAudioFile?

    var onCompletion: (() -> Void)?

    init() {
        engine.output = player
        player.completionHandler = { [weak self] in
            self?.reset()
            self?.onCompletion?()
        }
    }

    func load(_ audioData: Audio) {
        do {
            try? AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.duckOthers, .mixWithOthers]
            )
            file = try AVAudioFile(forReading: makeAVAudioFile(from: audioData).url)
            try engine.start()
            player.file = file
        } catch {
            print("Loading error: \(error)")
        }
    }

    func makeAVAudioFile(from stored: Audio) throws -> AVAudioFile {
        // 1) Grab the Data blob
        let blob = stored.data

        // 2) Pick a temporary URL (e.g. in Caches) with a proper extension:
        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".caf"  // match whatever format you recorded
        let fileURL = tempDir.appendingPathComponent(filename)

        // 3) Write the Data to disk:
        try blob.write(to: fileURL)

        // 4) Now open it as AVAudioFile:
        return try AVAudioFile(forReading: fileURL)
    }

    var loaded: Bool {
        player.file != nil
    }

    func play() {
        guard player.file != nil else { return }
        if !isPlaying {
            engine.stop()
            try? engine.start()
            player.play()
            isPlaying = true
            isPaused = false
        }
    }

    func pause() {
        if isPlaying {
            player.pause()
            isPlaying = false
            isPaused = true
        }
    }

    func reset() {
        player.stop()
        isPlaying = false
        isPaused = false
        player.seek(time: 0)
    }

    func seek(to time: Double) {
        player.seek(time: time)
    }

    var duration: Double {
        player.duration
    }

    var currentTime: Double {
        player.currentTime
    }
}
