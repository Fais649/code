import SwiftData
import SwiftUI

struct MomentSheetImageRow: View {
    struct ImageObject {
        var position: Int
        var image: Image
    }

    let images: Images
    @State private var imageObjects: [ImageObject] = []

    func loadImages() {
        for d in images.data {
            if let i = loadImage(from: d) {
                let o = ImageObject(position: d.position, image: i)
                imageObjects.append(o)
            }
        }
    }

    func loadImage(from imageData: ImageData) -> Image? {
        guard let uiImage = UIImage(data: imageData.data) else { return nil }
        return Image(uiImage: uiImage)
    }

    var body: some View {
        TabView {
            ForEach(imageObjects.sorted(by: { $0.position < $1.position }), id: \.position) {
                imageObject in
                imageObject.image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(.rect(cornerRadius: 5))
            }
        }
        .contentMargins(Spacing.s)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .task {
            loadImages()
        }
        .animation(.smooth, value: imageObjects.count)
    }
}
