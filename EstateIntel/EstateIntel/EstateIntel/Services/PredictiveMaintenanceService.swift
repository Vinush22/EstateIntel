//
//  PredictiveMaintenanceService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

/// AI service for predicting equipment failures and generating maintenance alerts
class PredictiveMaintenanceService {
    
    struct MaintenancePrediction: Identifiable {
        let id = UUID()
        let equipmentType: String
        let equipmentID: String
        let predictedFailureDate: Date
        let confidence: Double // 0-1
        let severity: Severity
        let estimatedCost: Double
        let riskFactors: [String]
        let recommendedAction: String
        
        enum Severity: String, CaseIterable {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"
            
            var color: String {
                switch self {
                case .low: return "green"
                case .medium: return "yellow"
                case .high: return "orange"
                case .critical: return "red"
                }
            }
        }
    }
    
    /// Analyzes maintenance logs to predict upcoming failures
    func analyzeMaintenance(for property: Property, context: NSManagedObjectContext) -> [MaintenancePrediction] {
        guard let logs = property.maintenanceLogs as? Set<MaintenanceLog> else {
            return []
        }
        
        var predictions: [MaintenancePrediction] = []
        
        // Group logs by equipment type
        let groupedLogs = Dictionary(grouping: Array(logs)) { $0.equipmentType ?? "Unknown" }
        
        for (equipmentType, equipmentLogs) in groupedLogs {
            if let prediction = predictFailure(equipmentType: equipmentType, logs: equipmentLogs) {
                predictions.append(prediction)
            }
        }
        
        return predictions.sorted { $0.predictedFailureDate < $1.predictedFailureDate }
    }
    
    /// Predicts failure for a specific equipment type based on historical patterns
    private func predictFailure(equipmentType: String, logs: [MaintenanceLog]) -> MaintenancePrediction? {
        guard !logs.isEmpty else { return nil }
        
        // Sort logs by date
        let sortedLogs = logs.sorted { ($0.repairDate ?? Date.distantPast) < ($1.repairDate ?? Date.distantPast) }
        
        // Calculate average time between failures
        var timeBetweenFailures: [TimeInterval] = []
        for i in 1..<sortedLogs.count {
            if let prevDate = sortedLogs[i-1].repairDate,
               let currentDate = sortedLogs[i].repairDate {
                timeBetweenFailures.append(currentDate.timeIntervalSince(prevDate))
            }
        }
        
        guard !timeBetweenFailures.isEmpty else {
            // If no pattern, predict based on typical equipment lifespan
            return createDefaultPrediction(equipmentType: equipmentType, lastLog: sortedLogs.last!)
        }
        
        // Calculate average interval
        let averageInterval = timeBetweenFailures.reduce(0, +) / Double(timeBetweenFailures.count)
        
        // Predict next failure date
        let lastRepairDate = sortedLogs.last?.repairDate ?? Date()
        let predictedDate = lastRepairDate.addingTimeInterval(averageInterval)
        
        // Calculate confidence based on consistency of intervals
        let variance = calculateVariance(values: timeBetweenFailures, mean: averageInterval)
        let confidence = max(0.3, 1.0 - (variance / averageInterval)) // Higher variance = lower confidence
        
        // Determine severity based on how soon failure is predicted
        let daysUntilFailure = Calendar.current.dateComponents([.day], from: Date(), to: predictedDate).day ?? 0
        let severity: MaintenancePrediction.Severity
        if daysUntilFailure < 7 {
            severity = .critical
        } else if daysUntilFailure < 30 {
            severity = .high
        } else if daysUntilFailure < 90 {
            severity = .medium
        } else {
            severity = .low
        }
        
        // Estimate cost based on historical average
        let avgCost = logs.map { $0.repairCost }.reduce(0, +) / Double(logs.count)
        let estimatedCost = avgCost * 1.1 // Add 10% inflation buffer
        
        // Identify risk factors
        let riskFactors = identifyRiskFactors(logs: logs)
        
        return MaintenancePrediction(
            equipmentType: equipmentType,
            equipmentID: sortedLogs.last?.equipmentID ?? "Unknown",
            predictedFailureDate: predictedDate,
            confidence: confidence,
            severity: severity,
            estimatedCost: estimatedCost,
            riskFactors: riskFactors,
            recommendedAction: generateRecommendation(equipmentType: equipmentType, severity: severity, daysUntil: daysUntilFailure)
        )
    }
    
    private func createDefaultPrediction(equipmentType: String, lastLog: MaintenanceLog) -> MaintenancePrediction {
        // Default lifespan estimates in days
        let defaultLifespans: [String: Int] = [
            "HVAC": 180,
            "Water Heater": 365,
            "Elevator": 90,
            "Plumbing": 120,
            "Electrical": 180,
            "Appliance": 365
        ]
        
        let lifespan = defaultLifespans[equipmentType] ?? 180
        let lastRepairDate = lastLog.repairDate ?? Date()
        let predictedDate = Calendar.current.date(byAdding: .day, value: lifespan, to: lastRepairDate) ?? Date()
        
        return MaintenancePrediction(
            equipmentType: equipmentType,
            equipmentID: lastLog.equipmentID ?? "Unknown",
            predictedFailureDate: predictedDate,
            confidence: 0.5,
            severity: .medium,
            estimatedCost: lastLog.repairCost * 1.2,
            riskFactors: ["Limited historical data"],
            recommendedAction: "Monitor equipment closely and schedule inspection"
        )
    }
    
    private func calculateVariance(values: [TimeInterval], mean: TimeInterval) -> Double {
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    private func identifyRiskFactors(logs: [MaintenanceLog]) -> [String] {
        var factors: [String] = []
        
        // Check for increasing repair frequency
        if logs.count >= 3 {
            let recentLogs = Array(logs.sorted { ($0.repairDate ?? Date.distantPast) > ($1.repairDate ?? Date.distantPast) }.prefix(3))
            if let firstDate = recentLogs.last?.repairDate,
               let lastDate = recentLogs.first?.repairDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
                if daysBetween < 30 {
                    factors.append("Increasing failure frequency")
                }
            }
        }
        
        // Check for high severity repairs
        let highSeverityCount = logs.filter { $0.severity == "High" || $0.severity == "Critical" }.count
        if Double(highSeverityCount) / Double(logs.count) > 0.3 {
            factors.append("History of severe failures")
        }
        
        // Check for seasonal patterns
        let currentSeason = getCurrentSeason()
        let seasonalFailures = logs.filter { $0.season == currentSeason }.count
        if Double(seasonalFailures) / Double(logs.count) > 0.4 {
            factors.append("Seasonal failure pattern")
        }
        
        // Check for escalating costs
        if logs.count >= 2 {
            let sortedByCost = logs.sorted { $0.repairCost < $1.repairCost }
            if let minCost = sortedByCost.first?.repairCost,
               let maxCost = sortedByCost.last?.repairCost,
               maxCost > minCost * 2 {
                factors.append("Escalating repair costs")
            }
        }
        
        return factors.isEmpty ? ["Normal wear and tear"] : factors
    }
    
    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return "Winter"
        case 3, 4, 5: return "Spring"
        case 6, 7, 8: return "Summer"
        case 9, 10, 11: return "Fall"
        default: return "Unknown"
        }
    }
    
    private func generateRecommendation(equipmentType: String, severity: MaintenancePrediction.Severity, daysUntil: Int) -> String {
        switch severity {
        case .critical:
            return "URGENT: Schedule immediate inspection and prepare for replacement. Failure expected within \(daysUntil) days."
        case .high:
            return "Schedule preventive maintenance within 1-2 weeks. Order replacement parts in advance."
        case .medium:
            return "Plan preventive maintenance for next routine service window. Monitor equipment performance."
        case .low:
            return "Add to quarterly maintenance checklist. Continue normal monitoring."
        }
    }
}
