import SwiftData

@Model
final class Location {
    var name: String
    var lat: Double?
    var long: Double?
    var moments: [Moment] = []

    init(name: String, lat: Double?, long: Double?) {
        self.name = name
        self.lat = lat
        self.long = long
    }
}
