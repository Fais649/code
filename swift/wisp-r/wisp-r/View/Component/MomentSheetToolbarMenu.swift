import PhotosUI
import SwiftData
import SwiftUI

struct MomentSheetToolbarMenu: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var moment: Moment
    @State private var showPhotosPicker: Bool = false
    @State private var showAudioRecorder: Bool = false
    @State var selectedPhotos: [PhotosPickerItem] = []

    func addPhotos() {
        Task {
            for (index, pickerItem) in selectedPhotos.enumerated() {
                if let imageDataBlob = try? await pickerItem.loadTransferable(type: Data.self) {
                    let newImage = ImageData(position: index, data: imageDataBlob)
                    modelContext.insert(newImage)

                    if moment.images == nil {
                        moment.images = Images(data: [newImage])
                    }

                    moment.images?.data.append(newImage)
                }
            }

            try? modelContext.save()
            selectedPhotos.removeAll()
        }
    }

    var body: some View {
        Menu {
            Button {
                if let images = moment.images {
                    modelContext.delete(images)
                    moment.images = nil
                } else {
                    showPhotosPicker = true
                }
            } label: {
                Label(
                    moment.images == nil ? "Add photos" : "Delete photos",
                    systemImage: "photo")
            }

            Button {
                if let audio = moment.audio {
                    modelContext.delete(audio)
                } else {
                    showAudioRecorder = true
                }
            } label: {
                Label(
                    moment.audio == nil ? "Record memo" : "Delete memo",
                    systemImage: "microphone")
            }
        } label: {
            Image(systemName: "link")
        }
        .onChange(of: selectedPhotos) {
            if selectedPhotos.isNotEmpty {
                addPhotos()
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotos,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showAudioRecorder) {
            AudioRecorderView(audio: $moment.audio)
        }
    }
}
