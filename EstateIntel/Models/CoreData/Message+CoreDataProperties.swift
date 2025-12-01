//
//  Message+CoreDataProperties.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

extension Message {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var sender: String? // Tenant, Manager, System
    @NSManaged public var senderName: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var isRead: Bool
    @NSManaged public var subject: String?
    @NSManaged public var threadID: String?
    
    // AI analysis
    @NSManaged public var sentiment: String? // Positive, Neutral, Negative
    @NSManaged public var sentimentScore: Double // -1 to 1
    @NSManaged public var urgencyLevel: String? // Low, Medium, High
    @NSManaged public var detectedTopics: String? // JSON array
    @NSManaged public var aiSuggestedReply: String?
    @NSManaged public var requiresAttention: Bool
    
    @NSManaged public var createdAt: Date?
    
    // Relationships
    @NSManaged public var tenant: Tenant?
}

extension Message: Identifiable {
    
}
