import SwiftData
import SwiftUI

@Model
final class ImageData {
    var position: Int

    @Attribute(.externalStorage)
    var data: Data

    init(position: Int, data: Data) {
        self.position = position
        self.data = data
    }
}
