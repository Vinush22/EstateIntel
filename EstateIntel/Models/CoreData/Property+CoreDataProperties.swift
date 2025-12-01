//
//  Property+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension Property {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Property> {
        return NSFetchRequest<Property>(entityName: "Property")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var zipCode: String?
    @NSManaged public var propertyType: String? // Apartment, Condo, House, etc.
    @NSManaged public var yearBuilt: Int32
    @NSManaged public var totalSquareFeet: Double
    @NSManaged public var amenities: String? // JSON string of amenities
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships
    @NSManaged public var units: NSSet?
    @NSManaged public var maintenanceLogs: NSSet?
}

// MARK: Generated accessors for units
extension Property {
    
    @objc(addUnitsObject:)
    @NSManaged public func addToUnits(_ value: Unit)
    
    @objc(removeUnitsObject:)
    @NSManaged public func removeFromUnits(_ value: Unit)
    
    @objc(addUnits:)
    @NSManaged public func addToUnits(_ values: NSSet)
    
    @objc(removeUnits:)
    @NSManaged public func removeFromUnits(_ values: NSSet)
}

// MARK: Generated accessors for maintenanceLogs
extension Property {
    
    @objc(addMaintenanceLogsObject:)
    @NSManaged public func addToMaintenanceLogs(_ value: MaintenanceLog)
    
    @objc(removeMaintenanceLogsObject:)
    @NSManaged public func removeFromMaintenanceLogs(_ value: MaintenanceLog)
    
    @objc(addMaintenanceLogs:)
    @NSManaged public func addToMaintenanceLogs(_ values: NSSet)
    
    @objc(removeMaintenanceLogs:)
    @NSManaged public func removeFromMaintenanceLogs(_ values: NSSet)
}

extension Property: Identifiable {
    
}
