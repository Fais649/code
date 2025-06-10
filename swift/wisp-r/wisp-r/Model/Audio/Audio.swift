import AVFoundation
import SwiftData
import SwiftUI

@Model
final class Audio {
    init(data: Data) {
        self.data = data
    }

    @Attribute(.externalStorage) var data: Data

    var transcript: String = ""

    func asAVAudioFile() throws -> AVAudioFile {
        let blob = data
        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".caf"  // match whatever format you recorded
        let fileURL = tempDir.appendingPathComponent(filename)
        try blob.write(to: fileURL)
        return try AVAudioFile(forReading: fileURL)
    }
}
