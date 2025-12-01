//
//  Unit+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension Unit {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Unit> {
        return NSFetchRequest<Unit>(entityName: "Unit")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var unitNumber: String?
    @NSManaged public var floor: Int16
    @NSManaged public var bedrooms: Int16
    @NSManaged public var bathrooms: Double
    @NSManaged public var squareFeet: Double
    @NSManaged public var monthlyRent: Double
    @NSManaged public var status: String? // Available, Occupied, Under Maintenance
    @NSManaged public var leaseStartDate: Date?
    @NSManaged public var leaseEndDate: Date?
    @NSManaged public var features: String? // JSON string
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships
    @NSManaged public var property: Property?
    @NSManaged public var currentTenant: Tenant?
    @NSManaged public var maintenanceRequests: NSSet?
    @NSManaged public var inspections: NSSet?
}

// MARK: Generated accessors for maintenanceRequests
extension Unit {
    
    @objc(addMaintenanceRequestsObject:)
    @NSManaged public func addToMaintenanceRequests(_ value: MaintenanceRequest)
    
    @objc(removeMaintenanceRequestsObject:)
    @NSManaged public func removeFromMaintenanceRequests(_ value: MaintenanceRequest)
    
    @objc(addMaintenanceRequests:)
    @NSManaged public func addToMaintenanceRequests(_ values: NSSet)
    
    @objc(removeMaintenanceRequests:)
    @NSManaged public func removeFromMaintenanceRequests(_ values: NSSet)
}

// MARK: Generated accessors for inspections
extension Unit {
    
    @objc(addInspectionsObject:)
    @NSManaged public func addToInspections(_ value: Inspection)
    
    @objc(removeInspectionsObject:)
    @NSManaged public func removeFromInspections(_ value: Inspection)
    
    @objc(addInspections:)
    @NSManaged public func addToInspections(_ values: NSSet)
    
    @objc(removeInspections:)
    @NSManaged public func removeFromInspections(_ values: NSSet)
}

extension Unit: Identifiable {
    
}
