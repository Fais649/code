//
//  ContentView.swift
//  acht
//
//  Created by Faisal Alalaiwat on 21.11.24.
//

import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var presets: [Preset]
    @State var preset: Preset = .init()

    private var defaultPreset: Preset {
        if let val = presets.first {
            return val
        }

        let preset = Preset()
        modelContext.insert(preset)
        return preset
    }

    var body: some View {
        NavigationStack {
            Breather(preset: $preset, moving: false)

            NavigationLink {
                EditPresetView(preset: $preset)
            } label: {
                Text("EDIT_PRESET")
            }
            // List {
            //     ForEach(presets) { preset in
            //         NavigationLink {
            //             EditPresetView(preset)
            //         } label: {
            //             Text("PRESET")
            //         }
            //     }
            //     .onDelete(perform: deletePresets)
            // }
            .toolbar {
                // ToolbarItem(placement: .navigationBarTrailing) {
                //     EditButton()
                // }
                // ToolbarItem {
                //     Button(action: addPreset) {
                //         Label("Add Preset", systemImage: "plus")
                //     }
                // }
            }.scrollContentBackground(.hidden)
            .listRowSeparator(.hidden)
            .listRowSpacing(5)
            .onAppear {
                preset = defaultPreset
            }
        }
    }

    private func addPreset() {
        withAnimation {
            let newPreset = Preset()
            modelContext.insert(newPreset)
        }
    }

    private func deletePresets(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(presets[index])
            }
        }
    }
}

struct Breather: View {
    @Binding var preset: Preset
    @State var moving: Bool

    private var duration: Double {
        return Double(10 / preset.speed)
    }

    private var spin: Double {
        return Double((preset.strength * 360) + 45)
    }

    private var delay: TimeInterval {
        return TimeInterval(preset.hold * 2)
    }

    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: moving ? 110 : 20)
                    .fill(.white)
                    .strokeBorder(.white, lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(moving ? -45 : -spin))
                    .blendMode(.difference)
                    .offset(y: moving ? 93 : 0)
                    .scaleEffect(moving ? 1.1 : 1)
            }

            ZStack {
                RoundedRectangle(cornerRadius: moving ? 110 : 20)
                    .fill(.white)
                    .strokeBorder(.white, lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(moving ? 45 : spin))
                    .blendMode(.difference)
                    .offset(y: moving ? -93 : 0)
                    .scaleEffect(moving ? 1.1 : 1)
            }
        }.frame(width: .infinity, height: 500)
            .animation(.easeInOut(duration: duration)
                .delay(delay).repeatForever(), value: moving)
            .padding()
            .compositingGroup()
            .onAppear {
                moving = false
                startAnimation()
            }
            .onChange(of: preset) {
                moving = false
                startAnimation()
            }
    }

    private func startAnimation() {
        moving = false
        withAnimation(
            .easeInOut(duration: duration)
                .delay(delay)
                .repeatForever(autoreverses: true)
        ) {
            moving = true
        }
    }
}

struct EditPresetView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var preset: Preset

    var body: some View {
        HStack {
            PresetMeter(label: "strength", value: $preset.strength, maxValue: 4)
            PresetMeter(label: "speed", value: $preset.speed, maxValue: 4)
            PresetMeter(label: "hold", value: $preset.hold, maxValue: 4)
        }
        .navigationTitle("Preset")
    }
}

struct PresetMeter: View {
    @Environment(\.modelContext) private var modelContext
    var label: String
    @Binding var value: Int
    var maxValue: Int

    var body: some View {
        VStack {
            Text(label)
            VStack {
                ForEach(1 ..< (maxValue + 1)) { index in
                    RoundedRectangle(cornerRadius: 30).fill(maxValue + 1 - index <= value ? .black : .clear)
                        .strokeBorder(.black, lineWidth: 1)
                }
            }.frame(width: 55, height: 240, alignment: .bottom)
                .padding()

            Text("\(value)")
            Button {
                withAnimation {
                    if value < 4 {
                        value += 1
                    }
                }
            } label: {
                RoundedRectangle(cornerRadius: 15).fill(.black).strokeBorder(.black, lineWidth: 1)
                    .frame(width: 30, height: 30).overlay {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
            }

            Button {
                withAnimation {
                    if value > 1 {
                        value -= 1
                    }
                }
            } label: {
                RoundedRectangle(cornerRadius: 15).fill(.white).strokeBorder(.black, lineWidth: 1)
                    .frame(width: 30, height: 30).overlay {
                        Image(systemName: "minus")
                            .foregroundStyle(.black)
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Preset.self, inMemory: true)
}
