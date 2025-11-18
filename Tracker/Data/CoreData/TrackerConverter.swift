import UIKit
import CoreData

final class TrackerConverter {

    // MARK: - CoreData → Model

    func makeTracker(from core: TrackerCoreData) -> Tracker? {

        guard
            let id = core.id,
            let name = core.name,
            let emoji = core.emoji,
            let colorHex = core.colorHex
        else { return nil }

        let color = UIColor(hex: colorHex)
        let schedule = (core.schedule as? [Int])?.compactMap { Weekday(rawValue: $0) } ?? []

        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }

    // MARK: - Model → CoreData

    func fill(entity: TrackerCoreData, from model: Tracker) {
        entity.id = model.id
        entity.name = model.name
        entity.emoji = model.emoji
        entity.colorHex = model.color.toHex()
        entity.schedule = model.schedule.map { NSNumber(value: $0.rawValue) } as NSArray
    }
}



