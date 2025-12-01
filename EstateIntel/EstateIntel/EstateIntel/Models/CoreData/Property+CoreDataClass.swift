//
//  Property+CoreDataClass.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

@objc(Property)
public class Property: NSManagedObject {
    // Computed property for total units
    var totalUnits: Int {
        return units?.count ?? 0
    }
    
    var occupiedUnits: Int {
        return units?.filter { ($0 as? Unit)?.isOccupied == true }.count ?? 0
    }
    
    var occupancyRate: Double {
        guard totalUnits > 0 else { return 0.0 }
        return Double(occupiedUnits) / Double(totalUnits)
    }
}
