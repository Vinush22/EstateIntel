//
//  RentPricingService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import CoreData

/// AI service for optimizing rental pricing
class RentPricingService {
    
    struct PricingRecommendation {
        let recommendedRent: Double
        let currentRent: Double
        let changePercentage: Double
        let confidence: Double
        let justificationFactors: [JustificationFactor]
        let marketComparison: MarketComparison
    }
    
    struct JustificationFactor {
        let category: String
        let impact: Double // -10 to +10 percentage points
        let description: String
    }
    
    struct MarketComparison {
        let averageInArea: Double
        let percentile: Int // Where this unit ranks
        let competitivePosition: String
    }
    
    struct WhatIfScenario {
        let scenarioName: String
        let adjustedRent: Double
        let factors: [String: Double]
    }
    
    /// Analyzes unit and market data to recommend optimal rent price
    func calculateOptimalRent(for unit: Unit, context: NSManagedObjectContext) -> PricingRecommendation {
        let currentRent = unit.monthlyRent
        
        // Calculate base rent based on size and bedrooms
        var recommendedRent = calculateBaseRent(unit: unit)
        
        // Collect justification factors
        var factors: [JustificationFactor] = []
        
        // Adjust for amenities
        if let property = unit.property {
            let amenityAdjustment = calculateAmenityValue(property: property)
            recommendedRent *= (1.0 + amenityAdjustment)
            factors.append(JustificationFactor(
                category: "Property Amenities",
                impact: amenityAdjustment * 100,
                description: "Gym, pool, and parking add \(Int(amenityAdjustment * 100))% value"
            ))
        }
        
        // Adjust for location (simulated - in production, use real location data)
        let locationFactor = calculateLocationValue()
        recommendedRent *= (1.0 + locationFactor)
        factors.append(JustificationFactor(
            category: "Location Premium",
            impact: locationFactor * 100,
            description: "Desirable neighborhood with good schools"
        ))
        
        // Seasonal adjustment
        let seasonalFactor = calculateSeasonalAdjustment()
        recommendedRent *= (1.0 + seasonalFactor)
        if abs(seasonalFactor) > 0.01 {
            factors.append(JustificationFactor(
                category: "Seasonal Demand",
                impact: seasonalFactor * 100,
                description: seasonalFactor > 0 ? "Peak rental season (spring/summer)" : "Off-season discount"
            ))
        }
        
        // Market trend adjustment
        let marketTrend = calculateMarketTrend()
        recommendedRent *= (1.0 + marketTrend)
        factors.append(JustificationFactor(
            category: "Market Trends",
            impact: marketTrend * 100,
            description: marketTrend > 0 ? "Rising market conditions" : "Softening market"
        ))
        
        // Unit-specific features
        let featureFactor = calculateFeatureValue(unit: unit)
        recommendedRent *= (1.0 + featureFactor)
        if abs(featureFactor) > 0.01 {
            factors.append(JustificationFactor(
                category: "Unit Features",
                impact: featureFactor * 100,
                description: "Updated appliances and flooring"
            ))
        }
        
        // Round to nearest $25
        recommendedRent = round(recommendedRent / 25) * 25
        
        // Calculate change percentage
        let changePercent = ((recommendedRent - currentRent) / currentRent) * 100
        
        // Market comparison (simulated)
        let marketComp = MarketComparison(
            averageInArea: recommendedRent * 0.97, // Slightly below recommendation
            percentile: 65,
            competitivePosition: "Above Average"
        )
        
        return PricingRecommendation(
            recommendedRent: recommendedRent,
            currentRent: currentRent,
            changePercentage: changePercent,
            confidence: 0.78,
            justificationFactors: factors,
            marketComparison: marketComp
        )
    }
    
    /// Calculates what-if scenarios with different parameters
    func calculateWhatIfScenario(baseRent: Double, adjustments: [String: Double]) -> WhatIfScenario {
        var adjustedRent = baseRent
        
        for (_, value) in adjustments {
            adjustedRent *= (1.0 + value)
        }
        
        adjustedRent = round(adjustedRent / 25) * 25
        
        return WhatIfScenario(
            scenarioName: "Custom Scenario",
            adjustedRent: adjustedRent,
            factors: adjustments
        )
    }
    
    private func calculateBaseRent(unit: Unit) -> Double {
        // Base rent calculation based on square footage and bedrooms
        let sqftRate = 2.5 // $2.50 per square foot (varies by market)
        let bedroomValue = 300.0 // $300 per bedroom
        
        var baseRent = unit.squareFeet * sqftRate
        baseRent += Double(unit.bedrooms) * bedroomValue
        
        // Bathroom adjustment
        baseRent += unit.bathrooms * 150
        
        // Floor preference (higher floors command premium)
        if unit.floor > 3 {
            baseRent *= 1.05 // 5% premium for higher floors
        }
        
        return baseRent
    }
    
    private func calculateAmenityValue(property: Property) -> Double {
        // In production, parse amenities from property.amenities JSON
        // For now, return a simulated value
        return 0.08 // 8% premium for amenities
    }
    
    private func calculateLocationValue() -> Double {
        // In production, use real location data, crime rates, school ratings, etc.
        return 0.12 // 12% location premium
    }
    
    private func calculateSeasonalAdjustment() -> Double {
        let month = Calendar.current.component(.month, from: Date())
        
        // Spring (Apr-June) and early Fall (Sep-Oct) are peak rental seasons
        switch month {
        case 4, 5, 6:
            return 0.05 // 5% premium in peak season
        case 9, 10:
            return 0.03 // 3% premium in fall
        case 11, 12, 1, 2:
            return -0.02 // 2% discount in winter
        default:
            return 0.0
        }
    }
    
    private func calculateMarketTrend() -> Double {
        // In production, analyze historical rent data and market reports
        // Simulating a growing market
        return 0.04 // 4% market growth
    }
    
    private func calculateFeatureValue(unit: Unit) -> Double {
        // Parse features from unit.features JSON
        // For now, return simulated value based on unit age/condition
        return 0.05 // 5% premium for updated features
    }
}
