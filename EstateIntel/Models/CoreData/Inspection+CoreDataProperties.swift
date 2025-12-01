//
//  Inspection+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension Inspection {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Inspection> {
        return NSFetchRequest<Inspection>(entityName: "Inspection")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var inspectionType: String? // Move-In, Move-Out, Routine, Emergency
    @NSManaged public var inspectionDate: Date?
    @NSManaged public var inspectorName: String?
    @NSManaged public var overallCondition: String? // Excellent, Good, Fair, Poor
    @NSManaged public var notes: String?
    
    // Media
    @NSManaged public var imageURLs: String? // JSON array of image paths
    @NSManaged public var videoURLs: String? // JSON array of video paths
    
    // AI damage detection
    @NSManaged public var aiDetectedDamages: String? // JSON array of {room, damageType, severity, location}
    @NSManaged public var damageCount: Int16
    @NSManaged public var estimatedRepairCost: Double
    @NSManaged public var comparisonInspectionID: UUID? // For comparing move-in vs move-out
    @NSManaged public var changesDetected: String? // JSON array of differences
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships
    @NSManaged public var unit: Unit?
}

extension Inspection: Identifiable {
    
}
