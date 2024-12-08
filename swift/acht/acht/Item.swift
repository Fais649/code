//
//  Item.swift
//  acht
//
//  Created by Faisal Alalaiwat on 21.11.24.
//

import Foundation
import SwiftData

@Model
class Preset {
    var id: UUID = UUID()
    var createdAt: Date
    var strength: Int
    var speed: Int
    var hold: Int

    init(strength: Int = 2, speed: Int = 2, hold: Int = 2) {
        self.strength = strength
        self.speed = speed
        self.hold = hold
        createdAt = Date()
    }
}
