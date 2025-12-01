//
//  MaintenanceRequest+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension MaintenanceRequest {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MaintenanceRequest> {
        return NSFetchRequest<MaintenanceRequest>(entityName: "MaintenanceRequest")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var requestDescription: String?
    @NSManaged public var category: String? // Plumbing, HVAC, Electrical, Appliance, Other
    @NSManaged public var urgency: String? // Low, Medium, High, Critical
    @NSManaged public var status: String? // Submitted, Assigned, In Progress, Completed, Cancelled
    @NSManaged public var submittedDate: Date?
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var completedDate: Date?
    @NSManaged public var estimatedCost: Double
    @NSManaged public var actualCost: Double
    @NSManaged public var assignedContractor: String?
    @NSManaged public var contractorPhone: String?
    
    // AI classification results
    @NSManaged public var aiClassificationConfidence: Double
    @NSManaged public var aiSuggestedCategory: String?
    @NSManaged public var aiUrgencyScore: Double // 0-100
    @NSManaged public var aiDetectedIssues: String? // JSON array
    
    // Media attachments
    @NSManaged public var imageURLs: String? // JSON array of local file URLs
    @NSManaged public var videoURL: String?
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships
    @NSManaged public var tenant: Tenant?
    @NSManaged public var unit: Unit?
}

extension MaintenanceRequest: Identifiable {
    
}
