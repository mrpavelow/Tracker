//
//  TrackerCoreData+CoreDataProperties.swift
//  Tracker
//
//  Created by Mikhail Pavlov on 19.11.2025.
//
//

import Foundation
import CoreData


extension TrackerCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackerCoreData> {
        return NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var emoji: String?
    @NSManaged public var schedule: NSObject?
    @NSManaged public var category: TrackerCategoryCoreData?
    @NSManaged public var records: TrackerRecordCoreData?

}

extension TrackerCoreData : Identifiable {

}
