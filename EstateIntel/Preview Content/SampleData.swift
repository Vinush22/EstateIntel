//
//  SampleData.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

struct SampleData {
    static func createSampleData(in context: NSManagedObjectContext) {
        // Clear existing data
        clearData(in: context)
        
        // Create sample property
        let property = Property(context: context)
        property.id = UUID()
        property.name = "Sunset Apartments"
        property.address = "123 Main Street"
        property.city = "San Francisco"
        property.state = "CA"
        property.zipCode = "94102"
        property.propertyType = "Apartment"
        property.yearBuilt = 2010
        property.totalSquareFeet = 50000
        property.createdAt = Date()
        property.updatedAt = Date()
        
        // Create sample units
        for i in 1...5 {
            let unit = Unit(context: context)
            unit.id = UUID()
            unit.unitNumber = "30\(i)"
            unit.floor = Int16(i % 3 + 1)
            unit.bedrooms = Int16([1, 2, 2, 3, 1][i-1])
            unit.bathrooms = Double([1, 2, 1.5, 2, 1][i-1])
            unit.squareFeet = Double([750, 1100, 950, 1400, 700][i-1])
            unit.monthlyRent = Double([1800, 2400, 2100, 3200, 1600][i-1])
            unit.status = i <= 4 ? "Occupied" : "Available"
            unit.createdAt = Date()
            unit.updatedAt = Date()
            
            if i <= 4 {
                unit.leaseStartDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                unit.leaseEndDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())
            }
            
            property.addToUnits(unit)
            
            // Create sample tenant for occupied units
            if i <= 4 {
                let tenant = Tenant(context: context)
                tenant.id = UUID()
                tenant.firstName = ["John", "Sarah", "Michael", "Emily"][i-1]
                tenant.lastName = ["Smith", "Johnson", "Williams", "Davis"][i-1]
                tenant.email = "\(tenant.firstName!.lowercased()).\(tenant.lastName!.lowercased())@email.com"
                tenant.phone = "(555) \(100 + i * 11)-\(1000 + i * 111)"
                tenant.moveInDate = unit.leaseStartDate
                tenant.leaseEndDate = unit.leaseEndDate
                tenant.monthlyRent = unit.monthlyRent
                tenant.securityDeposit = unit.monthlyRent
                tenant.employmentStatus = "Full-time"
                tenant.monthlyIncome = unit.monthlyRent * 3.5
                tenant.reliabilityScore = Double([85, 72, 90, 68][i-1])
                tenant.satisfactionScore = Double([88, 65, 92, 70][i-1])
                tenant.moveOutProbability = Double([0.15, 0.4, 0.1, 0.6][i-1])
                tenant.createdAt = Date()
                tenant.updatedAt = Date()
                
                unit.currentTenant = tenant
                
                // Create sample messages
                for j in 1...3 {
                    let message = Message(context: context)
                    message.id = UUID()
                    message.content = ["Thank you for the quick response!", "The maintenance issue has been resolved.", "When will the pool be reopened?"][j-1]
                    message.sender = "Tenant"
                    message.senderName = tenant.fullName
                    message.timestamp = Calendar.current.date(byAdding: .day, value: -j*7, to: Date())
                    message.isRead = true
                    message.sentiment = ["Positive", "Positive", "Neutral"][j-1]
                    message.sentimentScore = Double([0.8, 0.7, 0.0][j-1])
                    message.urgencyLevel = "Low"
                    message.createdAt = message.timestamp
                    
                    tenant.addToMessages(message)
                }
                
                // Create sample payments
                for j in 1...6 {
                    let payment = Payment(context: context)
                    payment.id = UUID()
                    payment.amount = tenant.monthlyRent
                    payment.dueDate = Calendar.current.date(byAdding: .month, value: -j, to: Date())
                    payment.paymentDate = Calendar.current.date(byAdding: .day, value: (j == 2 ? 5 : 0), to: payment.dueDate!)
                    payment.paymentMethod = "Bank Transfer"
                    payment.status = "Completed"
                    payment.isLate = (j == 2)
                    payment.lateDays = (j == 2) ? 5 : 0
                    payment.fraudRiskScore = Double.random(in: 5...15)
                    payment.unusualPatternDetected = false
                    payment.createdAt = payment.paymentDate
                    
                    tenant.addToPayments(payment)
                }
            }
        }
        
        // Create sample maintenance logs
        let equipmentTypes = ["HVAC", "Water Heater", "Elevator", "Plumbing"]
        for (index, equipment) in equipmentTypes.enumerated() {
            let log = MaintenanceLog(context: context)
            log.id = UUID()
            log.equipmentType = equipment
            log.equipmentID = "\(equipment)-001"
            log.issueType = "Routine Maintenance"
            log.issueDescription = "Scheduled maintenance for \(equipment)"
            log.repairDate = Calendar.current.date(byAdding: .month, value: -(index + 1) * 3, to: Date())
            log.repairCost = Double([450, 350, 800, 275][index])
            log.preventiveMaintenance = true
            log.severity = "Medium"
            log.downtime = Double([2, 4, 6, 1][index])
            log.season = ["Fall", "Summer", "Spring", "Winter"][index]
            log.createdAt = log.repairDate
            
            property.addToMaintenanceLogs(log)
        }
        
        // Save context
        do {
            try context.save()
            print("Sample data created successfully")
        } catch {
            print("Failed to save sample data: \(error.localizedDescription)")
        }
    }
    
    private static func clearData(in context: NSManagedObjectContext) {
        let entities = ["Property", "Unit", "Tenant", "Message", "Payment", "MaintenanceLog", "MaintenanceRequest", "Document", "Inspection"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entityName): \(error.localizedDescription)")
            }
        }
    }
}
