import SwiftData
import SwiftUI

@Model
final class Images {
    @Relationship(deleteRule: .cascade)
    var data: [ImageData]

    init(data: [ImageData]) {
        self.data = data
    }
}
