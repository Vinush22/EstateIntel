//
//  Color+Theme.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI

extension Color {
    // Primary Brand Colors
    static let primaryBlue = Color(red: 0.2, green: 0.45, blue: 0.85)
    static let primaryDark = Color(red: 0.12, green: 0.15, blue: 0.25)
    static let accentGreen = Color(red: 0.2, green: 0.75, blue: 0.4)
    
    // Risk/Status Colors
    static let riskLow = Color.green
    static let riskMedium = Color.yellow
    static let riskHigh = Color.orange
    static let riskCritical = Color.red
    
    // Sentiment Colors
    static let sentimentPositive = Color.green
    static let sentimentNeutral = Color.gray
    static let sentimentNegative = Color.red
    
    // Background Colors
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    // Helper to get color by risk level string
    static func riskColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "low", "low risk":
            return .riskLow
        case "medium", "medium risk":
            return .riskMedium
        case "high", "high risk":
            return .riskHigh
        case "critical", "critical risk", "imminent":
            return .riskCritical
        default:
            return .gray
        }
    }
}
