//
//  EnergyOptimizationService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

/// AI service for analyzing utility usage and recommending efficiency improvements
class EnergyOptimizationService {
    
    struct UtilityAnalysis {
        let unit: Unit
        let monthlyUsage: UsageStats
        let anomaliesDetected: [Anomaly]
        let recommendations: [Recommendation]
        let potentialSavings: Double
        let efficiencyScore: Double // 0-100
    }
    
    struct UsageStats {
        let electricity: Double // kWh
        let water: Double // gallons
        let gas: Double // therms
        let month: Date
        let totalCost: Double
    }
    
    struct Anomaly {
        let utilityType: String
        let description: String
        let severity: Severity
        let usageIncrease: Double // percentage
        
        enum Severity: String {
            case minor = "Minor"
            case moderate = "Moderate"
            case significant = "Significant"
            
            var color: String {
                switch self {
                case .minor: return "yellow"
                case .moderate: return "orange"
                case .significant: return "red"
                }
            }
        }
    }
    
    struct Recommendation {
        let category: String
        let description: String
        let estimatedMonthlySavings: Double
        let implementation: String
        let priority: Priority
        
        enum Priority: String {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
        }
    }
    
    /// Analyzes utility usage for a unit and provides optimization recommendations
    func analyzeUtilityUsage(for unit: Unit) -> UtilityAnalysis {
        // Simulate utility data (in production, fetch from utility provider API or database)
        let currentUsage = generateSimulatedUsage(unit: unit)
        let baselineUsage = calculateBaseline(unit: unit)
        
        // Detect anomalies
        let anomalies = detectAnomalies(current: currentUsage, baseline: baselineUsage)
        
        // Generate recommendations
        let recommendations = generateRecommendations(usage: currentUsage, unit: unit, anomalies: anomalies)
        
        // Calculate potential savings
        let savings = recommendations.reduce(0) { $0 + $1.estimatedMonthlySavings }
        
        // Calculate efficiency score
        let efficiency = calculateEfficiencyScore(usage: currentUsage, baseline: baselineUsage, anomalies: anomalies)
        
        return UtilityAnalysis(
            unit: unit,
            monthlyUsage: currentUsage,
            anomaliesDetected: anomalies,
            recommendations: recommendations,
            potentialSavings: savings,
            efficiencyScore: efficiency
        )
    }
    
    private func generateSimulatedUsage(unit: Unit) -> UsageStats {
        // Simulate usage based on unit size and bedrooms
        let sqft = unit.squareFeet
        let bedrooms = Int(unit.bedrooms)
        
        // Base usage calculations (rough estimates)
        let electricityPerSqft = 0.8 // kWh per sqft per month
        let waterPerBedroom = 2000.0 // gallons per bedroom per month
        let gasPerSqft = 0.05 // therms per sqft per month
        
        let electricity = sqft * electricityPerSqft * Double.random(in: 0.9...1.2)
        let water = Double(bedrooms) * waterPerBedroom * Double.random(in: 0.8...1.3)
        let gas = sqft * gasPerSqft * Double.random(in: 0.85...1.15)
        
        // Cost calculation (approximate rates)
        let electricityCost = electricity * 0.13 // $0.13 per kWh
        let waterCost = water * 0.003 // $0.003 per gallon
        let gasCost = gas * 1.20 // $1.20 per therm
        
        return UsageStats(
            electricity: electricity,
            water: water,
            gas: gas,
            month: Date(),
            totalCost: electricityCost + waterCost + gasCost
        )
    }
    
    private func calculateBaseline(unit: Unit) -> UsageStats {
        // Calculate expected baseline for similar units
        let sqft = unit.squareFeet
        let bedrooms = Int(unit.bedrooms)
        
        let electricity = sqft * 0.75 // Efficient usage
        let water = Double(bedrooms) * 1800.0
        let gas = sqft * 0.045
        
        let cost = (electricity * 0.13) + (water * 0.003) + (gas * 1.20)
        
        return UsageStats(
            electricity: electricity,
            water: water,
            gas: gas,
            month: Date(),
            totalCost: cost
        )
    }
    
    private func detectAnomalies(current: UsageStats, baseline: UsageStats) -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        // Check electricity usage
        let electricityIncrease = ((current.electricity - baseline.electricity) / baseline.electricity) * 100
        if electricityIncrease > 30 {
            anomalies.append(Anomaly(
                utilityType: "Electricity",
                description: "Electricity usage is \(Int(electricityIncrease))% above normal for similar units",
                severity: electricityIncrease > 50 ? .significant : .moderate,
                usageIncrease: electricityIncrease
            ))
        }
        
        // Check water usage
        let waterIncrease = ((current.water - baseline.water) / baseline.water) * 100
        if waterIncrease > 40 {
            anomalies.append(Anomaly(
                utilityType: "Water",
                description: "Water consumption is \(Int(waterIncrease))% higher than expected - possible leak",
                severity: waterIncrease > 60 ? .significant : .moderate,
                usageIncrease: waterIncrease
            ))
        }
        
        // Check gas usage
        let gasIncrease = ((current.gas - baseline.gas) / baseline.gas) * 100
        if gasIncrease > 25 {
            anomalies.append(Anomaly(
                utilityType: "Gas",
                description: "Gas usage is \(Int(gasIncrease))% above expected - check heating efficiency",
                severity: gasIncrease > 50 ? .significant : .moderate,
                usageIncrease: gasIncrease
            ))
        }
        
        return anomalies
    }
    
    private func generateRecommendations(usage: UsageStats, unit: Unit, anomalies: [Anomaly]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Electricity recommendations
        if usage.electricity > calculateBaseline(unit: unit).electricity * 1.2 {
            recommendations.append(Recommendation(
                category: "Lighting & Appliances",
                description: "Upgrade to LED bulbs and Energy Star appliances",
                estimatedMonthlySavings: usage.electricity * 0.13 * 0.15, // 15% reduction
                implementation: "Replace incandescent bulbs with LEDs. Consider appliance upgrades",
                priority: .high
            ))
            
            recommendations.append(Recommendation(
                category: "HVAC Efficiency",
                description: "Install programmable thermostat and seal air leaks",
                estimatedMonthlySavings: usage.electricity * 0.13 * 0.10, // 10% reduction
                implementation: "Smart thermostat can save 10-15% on heating/cooling costs",
                priority: .medium
            ))
        }
        
        // Water recommendations
        if usage.water > calculateBaseline(unit: unit).water * 1.3 {
            recommendations.append(Recommendation(
                category: "Water Conservation",
                description: "Install low-flow fixtures and check for leaks",
                estimatedMonthlySavings: usage.water * 0.003 * 0.25, // 25% reduction
                implementation: "Low-flow showerheads and faucet aerators reduce usage by 20-30%",
                priority: .high
            ))
        }
        
        // Time-of-use optimization
        recommendations.append(Recommendation(
            category: "Usage Scheduling",
            description: "Shift high-energy activities to off-peak hours",
            estimatedMonthlySavings: usage.electricity * 0.13 * 0.08, // 8% savings
            implementation: "Run dishwasher and laundry during off-peak times (9pm-7am)",
            priority: .low
        ))
        
        // General efficiency
        recommendations.append(Recommendation(
            category: "Weatherization",
            description: "Improve insulation and seal windows/doors",
            estimatedMonthlySavings: (usage.electricity * 0.13 + usage.gas * 1.20) * 0.12,
            implementation: "Weather stripping, caulking, and window film can reduce heating/cooling load",
            priority: .medium
        ))
        
        return recommendations.sorted { $0.estimatedMonthlySavings > $1.estimatedMonthlySavings }
    }
    
    private func calculateEfficiencyScore(usage: UsageStats, baseline: UsageStats, anomalies: [Anomaly]) -> Double {
        var score: Double = 100.0
        
        // Deduct points for usage above baseline
        let totalUsageIncrease = ((usage.totalCost - baseline.totalCost) / baseline.totalCost) * 100
        score -= totalUsageIncrease * 0.5 // Deduct 0.5 points per 1% over baseline
        
        // Deduct additional points for anomalies
        for anomaly in anomalies {
            switch anomaly.severity {
            case .minor:
                score -= 5
            case .moderate:
                score -= 10
            case .significant:
                score -= 15
            }
        }
        
        // Cap between 0 and 100
        return max(0, min(100, score))
    }
}
