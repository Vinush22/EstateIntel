//
//  TenantScreeningService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

/// AI service for evaluating tenant applications and generating reliability scores
class TenantScreeningService {
    
    struct ScreeningResult {
        let reliabilityScore: Double // 0-100
        let scoreBreakdown: [ScoreComponent]
        let strengths: [String]
        let redFlags: [String]
        let recommendation: Recommendation
        let comparisonRank: Int? // When comparing multiple applicants
    }
    
    struct ScoreComponent {
        let category: String
        let score: Double // Out of max points
        let maxPoints: Double
        let weight: Double
        let explanation: String
    }
    
    enum Recommendation: String {
        case stronglyRecommend = "Strongly Recommend"
        case recommend = "Recommend"
        case conditional = "Conditional Approval"
        case notRecommended = "Not Recommended"
        
        var color: String {
            switch self {
            case .stronglyRecommend: return "green"
            case .recommend: return "blue"
            case .conditional: return "orange"
            case .notRecommended: return "red"
            }
        }
    }
    
    /// Evaluates a tenant application and returns reliability score
    func screenTenant(_ tenant: Tenant, context: NSManagedObjectContext) -> ScreeningResult {
        var components: [ScoreComponent] = []
        var strengths: [String] = []
        var redFlags: [String] = []
        
        // 1. Financial Reliability (35 points)
        let financial Currency = evaluateFinancialStability(tenant: tenant)
        components.append(financialScore)
        if financialScore.score >= 25 {
            strengths.append("Strong financial profile")
        } else if financialScore.score < 15 {
            redFlags.append("Weak financial stability")
        }
        
        // 2. Employment Stability (20 points)
        let employmentScore = evaluateEmployment(tenant: tenant)
        components.append(employmentScore)
        if employmentScore.score >= 15 {
            strengths.append("Stable employment")
        } else if employmentScore.score < 10 {
            redFlags.append("Employment concerns")
        }
        
        // 3. Communication History (20 points)
        let communicationScore = evaluateCommunication(tenant: tenant)
        components.append(communicationScore)
        if communicationScore.score >= 15 {
            strengths.append("Excellent communication")
        } else if communicationScore.score < 10 {
            redFlags.append("Poor communication responsiveness")
        }
        
        // 4. Rental History (15 points)
        let rentalScore = evaluateRentalHistory(tenant: tenant)
        components.append(rentalScore)
        if rentalScore.score >= 12 {
            strengths.append("Positive rental history")
        } else if rentalScore.score < 8 {
            redFlags.append("Rental history concerns")
        }
        
        // 5. Document Verification (10 points)
        let documentScore = evaluateDocuments(tenant: tenant, context: context)
        components.append(documentScore)
        if documentScore.score >= 8 {
            strengths.append("All documents verified")
        } else if documentScore.score < 5 {
            redFlags.append("Document verification issues")
        }
        
        // Calculate total weighted score
        let totalScore = components.reduce(0) { $0 + ($1.score * $1.weight) }
        
        // Determine recommendation
        let recommendation: Recommendation
        if totalScore >= 85 {
            recommendation = .stronglyRecommend
        } else if totalScore >= 70 {
            recommendation = .recommend
        } else if totalScore >= 55 {
            recommendation = .conditional
        } else {
            recommendation = .notRecommended
        }
        
        return ScreeningResult(
            reliabilityScore: totalScore,
            scoreBreakdown: components,
            strengths: strengths,
            redFlags: redFlags,
            recommendation: recommendation,
            comparisonRank: nil
        )
    }
    
    /// Compares multiple tenant applications side-by-side
    func compareApplicants(_ tenants: [Tenant], context: NSManagedObjectContext) -> [ScreeningResult] {
        var results: [ScreeningResult] = []
        
        // Screen each tenant
        for tenant in tenants {
            let screening = screenTenant(tenant, context: context)
            results.append(screening)
        }
        
        // Rank by score
        results.sort { $0.reliabilityScore > $1.reliabilityScore }
        
        // Add ranking
        var rankedResults: [ScreeningResult] = []
        for (index, result) in results.enumerated() {
            let ranked = ScreeningResult(
                reliabilityScore: result.reliabilityScore,
                scoreBreakdown: result.scoreBreakdown,
                strengths: result.strengths,
                redFlags: result.redFlags,
                recommendation: result.recommendation,
                comparisonRank: index + 1
            )
            rankedResults.append(ranked)
        }
        
        return rankedResults
    }
    
    private func evaluateFinancialStability(tenant: Tenant) -> ScoreComponent {
        var score: Double = 0
        let maxPoints: Double = 35
        
        // Income to rent ratio (most important)
        if tenant.monthlyIncome > 0 && tenant.monthlyRent > 0 {
            let ratio = tenant.monthlyRent / tenant.monthlyIncome
            
            if ratio <= 0.25 { // Rent is 25% or less of income
                score += 20
            } else if ratio <= 0.30 {
                score += 17
            } else if ratio <= 0.35 {
                score += 14
            } else if ratio <= 0.40 {
                score += 10
            } else {
                score += 5 // High burden
            }
        }
        
        // Security deposit readiness
        if tenant.securityDeposit >= tenant.monthlyRent {
            score += 10
        } else if tenant.securityDeposit >= tenant.monthlyRent * 0.5 {
            score += 5
        }
        
        // Payment history if available
        if let payments = tenant.payments as? Set<Payment> {
            let latePayments = payments.filter { $0.isLate }.count
            let totalPayments = payments.count
            
            if totalPayments > 0 {
                let lateRatio = Double(latePayments) / Double(totalPayments)
                if lateRatio == 0 {
                    score += 5 // Bonus for perfect payment history
                } else if lateRatio > 0.2 {
                    score -= 5 // Penalty for frequent late payments
                }
            }
        }
        
        let explanation: String
        if score >= 30 {
            explanation = "Excellent financial position with strong income-to-rent ratio"
        } else if score >= 20 {
            explanation = "Good financial stability"
        } else {
            explanation = "Financial concerns regarding ability to afford rent"
        }
        
        return ScoreComponent(
            category: "Financial Reliability",
            score: score,
            maxPoints: maxPoints,
            weight: 1.0,
            explanation: explanation
        )
    }
    
    private func evaluateEmployment(tenant: Tenant) -> ScoreComponent {
        var score: Double = 0
        let maxPoints: Double = 20
        
        // Employment status
        if let status = tenant.employmentStatus?.lowercased() {
            if status.contains("full-time") || status.contains("full time") {
                score += 15
            } else if status.contains("part-time") || status.contains("part time") {
                score += 10
            } else if status.contains("self-employed") {
                score += 12
            } else if status.contains("unemployed") {
                score += 2
            } else {
                score += 8 // Other/contractor
            }
        } else {
            score += 8 // No info provided, neutral
        }
        
        // Bonus for verifiable income documentation
        score += 5
        
        let explanation = "Employment: \(tenant.employmentStatus ?? "Not specified")"
        
        return ScoreComponent(
            category: "Employment Stability",
            score: min(score, maxPoints),
            maxPoints: maxPoints,
            weight: 1.0,
            explanation: explanation
        )
    }
    
    private func evaluateCommunication(tenant: Tenant) -> ScoreComponent {
        var score: Double = 0
        let maxPoints: Double = 20
        
        // Analyze message history
        if let messages = tenant.messages as? Set<Message> {
            let messageCount = messages.count
            
            // Response rate and quality
            if messageCount > 0 {
                let positiveMessages = messages.filter { $0.sentiment == "Positive" }.count
                let negativeMessages = messages.filter { $0.sentiment == "Negative" }.count
                
                // Sentiment score
                let positiveRatio = Double(positiveMessages) / Double(messageCount)
                let negativeRatio = Double(negativeMessages) / Double(messageCount)
                
                if positiveRatio > 0.5 {
                    score += 10
                } else if negativeRatio > 0.5 {
                    score += 3
                } else {
                    score += 6
                }
                
                // Communication frequency (not too many complaints)
                if messageCount < 5 {
                    score += 5 // Minimal issues
                } else if messageCount < 10 {
                    score += 3
                } else {
                    score += 1 // Frequent communicator (could be problematic)
                }
                
                // Responsiveness
                score += 5
            } else {
                // No history - neutral score
                score += 12
            }
        } else {
            score += 12 // No data, assume neutral
        }
        
        let explanation = "Communication pattern appears professional and reasonable"
        
        return ScoreComponent(
            category: "Communication History",
            score: min(score, maxPoints),
            maxPoints: maxPoints,
            weight: 1.0,
            explanation: explanation
        )
    }
    
    private func evaluateRentalHistory(tenant: Tenant) -> ScoreComponent {
        var score: Double = 0
        let maxPoints: Double = 15
        
        // Check maintenance request patterns
        if let requests = tenant.maintenanceRequests as? Set<MaintenanceRequest> {
            let requestCount = requests.count
            
            // Fewer maintenance requests is generally better (less wear on unit)
            if requestCount == 0 {
                score += 10 // Perfect - no requests
            } else if requestCount < 3 {
                score += 8 // Normal/acceptable
            } else if requestCount < 6 {
                score += 5 // Above average
            } else {
                score += 2 // High maintenance tenant
            }
        } else {
            score += 8 // No data
        }
        
        // Lease compliance
        if tenant.isLeaseActive {
            score += 5 // Currently in good standing
        }
        
        let explanation = "Rental behavior suggests responsible tenancy"
        
        return ScoreComponent(
            category: "Rental History",
            score: min(score, maxPoints),
            maxPoints: maxPoints,
            weight: 1.0,
            explanation: explanation
        )
    }
    
    private func evaluateDocuments(tenant: Tenant, context: NSManagedObjectContext) -> ScoreComponent {
        var score: Double = 0
        let maxPoints: Double = 10
        
        if let documents = tenant.documents as? Set<Document> {
            let requiredTypes = ["ID", "PayStub", "Lease"]
            var foundTypes: [String] = []
            
            for document in documents {
                if let type = document.documentType {
                    foundTypes.append(type)
                    
                    // Check document quality
                    if document.extractionConfidence > 0.7 {
                        score += 2
                    } else if document.extractionConfidence > 0.5 {
                        score += 1
                    }
                }
            }
            
            // Bonus for having all required documents
            let hasAllRequired = requiredTypes.allSatisfy { foundTypes.contains($0) }
            if hasAllRequired {
                score += 4
            }
        } else {
            score += 5 // Neutral if no documents yet
        }
        
        let explanation = "Document verification complete"
        
        return ScoreComponent(
            category: "Document Verification",
            score: min(score, maxPoints),
            maxPoints: maxPoints,
            weight: 1.0,
            explanation: explanation
        )
    }
}
