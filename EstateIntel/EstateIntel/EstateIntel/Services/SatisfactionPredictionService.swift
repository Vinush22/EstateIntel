//
//  SatisfactionPredictionService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

/// AI service for predicting tenant satisfaction and retention risk
class SatisfactionPredictionService {
    
    struct SatisfactionAnalysis {
        let satisfactionScore: Double // 0-100
        let retentionProbability: Double // 0-1
        let riskLevel: RiskLevel
        let satisfactionFactors: [Factor]
        let interventionSuggestions: [Intervention]
        let trend: Trend
    }
    
    struct Factor {
        let category: String
        let impact: ImpactLevel // positive or negative
        let score: Double
        let description: String
        
        enum ImpactLevel: String {
            case veryPositive = "Very Positive"
            case positive = "Positive"
            case neutral = "Neutral"
            case negative = "Negative"
            case veryNegative = "Very Negative"
        }
    }
    
    enum RiskLevel: String {
        case low = "Low Risk"
        case medium = "Medium Risk"
        case high = "High Risk"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "red"
            }
        }
    }
    
    enum Trend: String {
        case improving = "Improving"
        case stable = "Stable"
        case declining = "Declining"
    }
    
    struct Intervention {
        let priority: Priority
        let action: String
        let expectedImpact: String
        
        enum Priority: String {
            case immediate = "Immediate"
            case soon = "Within 1 Week"
            case planned = "Planned"
        }
    }
    
    /// Analyzes multiple factors to predict tenant satisfaction
    func predictSatisfaction(for tenant: Tenant, context: NSManagedObjectContext) -> SatisfactionAnalysis {
        var satisfactionScore: Double = 50.0 // Start at neutral
        var factors: [Factor] = []
        
        // 1. Maintenance Response Time (30% weight)
        let maintenanceFactor = analyzeMaintenanceResponse(tenant: tenant)
        satisfactionScore += maintenanceFactor.score * 0.30
        factors.append(maintenanceFactor)
        
        // 2. Communication Quality (25% weight)
        let communicationFactor = analyzeCommunicationQuality(tenant: tenant)
        satisfactionScore += communicationFactor.score * 0.25
        factors.append(communicationFactor)
        
        // 3. Request Resolution Rate (20% weight)
        let resolutionFactor = analyzeResolutionRate(tenant: tenant)
        satisfactionScore += resolutionFactor.score * 0.20
        factors.append(resolutionFactor)
        
        // 4. Property Condition (15% weight)
        let conditionFactor = analyzePropertyCondition(tenant: tenant)
        satisfactionScore += conditionFactor.score * 0.15
        factors.append(conditionFactor)
        
        // 5. Value Perception (10% weight)
        let valueFactor = analyzeValuePerception(tenant: tenant)
        satisfactionScore += valueFactor.score * 0.10
        factors.append(valueFactor)
        
        // Cap at 0-100
        satisfactionScore = max(0, min(100, satisfactionScore))
        
        // Calculate retention probability
        let retentionProb = calculateRetentionProbability(satisfactionScore: satisfactionScore, tenant: tenant)
        
        // Determine risk level
        let risk: RiskLevel
        if satisfactionScore < 50 {
            risk = .high
        } else if satisfactionScore < 70 {
            risk = .medium
        } else {
            risk = .low
        }
        
        // Determine trend
        let trend = analyzeTrend(tenant: tenant)
        
        // Generate interventions
        let interventions = generateInterventions(score: satisfactionScore, factors: factors, trend: trend)
        
        return SatisfactionAnalysis(
            satisfactionScore: satisfactionScore,
            retentionProbability: retentionProb,
            riskLevel: risk,
            satisfactionFactors: factors,
            interventionSuggestions: interventions,
            trend: trend
        )
    }
    
    private func analyzeMaintenanceResponse(tenant: Tenant) -> Factor {
        guard let requests = tenant.maintenanceRequests as? Set<MaintenanceRequest>, !requests.isEmpty else {
            return Factor(
                category: "Maintenance Response",
                impact: .neutral,
                score: 0,
                description: "No maintenance requests on record"
            )
        }
        
        var score: Double = 0
        let completedRequests = requests.filter { $0.status == "Completed" }
        let completionRate = Double(completedRequests.count) / Double(requests.count)
        
        // Calculate average resolution time
        var totalDays = 0
        var countWithDates = 0
        for request in completedRequests {
            if let submitted = request.submittedDate, let completed = request.completedDate {
                let days = Calendar.current.dateComponents([.day], from: submitted, to: completed).day ?? 0
                totalDays += days
                countWithDates += 1
            }
        }
        
        let avgResolutionDays = countWithDates > 0 ? Double(totalDays) / Double(countWithDates) : 5
        
        // Score based on completion rate and speed
        if completionRate >= 0.9 && avgResolutionDays <= 2 {
            score = 20
            return Factor(category: "Maintenance Response", impact: .veryPositive, score: score, description: "Excellent maintenance response - average \(Int(avgResolutionDays)) day turnaround")
        } else if completionRate >= 0.75 && avgResolutionDays <= 5 {
            score = 10
            return Factor(category: "Maintenance Response", impact: .positive, score: score, description: "Good maintenance response time")
        } else if avgResolutionDays > 10 {
            score = -15
            return Factor(category: "Maintenance Response", impact: .veryNegative, score: score, description: "Slow maintenance response - average \(Int(avgResolutionDays)) days")
        } else {
            score = 0
            return Factor(category: "Maintenance Response", impact: .neutral, score: score, description: "Average maintenance response")
        }
    }
    
    private func analyzeCommunicationQuality(tenant: Tenant) -> Factor {
        guard let messages = tenant.messages as? Set<Message>, !messages.isEmpty else {
            return Factor(category: "Communication Quality", impact: .neutral, score: 0, description: "Limited communication history")
        }
        
        let positiveMessages = messages.filter { $0.sentiment == "Positive" }.count
        let negativeMessages = messages.filter { $0.sentiment == "Negative" }.count
        let totalMessages = messages.count
        
        let positiveRatio = Double(positiveMessages) / Double(totalMessages)
        let negativeRatio = Double(negativeMessages) / Double(totalMessages)
        
        var score: Double
        let impact: Factor.ImpactLevel
        let description: String
        
        if positiveRatio > 0.6 {
            score = 15
            impact = .veryPositive
            description = "Consistently positive interactions"
        } else if negativeRatio > 0.5 {
            score = -20
            impact = .veryNegative
            description = "Frequent negative communications - needs immediate attention"
        } else if negativeRatio > 0.3 {
            score = -10
            impact = .negative
            description = "Some dissatisfaction expressed in messages"
        } else {
            score = 5
            impact = .positive
            description = "Generally positive communication tone"
        }
        
        return Factor(category: "Communication Quality", impact: impact, score: score, description: description)
    }
    
    private func analyzeResolutionRate(tenant: Tenant) -> Factor {
        guard let requests = tenant.maintenanceRequests as? Set<MaintenanceRequest>, !requests.isEmpty else {
            return Factor(category: "Issue Resolution", impact: .neutral, score: 0, description: "No issues reported")
        }
        
        let completedCount = requests.filter { $0.status == "Completed" }.count
        let completionRate = Double(completedCount) / Double(requests.count)
        
        var score: Double
        let impact: Factor.ImpactLevel
        let description: String
        
        if completionRate >= 0.95 {
            score = 12
            impact = .veryPositive
            description = "\(Int(completionRate * 100))% of issues resolved successfully"
        } else if completionRate >= 0.80 {
            score = 6
            impact = .positive
            description = "Most issues resolved"
        } else if completionRate < 0.60 {
            score = -12
            impact = .veryNegative
            description = "Low resolution rate - many open issues"
        } else {
            score = 0
            impact = .neutral
            description: "Average issue resolution"
        }
        
        return Factor(category: "Issue Resolution", impact: impact, score: score, description: description)
    }
    
    private func analyzePropertyCondition(tenant: Tenant) -> Factor {
        // Analyze based on recent inspections and maintenance frequency
        guard let requests = tenant.maintenanceRequests as? Set<MaintenanceRequest> else {
            return Factor(category: "Property Condition", impact: .positive, score: 5, description: "Property appears well-maintained")
        }
        
        let requestCount = requests.count
        
        var score: Double
        let impact: Factor.ImpactLevel
        let description: String
        
        if requestCount > 10 {
            score = -8
            impact = .negative
            description = "High maintenance frequency may indicate property condition issues"
        } else if requestCount > 6 {
            score = -3
            impact = .neutral
            description = "Moderate maintenance needs"
        } else {
            score = 8
            impact = .positive
            description = "Property in good condition with minimal issues"
        }
        
        return Factor(category: "Property Condition", impact: impact, score: score, description: description)
    }
    
    private func analyzeValuePerception(tenant: Tenant) -> Factor {
        // Analyze rent vs market and amenities
        let rentAmount = tenant.monthlyRent
        
        // Simulate market comparison (in production, use real market data)
        let marketAverage = rentAmount * 1.05 // Assume 5% above market
        
        var score: Double
        let impact: Factor.ImpactLevel
        let description: String
        
        if rentAmount < marketAverage * 0.95 {
            score = 8
            impact = .positive
            description = "Excellent value - below market average"
        } else if rentAmount > marketAverage * 1.10 {
            score = -6
            impact = .negative
            description = "Rent above market - value concerns possible"
        } else {
            score = 2
            impact = .neutral
            description: "Rent aligns with market value"
        }
        
        return Factor(category: "Value Perception", impact: impact, score: score, description: description)
    }
    
    private func calculateRetentionProbability(satisfactionScore: Double, tenant: Tenant) -> Double {
        // Base probability on satisfaction score
        var probability = satisfactionScore / 100.0
        
        // Adjust for lease end proximity
        if let leaseEnd = tenant.leaseEndDate {
            let daysUntilEnd = Calendar.current.dateComponents([.day], from: Date(), to: leaseEnd).day ?? 365
            if daysUntilEnd < 60 {
                probability *= 0.7 // Lower retention when lease is ending soon
            }
        }
        
        // Adjust for payment history
        if let payments = tenant.payments as? Set<Payment> {
            let latePayments = payments.filter { $0.isLate }.count
            if latePayments > 2 {
                probability *= 0.85
            }
        }
        
        return min(1.0, max(0.0, probability))
    }
    
    private func analyzeTrend(tenant: Tenant) -> Trend {
        // Compare recent sentiment to older sentiment
        guard let messages = tenant.messages as? Set<Message>, messages.count >= 5 else {
            return .stable
        }
        
        let sortedMessages = messages.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }
        let recent = Array(sortedMessages.prefix(3))
        let older = Array(sortedMessages.dropFirst(3).prefix(3))
        
        let recentPositive = recent.filter { $0.sentiment == "Positive" }.count
        let olderPositive = older.filter { $0.sentiment == "Positive" }.count
        
        if recentPositive > olderPositive {
            return .improving
        } else if recentPositive < olderPositive {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func generateInterventions(score: Double, factors: [Factor], trend: Trend) -> [Intervention] {
        var interventions: [Intervention] = []
        
        if score < 50 {
            interventions.append(Intervention(
                priority: .immediate,
                action: "Schedule personal check-in call with tenant",
                expectedImpact: "Address concerns before they escalate"
            ))
        }
        
        // Check for maintenance issues
        let maintenanceFactor = factors.first { $0.category == "Maintenance Response" }
        if maintenanceFactor?.impact == .negative || maintenanceFactor?.impact == .veryNegative {
            interventions.append(Intervention(
                priority: .immediate,
                action: "Expedite all pending maintenance requests",
                expectedImpact: "Improve satisfaction by 15-20 points"
            ))
        }
        
        // Communication issues
        let commFactor = factors.first { $0.category == "Communication Quality" }
        if commFactor?.impact == .veryNegative {
            interventions.append(Intervention(
                priority: .soon,
                action: "Send personalized message acknowledging concerns",
                expectedImpact: "Demonstrate responsiveness and care"
            ))
        }
        
        if trend == .declining {
            interventions.append(Intervention(
                priority: .soon,
                action: "Offer amenity upgrade or small rent concession",
                expectedImpact: "Reverse negative trend and improve retention"
            ))
        }
        
        if score >= 70 && trend != .declining {
            interventions.append(Intervention(
                priority: .planned,
                action: "Proactively offer lease renewal with incentive",
                expectedImpact: "Lock in satisfied tenant before market changes"
            ))
        }
        
        return interventions
    }
}
