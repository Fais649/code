import AudioKit
import SwiftData
import SwiftUI
import SwiftWhisper

struct AudioRecorderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var recorder = AudioRecorderService()
    @Binding var audio: Audio?
    @Namespace var animation
    @State private var recording: Bool = false

    var body: some View {
        HStack {
            Button {
                if recording {
                    recorder.stopRecording()
                    self.audio = recorder.audio
                    dismiss()
                } else {
                    recorder.startRecording()
                }

                withAnimation {
                    recording.toggle()
                }
            } label: {
                Image(
                    systemName: recording ? "stop.circle.fill" : "circle.fill"
                )
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(height: 60)
                .foregroundStyle(.red)
            }
        }
        .onAppear {
            recorder.onStop = {
                self.audio = recorder.audio
                dismiss()
            }
        }
        .onDisappear {
            if recording {
                recorder.cancelRecording()
            }
        }
    }

    func startTranscription() {
        guard let audioURL = try? audio?.asAVAudioFile().url else { return }
        Task {
            convertAudioFileToPCMArray(fileURL: audioURL) { result in
                let modelURL = Bundle.main.url(
                    forResource: "tiny",
                    withExtension: "bin"
                )!
                let whisper = Whisper(fromFileURL: modelURL)
                switch result {
                case let .success(success):
                    Task {
                        do {
                            let segments =
                                try await whisper
                                .transcribe(audioFrames: success)
                            let transcriptText = segments.map(\.text)
                                .joined()
                            DispatchQueue.main.async {
                                self.audio?.transcript = transcriptText
                            }
                        } catch {
                            print("Transcription error: \(error)")
                        }
                    }
                case let .failure(failure):
                    print("Conversion error: \(failure)")
                }
            }
        }
    }

    func convertAudioFileToPCMArray(
        fileURL: URL,
        completionHandler: @escaping (Result<[Float], Error>) -> Void
    ) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(
            inputURL: fileURL,
            outputURL: tempURL,
            options: options
        )
        converter.start { error in
            if let error {
                completionHandler(.failure(error))
                return
            }

            let data = try! Data(contentsOf: tempURL)

            let floats = stride(from: 44, to: data.count, by: 2).map {
                data[$0..<$0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }

            try? FileManager.default.removeItem(at: tempURL)

            completionHandler(.success(floats))
        }
    }
}
