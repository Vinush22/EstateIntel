//
//  MaintenanceTriageService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import Vision
import UIKit
import NaturalLanguage

/// AI service for classifying and prioritizing maintenance requests
class MaintenanceTriageService {
    
    struct TriageResult {
        let category: MaintenanceCategory
        let urgency: UrgencyLevel
        let confidence: Double
        let detectedIssues: [String]
        let suggestedContractor: String
        let estimatedCost: Double
        let estimatedDuration: String
    }
    
    enum MaintenanceCategory: String, CaseIterable {
        case plumbing = "Plumbing"
        case hvac = "HVAC"
        case electrical = "Electrical"
        case appliance = "Appliance"
        case structural = "Structural"
        case pest = "Pest Control"
        case noise = "Noise Complaint"
        case cleaning = "Cleaning"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .plumbing: return "drop.fill"
            case .hvac: return "wind"
            case .electrical: return "bolt.fill"
            case .appliance: return "refrigerator.fill"
            case .structural: return "hammer.fill"
            case .pest: return "ant.fill"
            case .noise: return "speaker.wave.2.fill"
            case .cleaning: return "sparkles"
            case .other: return "wrench.fill"
            }
        }
    }
    
    enum UrgencyLevel: String, CaseIterable {
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
        
        var score: Double {
            switch self {
            case .low: return 25
            case .medium: return 50
            case .high: return 75
            case .critical: return 100
            }
        }
    }
    
    /// Analyzes maintenance request text and images to classify and prioritize
    func analyzeRequest(description: String, images: [UIImage]?) async -> TriageResult {
        // Analyze text description
        let textAnalysis = analyzeText(description)
        
        // Analyze images if provided
        var imageAnalysis: (category: MaintenanceCategory?, confidence: Double, issues: [String]) = (nil, 0.0, [])
        if let images = images {
            imageAnalysis = await analyzeImages(images)
        }
        
        // Combine text and image analysis
        let category = imageAnalysis.category ?? textAnalysis.category
        let combinedConfidence = (textAnalysis.confidence + imageAnalysis.confidence) / 2.0
        let allIssues = textAnalysis.issues + imageAnalysis.issues
        
        // Determine urgency based on keywords and detected issues
        let urgency = calculateUrgency(description: description, category: category, issues: allIssues)
        
        // Suggest contractor based on category
        let contractor = suggestContractor(for: category)
        
        // Estimate cost and duration
        let cost = estimateCost(category: category, urgency: urgency)
        let duration = estimateDuration(category: category, urgency: urgency)
        
        return TriageResult(
            category: category,
            urgency: urgency,
            confidence: max(combinedConfidence, 0.6), // Minimum confidence
            detectedIssues: Array(Set(allIssues)), // Remove duplicates
            suggestedContractor: contractor,
            estimatedCost: cost,
            estimatedDuration: duration
        )
    }
    
    private func analyzeText(_ text: String) -> (category: MaintenanceCategory, confidence: Double, issues: [String]) {
        let lowercased = text.lowercased()
        var detectedIssues: [String] = []
        var categoryScores: [MaintenanceCategory: Double] = [:]
        
        // Plumbing keywords
        let plumbingKeywords = ["leak", "water", "pipe", "drain", "toilet", "faucet", "sink", "shower", "bathtub", "clog"]
        if plumbingKeywords.contains(where: { lowercased.contains($0) }) {
            categoryScores[.plumbing] = 0.9
            if lowercased.contains("leak") { detectedIssues.append("Water leak detected") }
            if lowercased.contains("clog") { detectedIssues.append("Drainage issue") }
        }
        
        // HVAC keywords
        let hvacKeywords = ["heat", "cold", "ac", "air conditioning", "thermostat", "temperature", "furnace", "cooling", "heating"]
        if hvacKeywords.contains(where: { lowercased.contains($0) }) {
            categoryScores[.hvac] = 0.85
            if lowercased.contains("not working") || lowercased.contains("broken") {
                detectedIssues.append("System malfunction")
            }
        }
        
        // Electrical keywords
        let electricalKeywords = ["electric", "power", "outlet", "light", "switch", "breaker", "wire", "spark"]
        if electricalKeywords.contains(where: { lowercased.contains($0) }) {
            categoryScores[.electrical] = 0.9
            if lowercased.contains("spark") { detectedIssues.append("Electrical hazard") }
        }
        
        // Appliance keywords
        let applianceKeywords = ["refrigerator", "stove", "oven", "dishwasher", "washer", "dryer", "microwave"]
        if applianceKeywords.contains(where: { lowercased.contains($0) }) {
            categoryScores[.appliance] = 0.85
            detectedIssues.append("Appliance issue")
        }
        
        // Noise keywords
        let noiseKeywords = ["noise", "loud", "sound", "neighbor", "music", "barking"]
        if noiseKeywords.contains(where: { lowercased.contains($0) }) {
            categoryScores[.noise] = 0.8
            detectedIssues.append("Noise disturbance")
        }
        
        // Pest keywords
        let pestKeywords = ["bug", "insect", "mouse", "rat", "roach", "pest", "ant", "spider"]
        if pestKeywords.contains(where: { lowercased.contains($0) }) {
            categoryScores[.pest] = 0.9
            detectedIssues.append("Pest infestation")
        }
        
        // Find highest scoring category
        let topCategory = categoryScores.max { $0.value < $1.value }
        
        return (
            category: topCategory?.key ?? .other,
            confidence: topCategory?.value ?? 0.5,
            issues: detectedIssues
        )
    }
    
    private func analyzeImages(_ images: [UIImage]) async -> (category: MaintenanceCategory?, confidence: Double, issues: [String]) {
        // In production, this would use a trained CoreML model for damage classification
        // For now, we'll use Vision framework's default image analysis as a placeholder
        
        var detectedIssues: [String] = []
        
        // Simulate ML image classification
        // In real implementation, load CoreML model and classify images
        
        // For demo purposes, we'll return a simulated result
        detectedIssues.append("Visual damage detected")
        
        return (category: nil, confidence: 0.7, issues: detectedIssues)
    }
    
    private func calculateUrgency(description: String, category: MaintenanceCategory, issues: [String]) -> UrgencyLevel {
        let lowercased = description.lowercased()
        
        // Critical urgency keywords
        let criticalKeywords = ["emergency", "urgent", "immediately", "dangerous", "safety", "fire", "gas", "flood", "spark"]
        if criticalKeywords.contains(where: { lowercased.contains($0) }) {
            return .critical
        }
        
        // High urgency keywords
        let highKeywords = ["broken", "not working", "completely", "won't", "can't", "no water", "no heat"]
        if highKeywords.contains(where: { lowercased.contains($0) }) {
            return .high
        }
        
        // Category-based urgency
        if category == .electrical && issues.contains("Electrical hazard") {
            return .critical
        }
        
        if category == .plumbing && issues.contains("Water leak detected") {
            return .high
        }
        
        // Medium urgency keywords
        let mediumKeywords = ["soon", "asap", "problem", "issue"]
        if mediumKeywords.contains(where: { lowercased.contains($0) }) {
            return .medium
        }
        
        return .low
    }
    
    private func suggestContractor(for category: MaintenanceCategory) -> String {
        // In production, this would match with a database of contractors
        let contractors: [MaintenanceCategory: String] = [
            .plumbing: "Ace Plumbing Services - (555) 123-4567",
            .hvac: "CoolAir HVAC Specialists - (555) 234-5678",
            .electrical: "Bright Electric Co. - (555) 345-6789",
            .appliance: "Fix-It Appliance Repair - (555) 456-7890",
            .structural: "Strong Build Contractors - (555) 567-8901",
            .pest: "BugBe-Gone Exterminators - (555) 678-9012",
            .cleaning: "Sparkle Clean Services - (555) 789-0123",
            .noise: "Property Management Team",
            .other: "General Maintenance Crew - (555) 890-1234"
        ]
        
        return contractors[category] ?? "General Maintenance Crew - (555) 890-1234"
    }
    
    private func estimateCost(category: MaintenanceCategory, urgency: UrgencyLevel) -> Double {
        let baseCosts: [MaintenanceCategory: Double] = [
            .plumbing: 150,
            .hvac: 200,
            .electrical: 125,
            .appliance: 100,
            .structural: 300,
            .pest: 175,
            .cleaning: 75,
            .noise: 0,
            .other: 100
        ]
        
        let urgencyMultiplier: [UrgencyLevel: Double] = [
            .low: 1.0,
            .medium: 1.2,
            .high: 1.5,
            .critical: 2.0
        ]
        
        let baseCost = baseCosts[category] ?? 100
        let multiplier = urgencyMultiplier[urgency] ?? 1.0
        
        return baseCost * multiplier
    }
    
    private func estimateDuration(category: MaintenanceCategory, urgency: UrgencyLevel) -> String {
        if urgency == .critical {
            return "Same day"
        } else if urgency == .high {
            return "1-2 days"
        } else if urgency == .medium {
            return "3-5 days"
        } else {
            return "1-2 weeks"
        }
    }
}
