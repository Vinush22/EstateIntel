//
//  Payment+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension Payment {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Payment> {
        return NSFetchRequest<Payment>(entityName: "Payment")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var paymentDate: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var paymentMethod: String? // Credit Card, Bank Transfer, Check, Cash
    @NSManaged public var transactionID: String?
    @NSManaged public var status: String? // Pending, Completed, Failed, Refunded
    @NSManaged public var isLate: Bool
    @NSManaged public var lateDays: Int16
    @NSManaged public var notes: String?
    
    // Fraud detection
    @NSManaged public var fraudRiskScore: Double // 0-100
    @NSManaged public var unusualPatternDetected: Bool
    @NSManaged public var fraudIndicators: String? // JSON array
    
    @NSManaged public var createdAt: Date?
    
    // Relationships
    @NSManaged public var tenant: Tenant?
}

extension Payment: Identifiable {
    
}
