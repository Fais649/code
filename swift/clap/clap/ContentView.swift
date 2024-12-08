//
//  ContentView.swift
//  clap
//
//  Created by Faisal Alalaiwat on 30.11.24.
//

import AVFoundation
import Combine
import SwiftData
import SwiftUI

class AudioManager: ObservableObject {
    private let audioEngine = AVAudioEngine()
    @Published var clapCount = 0

    private var isClapDetected = false
    private let threshold: Float = 0.05
    private var lastClapTime = Date()

    init() {
        configureAudioSession()
    }

    func startClapDetection() {
        if !audioEngine.isRunning {
            startAudioEngine()
        }
    }

    func stopClapDetection() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func startAudioEngine() {
        let inputNode = audioEngine.inputNode
        let bus = 0
        let inputFormat = inputNode.outputFormat(forBus: bus)

        inputNode.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine couldn't start: \(error)")
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let channelDataValue = stride(from: 0,
                                      to: Int(buffer.frameLength),
                                      by: buffer.stride).map { channelData[$0] }

        let rms = sqrt(channelDataValue.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))

        detectClap(rms: rms)
    }

    private func detectClap(rms: Float) {
        if rms > threshold && !isClapDetected {
            let currentTime = Date()
            if currentTime.timeIntervalSince(lastClapTime) > 0.1 {
                isClapDetected = true
                lastClapTime = currentTime
                DispatchQueue.main.async {
                    self.clapCount += 1
                }
            }
        } else if rms < threshold * 0.5 {
            isClapDetected = false
        }
    }
}

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var maxCountdown: Int = 21
    @State private var countdown: Int = 20
    @State private var isDetecting: Bool = false
    @State private var infoClicked: Bool = false
    @State private var infoClicked2: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()

                if isDetecting {
                    HStack {
                        // Text("\(countdown)")
                        //     .font(.custom("GohuFont11NFM", size: 12))
                        //     .foregroundColor(.red)
                        ForEach(1 ..< maxCountdown) { i in
                            RoundedRectangle(cornerRadius: 20).fill(i > countdown ? .black : .red).frame(height: 10).border(.red)
                        }
                    }.padding()

                    Text("\(audioManager.clapCount)")
                        .font(.custom("GohuFont11NFM", size: 64))
                        .padding()

                    // Text("claps")
                    //     .font(.custom("GohuFont11NFM", size: 16))

                    Button(action: stopDetection) {
                        Image(systemName: "stop")
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .foregroundColor(.black)
                            .cornerRadius(150)
                    }
                } else {
                    VStack {
                        Text("clap_r")
                            .padding()
                            .font(.custom("GohuFont11NFM", size: 96))

                        HStack {
                            Button(action: startDetection) {
                                Text("countDown()")
                            }.buttonStyle(.plain)
                                .padding(5)
                                .foregroundColor(.black)
                                .background {
                                    RoundedRectangle(cornerRadius: 20).fill(.yellow)
                                        .frame(width: 160)
                                }
                                .font(.custom("GohuFont11NFM", size: 18))
                                .frame(width: 160)

                            Button(action: { infoClicked.toggle() }) {
                                Image(systemName: "info")
                                    .foregroundStyle(.black)
                                    .background {
                                        RoundedRectangle(cornerRadius: 120)
                                            .fill(.yellow)
                                            .frame(width: 20, height: 20)
                                    }
                                    .padding()
                                    .popover(isPresented: $infoClicked) {
                                        Text("TIME-ATTACK!\n See how many claps you can hit before time runs out!")
                                            .multilineTextAlignment(.center)
                                            .padding()
                                            .presentationDetents([.fraction(0.2)])
                                            .presentationBackground(.black)
                                    }
                            }
                        }
                        HStack {
                            Button(action: startDetection) {
                                Text("survival()")
                            }.buttonStyle(.plain)
                                .padding(5)
                                .foregroundColor(.black)
                                .background {
                                    RoundedRectangle(cornerRadius: 20).fill(.yellow)
                                        .frame(width: 160)
                                }
                                .font(.custom("GohuFont11NFM", size: 18))
                                .frame(width: 160)

                            Button(action: { infoClicked2.toggle() }) {
                                Image(systemName: "info")
                                    .foregroundStyle(.black)
                                    .background {
                                        RoundedRectangle(cornerRadius: 120)
                                            .fill(.yellow)
                                            .frame(width: 20, height: 20)
                                    }
                                    .padding()
                                    .popover(isPresented: $infoClicked2) {
                                        Text("SURIVE!\n THE GAME FINISHES WHEN YOU DO. CLAP TILL YOU CAN'T CLAP NO MORE!")
                                            .multilineTextAlignment(.center)
                                            .padding()
                                            .presentationDetents([.fraction(0.2)])
                                            .presentationBackground(.black)
                                    }
                            }
                        }
                    }
                }

                Spacer()
            }
            .font(.custom("GohuFont11NFM", size: 14))
            .foregroundStyle(.white)
        }
    }

    // Timer-related properties
    @State private var timerSubscription: AnyCancellable?

    func startDetection() {
        // Reset states
        audioManager.clapCount = 0
        countdown = 20
        isDetecting = true

        // Start clap detection
        audioManager.startClapDetection()

        // Start the countdown timer
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if countdown > 0 {
                    countdown -= 1
                } else {
                    stopDetection()
                }
            }
    }

    func stopDetection() {
        // Stop clap detection and timer
        audioManager.stopClapDetection()
        timerSubscription?.cancel()
        isDetecting = false
    }
}

#Preview {
    ContentView()
}
