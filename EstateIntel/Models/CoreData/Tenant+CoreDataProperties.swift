//
//  Tenant+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension Tenant {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tenant> {
        return NSFetchRequest<Tenant>(entityName: "Tenant")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var moveInDate: Date?
    @NSManaged public var leaseEndDate: Date?
    @NSManaged public var monthlyRent: Double
    @NSManaged public var securityDeposit: Double
    @NSManaged public var employmentStatus: String?
    @NSManaged public var monthlyIncome: Double
    @NSManaged public var emergencyContact: String?
    @NSManaged public var emergencyPhone: String?
    
    // AI/ML related fields
    @NSManaged public var reliabilityScore: Double // 0-100
    @NSManaged public var satisfactionScore: Double // 0-100
    @NSManaged public var riskScore: Double // 0-100
    @NSManaged public var moveOutProbability: Double // 0-1
    @NSManaged public var satisfactionMetricsJSON: String? // JSON encoded metrics
    @NSManaged public var lastCommunicationSentiment: String? // Positive, Neutral, Negative
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships
    @NSManaged public var unit: Unit?
    @NSManaged public var messages: NSSet?
    @NSManaged public var maintenanceRequests: NSSet?
    @NSManaged public var payments: NSSet?
    @NSManaged public var documents: NSSet?
}

// MARK: Generated accessors for messages
extension Tenant {
    
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

// MARK: Generated accessors for maintenanceRequests
extension Tenant {
    
    @objc(addMaintenanceRequestsObject:)
    @NSManaged public func addToMaintenanceRequests(_ value: MaintenanceRequest)
    
    @objc(removeMaintenanceRequestsObject:)
    @NSManaged public func removeFromMaintenanceRequests(_ value: MaintenanceRequest)
    
    @objc(addMaintenanceRequests:)
    @NSManaged public func addToMaintenanceRequests(_ values: NSSet)
    
    @objc(removeMaintenanceRequests:)
    @NSManaged public func removeFromMaintenanceRequests(_ values: NSSet)
}

// MARK: Generated accessors for payments
extension Tenant {
    
    @objc(addPaymentsObject:)
    @NSManaged public func addToPayments(_ value: Payment)
    
    @objc(removePaymentsObject:)
    @NSManaged public func removeFromPayments(_ value: Payment)
    
    @objc(addPayments:)
    @NSManaged public func addToPayments(_ values: NSSet)
    
    @objc(removePayments:)
    @NSManaged public func removeFromPayments(_ values: NSSet)
}

// MARK: Generated accessors for documents
extension Tenant {
    
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: Document)
    
    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: Document)
    
    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)
    
    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
}

extension Tenant: Identifiable {
    
}
