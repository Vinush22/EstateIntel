//
//  VacancyPredictionService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

/// AI service for predicting tenant move-outs and vacancy patterns
class VacancyPredictionService {
    
    struct VacancyPrediction {
        let unit: Unit
        let tenant: Tenant?
        let moveOutProbability: Double // 0-1
        let predictedVacancyDate: Date?
        let riskLevel: RiskLevel
        let behavioralIndicators: [String]
        let predictedVacancyDuration: Int // days
        let marketingRecommendations: [String]
    }
    
    enum RiskLevel: String {
        case low = "Low Risk"
        case medium = "Medium Risk"
        case high = "High Risk"
        case imminent = "Imminent Move-Out"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .imminent: return "red"
            }
        }
    }
    
    /// Predicts move-out probability for all occupied units
    func predictVacancies(for property: Property, context: NSManagedObjectContext) -> [VacancyPrediction] {
        guard let units = property.units as? Set<Unit> else {
            return []
        }
        
        var predictions: [VacancyPrediction] = []
        
        for unit in units where unit.isOccupied {
            if let prediction = analyzeUnit(unit) {
                predictions.append(prediction)
            }
        }
        
        return predictions.sorted { $0.moveOutProbability > $1.moveOutProbability }
    }
    
    private func analyzeUnit(_ unit: Unit) -> VacancyPrediction? {
        guard let tenant = unit.currentTenant else { return nil }
        
        var moveOutScore: Double = 0.0
        var indicators: [String] = []
        
        // 1. Lease end proximity (40% weight)
        let leaseEndFactor = analyzeLleaseEnd(unit: unit)
        moveOutScore += leaseEndFactor.score * 0.4
        if !leaseEndFactor.indicator.isEmpty {
            indicators.append(leaseEndFactor.indicator)
        }
        
        // 2. Payment behavior (25% weight)
        let paymentFactor = analyzePaymentBehavior(tenant: tenant)
        moveOutScore += paymentFactor.score * 0.25
        if !paymentFactor.indicator.isEmpty {
            indicators.append(paymentFactor.indicator)
        }
        
        // 3. Complaint frequency (20% weight)
        let complaintFactor = analyzeComplaints(tenant: tenant)
        moveOutScore += complaintFactor.score * 0.20
        if !complaintFactor.indicator.isEmpty {
            indicators.append(complaintFactor.indicator)
        }
        
        // 4. Communication engagement (15% weight)
        let engagementFactor = analyzeEngagement(tenant: tenant)
        moveOutScore += engagementFactor.score * 0.15
        if !engagementFactor.indicator.isEmpty {
            indicators.append(engagementFactor.indicator)
        }
        
        // Cap score at 1.0
        moveOutScore = min(moveOutScore, 1.0)
        
        // Determine risk level
        let riskLevel: RiskLevel
        if moveOutScore >= 0.8 {
            riskLevel = .imminent
        } else if moveOutScore >= 0.6 {
            riskLevel = .high
        } else if moveOutScore >= 0.35 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }
        
        // Predict vacancy date
        let predictedDate = estimateVacancyDate(unit: unit, probability: moveOutScore)
        
        // Estimate vacancy duration
        let vacancyDuration = estimateVacancyDuration(unit: unit)
        
        // Generate marketing recommendations
        let recommendations = generateMarketingRecommendations(unit: unit, riskLevel: riskLevel, duration: vacancyDuration)
        
        return VacancyPrediction(
            unit: unit,
            tenant: tenant,
            moveOutProbability: moveOutScore,
            predictedVacancyDate: predictedDate,
            riskLevel: riskLevel,
            behavioralIndicators: indicators,
            predictedVacancyDuration: vacancyDuration,
            marketingRecommendations: recommendations
        )
    }
    
    private func analyzeLleaseEnd(unit: Unit) -> (score: Double, indicator: String) {
        guard let leaseEnd = unit.leaseEndDate else {
            return (0.1, "")
        }
        
        let daysUntilEnd = Calendar.current.dateComponents([.day], from: Date(), to: leaseEnd).day ?? 365
        
        if daysUntilEnd < 0 {
            return (1.0, "Lease has expired")
        } else if daysUntilEnd < 30 {
            return (0.9, "Lease ending in \(daysUntilEnd) days")
        } else if daysUntilEnd < 60 {
            return (0.6, "Lease ending within 2 months")
        } else if daysUntilEnd < 90 {
            return (0.3, "Lease ending within 3 months")
        } else {
            return (0.05, "")
        }
    }
    
    private func analyzePaymentBehavior(tenant: Tenant) -> (score: Double, indicator: String) {
        guard let payments = tenant.payments as? Set<Payment>, !payments.isEmpty else {
            return (0.0, "")
        }
        
        let latePayments = payments.filter { $0.isLate }
        let lateRatio = Double(latePayments.count) / Double(payments.count)
        
        // Recent late payments are stronger indicator of move-out
        let recentPayments = payments.sorted { ($0.paymentDate ?? Date.distantPast) > ($1.paymentDate ?? Date.distantPast) }.prefix(3)
        let recentLateCount = recentPayments.filter { $0.isLate }.count
        
        if recentLateCount >= 2 {
            return (0.8, "Multiple recent late payments")
        } else if lateRatio > 0.3 {
            return (0.5, "Frequent payment delays")
        } else if lateRatio > 0.1 {
            return (0.2, "Occasional late payments")
        } else {
            return (0.0, "")
        }
    }
    
    private func analyzeComplaints(tenant: Tenant) -> (score: Double, indicator: String) {
        guard let requests = tenant.maintenanceRequests as? Set<MaintenanceRequest> else {
            return (0.0, "")
        }
        
        // High number of complaints/requests can indicate dissatisfaction
        let requestCount = requests.count
        let urgentRequests = requests.filter { $0.urgency == "High" || $0.urgency == "Critical" }.count
        
        if requestCount > 10 {
            return (0.7, "High volume of maintenance requests (\(requestCount))")
        } else if urgentRequests > 3 {
            return (0.6, "Multiple urgent requests - possible dissatisfaction")
        } else if requestCount > 5 {
            return (0.3, "Above average maintenance requests")
        } else {
            return (0.0, "")
        }
    }
    
    private func analyzeEngagement(tenant: Tenant) -> (score: Double, indicator: String) {
        guard let messages = tenant.messages as? Set<Message>, !messages.isEmpty else {
            return (0.1, "")
        }
        
        // Negative sentiment in recent communications
        let recentMessages = messages.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }.prefix(5)
        let negativeCount = recentMessages.filter { $0.sentiment == "Negative" }.count
        
        if negativeCount >= 3 {
            return (0.7, "Recent negative communication pattern")
        } else if negativeCount >= 2 {
            return (0.4, "Some negative sentiment detected")
        } else {
            return (0.0, "")
        }
    }
    
    private func estimateVacancyDate(unit: Unit, probability: Double) -> Date? {
        if probability < 0.3 {
            return nil // Too low to predict
        }
        
        // If lease end date is available, use that as primary indicator
        if let leaseEnd = unit.leaseEndDate {
            let daysUntilEnd = Calendar.current.dateComponents([.day], from: Date(), to: leaseEnd).day ?? 0
            if daysUntilEnd < 90 {
                return leaseEnd
            }
        }
        
        // Otherwise, estimate based on probability
        let estimatedDays = Int((1.0 - probability) * 180) // Higher probability = sooner move-out
        return Calendar.current.date(byAdding: .day, value: estimatedDays, to: Date())
    }
    
    private func estimateVacancyDuration(unit: Unit) -> Int {
        // Estimate based on unit characteristics
        let bedrooms = Int(unit.bedrooms)
        let baseDays = 30
        
        // Larger units typically take longer to fill
        var estimatedDays = baseDays + (bedrooms * 5)
        
        // Adjust for rent price (higher rent = longer vacancy)
        if unit.monthlyRent > 2000 {
            estimatedDays += 15
        } else if unit.monthlyRent > 1500 {
            estimatedDays += 7
        }
        
        // Seasonal adjustment
        let month = Calendar.current.component(.month, from: Date())
        if month >= 4 && month <= 8 { // Spring/Summer - easier to rent
            estimatedDays = Int(Double(estimatedDays) * 0.8)
        } else if month >= 11 || month <= 2 { // Winter - harder to rent
            estimatedDays = Int(Double(estimatedDays) * 1.2)
        }
        
        return estimatedDays
    }
    
    private func generateMarketingRecommendations(unit: Unit, riskLevel: RiskLevel, duration: Int) -> [String] {
        var recommendations: [String] = []
        
        if riskLevel == .imminent || riskLevel == .high {
            recommendations.append("🚨 Start marketing immediately to minimize vacancy")
            recommendations.append("📸 Schedule professional photos and virtual tour")
            recommendations.append("💰 Consider offering move-in incentives (first month discount)")
        } else if riskLevel == .medium {
            recommendations.append("📅 Begin pre-marketing 30 days before expected vacancy")
            recommendations.append("📝 Prepare unit listing with current photos")
        }
        
        if duration > 45 {
            recommendations.append("🎯 Expand marketing channels (Zillow, Apartments.com, local ads)")
            recommendations.append("💵 Review pricing - may be above market rate")
        }
        
        if unit.bedrooms >= 3 {
            recommendations.append("👨‍👩‍👧‍👦 Target family-oriented marketing (schools, parks nearby)")
        }
        
        return recommendations
    }
}
