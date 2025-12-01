//
//  Unit+CoreDataClass.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

@objc(Unit)
public class Unit: NSManagedObject {
    var isOccupied: Bool {
        return currentTenant != nil && leaseEndDate ?? Date() > Date()
    }
    
    var formattedRent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: monthlyRent)) ?? "$0"
    }
}
