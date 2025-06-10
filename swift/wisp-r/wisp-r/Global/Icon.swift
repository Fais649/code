import SwiftUI

struct Icon {
    static let logo: Image = Image(systemName: Symbol.logo)
    static let note: Image = Image(systemName: Symbol.note)
    static let task: Image = Image(systemName: Symbol.task)
    static let event: Image = Image(systemName: Symbol.event)
    static let calendar: Image = Image(systemName: Symbol.calendar)
    static let day: Image = Image(systemName: Symbol.day)
    static let timeline: Image = Image(systemName: Symbol.timeline)
    static let pin: Image = Image(systemName: Symbol.pin)
    static let photo: Image = Image(systemName: Symbol.photo)
    static let audio: Image = Image(systemName: Symbol.audio)
}

struct Symbol {
    static let logo: String = "circle.and.line.horizontal"
    static let note: String = "text.justify.trailing"
    static let task: String = "checkmark.square.fill"
    static let event: String = "clock.fill"
    static let calendar: String = "calendar"
    static let day: String = "diamond.fill"
    static let timeline: String = "circle.and.line.horizontal"
    static let pin: String = "pin.fill"
    static let photo: String = "photo.fill"
    static let audio: String = "microphone.fill"

    struct Health {
        static let sleep: String = "bed.double.fill"
        static let medication: String = "pill.fill"
        static let shower: String = "shower.fill"
        static let teeth: String = "mouth.fill"
        static let clean: String = "house.fill"
        static let money: String = "dollarsign"

    }

    struct Sport {
        static let stretch: String = "figure.cooldown"
        static let gym: String = "dumbbell.fill"
        static let run: String = "figure.run"
        static let walk: String = "figure.walk"
        static let treadmill: String = "figure.run.treadmill"
        static let meditate: String = "figure.mind.and.body"
        static let swim: String = "figure.pool.swim"
    }

    struct Activity {
        static let read: String = "book.fill"
        static let write: String = "pencil.and.scribble"
        static let game: String = "gamecontroller.fill"
        static let tv: String = "inset.filled.tv"
        static let mail: String = "envelope.fill"
    }

    struct Food {
        static let waterDrop: String = "drop.fill"
        static let waterBottle: String = "waterbottle.fill"
        static let coffeeCup: String = "cup.and.heat.waves.fill"
        static let forkKnife: String = "fork.knife"
    }

    struct Misc {
        static let diamond: String = "diamond.fill"
        static let star: String = "star.fill"
        static let hexagon: String = "hexagon.fill"
        static let staroflife: String = "staroflife.fill"
        static let waves: String = "water.waves"
        static let text: String = "text.justify.leading"
        static let checkbox: String = "checkmark.square.fill"
        static let clock: String = "clock.fill"
        static let calendar: String = "calendar"
        static let pin: String = "pin.fill"
        static let photo: String = "photo.fill"
        static let audio: String = "microphone.fill"
    }
}

extension Symbol.Health {
    static let all: [String] = [
        sleep, medication, shower, teeth, clean, money,
    ]
}

extension Symbol.Sport {
    static let all: [String] = [
        stretch, gym, run, treadmill, swim,
    ]
}

extension Symbol.Activity {
    static let all: [String] = [
        read, write, game, tv, mail,
    ]
}

extension Symbol.Food {
    static let all: [String] = [
        waterDrop, waterBottle, coffeeCup, forkKnife,
    ]
}

extension Symbol.Misc {
    static let all: [String] = [
        waves, text, checkbox, clock, calendar, diamond, pin, photo, audio,
    ]
}

extension Symbol {
    static let all: [String] =
        Health.all
        + Sport.all
        + Activity.all
        + Food.all
        + Misc.all
}
