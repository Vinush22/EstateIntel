//
//  Tenant+CoreDataClass.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

@objc(Tenant)
public class Tenant: NSManagedObject {
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }
    
    var isLeaseActive: Bool {
        guard let endDate = leaseEndDate else { return false }
        return endDate > Date()
    }
    
    // Helper to decode satisfaction metrics from JSON
    var satisfactionMetrics: [String: Any]? {
        guard let metricsJSON = satisfactionMetricsJSON else { return nil }
        return try? JSONSerialization.jsonObject(with: Data(metricsJSON.utf8), options: []) as? [String: Any]
    }
}
