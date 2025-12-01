//
//  MaintenanceLog+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension MaintenanceLog {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MaintenanceLog> {
        return NSFetchRequest<MaintenanceLog>(entityName: "MaintenanceLog")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var equipmentType: String? // HVAC, Water Heater, Elevator, etc.
    @NSManaged public var equipmentID: String?
    @NSManaged public var issueType: String?
    @NSManaged public var issueDescription: String?
    @NSManaged public var repairDate: Date?
    @NSManaged public var repairCost: Double
    @NSManaged public var preventiveMaintenance: Bool
    @NSManaged public var contractorName: String?
    @NSManaged public var severity: String? // Low, Medium, High, Critical
    @NSManaged public var downtime: Double // Hours
    @NSManaged public var partsReplaced: String? // JSON array
    @NSManaged public var notes: String?
    @NSManaged public var season: String? // Winter, Spring, Summer, Fall
    @NSManaged public var createdAt: Date?
    
    // Relationships
    @NSManaged public var property: Property?
}

extension MaintenanceLog: Identifiable {
    
}
