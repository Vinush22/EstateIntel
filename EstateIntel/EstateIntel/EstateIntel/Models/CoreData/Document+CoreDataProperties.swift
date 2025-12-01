//
//  Document+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension Document {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var documentType: String? // Lease, ID, PayStub, BankStatement, Other
    @NSManaged public var name: String?
    @NSManaged public var fileName: String?
    @NSManaged public var fileURL: String? // Local file path
    @NSManaged public var uploadDate: Date?
    @NSManaged public var scanDate: Date?
    
    // OCR and extraction results
    @NSManaged public var ocrText: String?
    @NSManaged public var extractedDataJSON: String? // Structured data as JSON
    @NSManaged public var extractionConfidence: Double // 0-1
    @NSManaged public var isVerified: Bool
    @NSManaged public var validationStatus: String? // Validated, Issues Found, Pending Review
    @NSManaged public var validationIssues: String? // JSON array of issues
    
    // AI fraud detection
    @NSManaged public var fraudRiskScore: Double // 0-100
    @NSManaged public var fraudFlags: String? // JSON array of detected fraud indicators
    @NSManaged public var documentAuthenticity: Double // 0-1
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships
    @NSManaged public var tenant: Tenant?
}

extension Document: Identifiable {
    
}
