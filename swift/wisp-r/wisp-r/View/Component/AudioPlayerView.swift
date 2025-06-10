import AudioKit
import SwiftData
import SwiftUI
import SwiftWhisper

struct AudioPlayerView: View {
    init(
        audioData: Audio
    ) {
        self.audio = audioData
    }

    @Bindable var audio: Audio
    @State private var transcribing: Bool = false
    @State private var playerManager: AudioPlayerService? = nil

    var body: some View {
        VStack {
            if audio.transcript.isNotEmpty {
                TextField(
                    "transcript...",
                    text: $audio.transcript,
                    axis: .vertical
                )

                HStack {
                    playerControls()
                    Spacer()
                }
            } else {
                HStack {
                    playerControls()
                    Spacer()
                    transcribeControl()
                }
            }
        }
        .background(.ultraThinMaterial.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private func playerControls() -> some View {
        if let manager = playerManager {
            HStack {
                Button {
                    if manager.isPlaying {
                        manager.pause()
                    } else {
                        manager.play()
                    }
                } label: {
                    Image(
                        systemName: manager
                            .isPlaying ? "pause.circle.fill" : "play.fill"
                    )
                }

                if manager.isPlaying || manager.isPaused {
                    Button {
                        manager.reset()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                }

                Text(formattedTime(manager.duration)).monospacedDigit()
                Spacer()
            }.contentShape(.rect)
        } else {
            Button {
                initializePlayerManagerAndPlay()
            } label: {
                Image(systemName: "play.fill")
            }
        }
    }

    @ViewBuilder
    private func transcribeControl() -> some View {
        VStack {
            if transcribing {
                ProgressView()
                    .task {
                        guard let file = try? audio.asAVAudioFile() else {
                            print("Exception caught")
                            audio.transcript = "[Failed to transcribe]"
                            transcribing = false
                            return
                        }

                        await extractTextFromAudio(file.url) { res in
                            switch res {
                            case let .success(string):
                                if string.isEmpty {
                                    self.audio.transcript = "[Empty audio]"
                                } else {
                                    self.audio.transcript = string
                                }
                            case let .failure(error):
                                print("Failed to transcribe")
                                self.audio.transcript = "[Empty audio]"
                                print(error.localizedDescription)
                            }
                            transcribing = false
                        }
                    }
            } else {
                Button {
                    transcribing = true
                } label: {
                    Image(systemName: "text.viewfinder")
                }
            }
        }
    }

    // MARK: - Lazy Initialization

    private func initializePlayerManagerAndPlay() {
        let manager = AudioPlayerService()
        manager.load(audio)
        manager.onCompletion = { manager.reset() }
        manager.play()
        playerManager = manager
    }

    func formattedTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func extractTextFromAudio(
        _ audioURL: URL,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) async {
        let modelURL = Bundle.main.url(
            forResource: "tiny",
            withExtension: "bin"
        )!
        let whisper = Whisper(fromFileURL: modelURL)
        convertAudioFileToPCMArray(fileURL: audioURL) { result in
            switch result {
            case let .success(success):
                Task {
                    do {
                        let segments =
                            try await whisper
                            .transcribe(audioFrames: success)
                        completionHandler(
                            .success(
                                segments.map(\.text)
                                    .joined()
                            ))
                    } catch {
                        completionHandler(.failure(error))
                    }
                }
            case let .failure(failure):
                completionHandler(.failure(failure))
            }
        }
    }

    func convertAudioFileToPCMArray(
        fileURL: URL,
        completionHandler: @escaping (Result<[Float], Error>) -> Void
    ) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16_000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        // Give the temp file a “.wav” extension so FormatConverter knows what to do:
        let tempFileName = "\(UUID().uuidString).wav"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(tempFileName)

        let converter = FormatConverter(
            inputURL: fileURL,
            outputURL: tempURL,
            options: options
        )

        converter.start { error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            // Now read back the data. If this file is zero-length, that's a problem.
            guard let data = try? Data(contentsOf: tempURL),
                data.count > 44 /* at least WAV header */
            else {
                completionHandler(
                    .failure(
                        NSError(
                            domain: "ConvertError", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Converted WAV is empty"])
                    ))
                return
            }

            // strip off the 44-byte WAV header, convert each 16-bit sample to Float
            let floats: [Float] = stride(from: 44, to: data.count, by: 2).map {
                let range = $0..<$0 + 2
                let littleEndianShort = data[range].withUnsafeBytes {
                    $0.load(as: Int16.self).littleEndian
                }
                return max(-1.0, min(Float(littleEndianShort) / 32767.0, 1.0))
            }

            // Clean up the temp file if you want:
            try? FileManager.default.removeItem(at: tempURL)
            completionHandler(.success(floats))
        }
    }
}
