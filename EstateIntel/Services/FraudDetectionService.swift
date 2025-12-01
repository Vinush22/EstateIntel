//
//  FraudDetectionService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData
import UIKit

/// AI service for detecting fraudulent tenant applications and documents
class FraudDetectionService {
    
    struct FraudAnalysis {
        let riskScore: Double // 0-100
        let riskLevel: RiskLevel
        let fraudFlags: [FraudFlag]
        let documentAuthenticity: Double // 0-1
        let paymentRiskFactors: [String]
        let overallAssessment: String
    }
    
    enum RiskLevel: String {
        case low = "Low Risk"
        case medium = "Medium Risk"
        case high = "High Risk"
        case critical = "Critical Risk"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    struct FraudFlag {
        let category: String
        let description: String
        let severity: Int // 1-10
    }
    
    /// Analyzes tenant application and documents for fraud indicators
    func analyzeTenantApplication(tenant: Tenant, documents: [Document], payments: [Payment]) -> FraudAnalysis {
        var fraudFlags: [FraudFlag] = []
        var totalRiskScore: Double = 0
        
        // Analyze documents
        let docFlags = analyzeDocuments(documents)
        fraudFlags.append(contentsOf: docFlags)
        totalRiskScore += Double(docFlags.reduce(0) { $0 + $1.severity }) * 5
        
        // Analyze payment patterns
        let paymentFlags = analyzePaymentPatterns(payments)
        fraudFlags.append(contentsOf: paymentFlags)
        totalRiskScore += Double(paymentFlags.reduce(0) { $0 + $1.severity }) * 4
        
        // Analyze income vs rent ratio
        if let incomeFlag = verifyIncomeRatio(tenant: tenant) {
            fraudFlags.append(incomeFlag)
            totalRiskScore += Double(incomeFlag.severity) * 6
        }
        
        // Check for identity inconsistencies
        if let identityFlag = checkIdentityConsistency(tenant: tenant, documents: documents) {
            fraudFlags.append(identityFlag)
            totalRiskScore += Double(identityFlag.severity) * 8
        }
        
        // Cap risk score at 100
        totalRiskScore = min(totalRiskScore, 100)
        
        // Determine risk level
        let riskLevel: RiskLevel
        if totalRiskScore < 30 {
            riskLevel = .low
        } else if totalRiskScore < 60 {
            riskLevel = .medium
        } else if totalRiskScore < 85 {
            riskLevel = .high
        } else {
            riskLevel = .critical
        }
        
        // Calculate document authenticity
        let avgAuthenticity = documents.isEmpty ? 0.8 : documents.map { $0.documentAuthenticity }.reduce(0, +) / Double(documents.count)
        
        // Payment risk factors
        let paymentRiskFactors = extractPaymentRisks(payments)
        
        // Overall assessment
        let assessment = generateAssessment(riskLevel: riskLevel, flags: fraudFlags)
        
        return FraudAnalysis(
            riskScore: totalRiskScore,
            riskLevel: riskLevel,
            fraudFlags: fraudFlags,
            documentAuthenticity: avgAuthenticity,
            paymentRiskFactors: paymentRiskFactors,
            overallAssessment: assessment
        )
    }
    
    private func analyzeDocuments(_ documents: [Document]) -> [FraudFlag] {
        var flags: [FraudFlag] = []
        
        for document in documents {
            // Check for low OCR confidence
            if document.extractionConfidence < 0.6 {
                flags.append(FraudFlag(
                    category: "Document Quality",
                    description: "Low quality or altered \(document.documentType ?? "document") detected",
                    severity: 6
                ))
            }
            
            // Check for high fraud risk score from document
            if document.fraudRiskScore > 70 {
                flags.append(FraudFlag(
                    category: "Fraudulent Document",
                    description: "\(document.documentType ?? "Document") shows signs of forgery",
                    severity: 9
                ))
            }
            
            // Check for validation issues
            if let issues = document.validationIssues,
               let issuesArray = try? JSONDecoder().decode([String].self, from: Data(issues.utf8)),
               issuesArray.count > 2 {
                flags.append(FraudFlag(
                    category: "Inconsistent Data",
                    description: "Multiple validation issues found in \(document.documentType ?? "document")",
                    severity: 5
                ))
            }
        }
        
        return flags
    }
    
    private func analyzePaymentPatterns(_ payments: [Payment]) -> [FraudFlag] {
        var flags: [FraudFlag] = []
        
        guard !payments.isEmpty else { return flags }
        
        // Check for unusual payment methods
        let methodCounts = Dictionary(grouping: payments) { $0.paymentMethod }
        if methodCounts.count > 3 {
            flags.append(FraudFlag(
                category: "Payment Behavior",
                description: "Frequent changes in payment methods (possible card testing)",
                severity: 4
            ))
        }
        
        // Check for late payments pattern
        let latePayments = payments.filter { $0.isLate }
        let lateRatio = Double(latePayments.count) / Double(payments.count)
        if lateRatio > 0.3 {
            flags.append(FraudFlag(
                category: "Payment History",
                description: "High frequency of late payments (\(Int(lateRatio * 100))%)",
                severity: 6
            ))
        }
        
        // Check for unusual pattern flags
        let flaggedPayments = payments.filter { $0.unusualPatternDetected }
        if !flaggedPayments.isEmpty {
            flags.append(FraudFlag(
                category: "Suspicious Activity",
                description: "\(flaggedPayments.count) payment(s) flagged with unusual patterns",
                severity: 7
            ))
        }
        
        return flags
    }
    
    private func verifyIncomeRatio(tenant: Tenant) -> FraudFlag? {
        let monthlyIncome = tenant.monthlyIncome
        let monthlyRent = tenant.monthlyRent
        
        guard monthlyIncome > 0 else {
            return FraudFlag(
                category: "Missing Data",
                description: "No income information provided",
                severity: 3
            )
        }
        
        let rentToIncomeRatio = monthlyRent / monthlyIncome
        
        // Standard guideline is rent should be <= 30% of income
        if rentToIncomeRatio > 0.5 {
            return FraudFlag(
                category: "Financial Inconsistency",
                description: "Rent is \(Int(rentToIncomeRatio * 100))% of stated income (typically should be <30%)",
                severity: 8
            )
        }
        
        return nil
    }
    
    private func checkIdentityConsistency(tenant: Tenant, documents: [Document]) -> FraudFlag? {
        // Check if tenant name matches documents
        // In production, this would parse extracted data from ID documents
        
        let tenantName = tenant.fullName.lowercased()
        
        for document in documents where document.documentType == "ID" {
            // Simulate name extraction check
            // In real implementation, parse the extractedDataJSON
            if let extractedData = document.extractedDataJSON,
               extractedData.lowercased().contains(tenantName) == false {
                return FraudFlag(
                    category: "Identity Mismatch",
                    description: "Name on ID document doesn't match application",
                    severity: 10
                )
            }
        }
        
        return nil
    }
    
    private func extractPaymentRisks(_ payments: [Payment]) -> [String] {
        var risks: [String] = []
        
        let lateCount = payments.filter { $0.isLate }.count
        if lateCount > 0 {
            risks.append("\(lateCount) late payment(s)")
        }
        
        let failedPayments = payments.filter { $0.status == "Failed" }.count
        if failedPayments > 0 {
            risks.append("\(failedPayments) failed transaction(s)")
        }
        
        let unusualPayments = payments.filter { $0.unusualPatternDetected }.count
        if unusualPayments > 0 {
            risks.append("\(unusualPayments) unusual pattern(s)")
        }
        
        return risks.isEmpty ? ["No major concerns"] : risks
    }
    
    private func generateAssessment(riskLevel: RiskLevel, flags: [FraudFlag]) -> String {
        switch riskLevel {
        case .low:
            return "✅ Application appears legitimate with no major red flags. Standard verification recommended."
        case .medium:
            return "⚠️ Some concerns detected. Additional verification and documentation recommended before approval."
        case .high:
            return "🔴 Multiple fraud indicators present. Thorough investigation required. Consider requiring additional documentation."
        case .critical:
            return "🚫 CRITICAL: Severe fraud indicators detected. Strong recommendation to REJECT application or conduct extensive verification with legal counsel."
        }
    }
}
