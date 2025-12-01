//
//  RiskBadge.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI

/// Color-coded badge for displaying risk levels
struct RiskBadge: View {
    let level: String
    let showIcon: Bool
    
    init(level: String, showIcon: Bool = true) {
        self.level = level
        self.showIcon = showIcon
    }
    
    private var color: Color {
        Color.riskColor(level)
    }
    
    private var icon: String {
        switch level.lowercased() {
        case "low", "low risk":
            return "checkmark.shield.fill"
        case "medium", "medium risk":
            return "exclamationmark.triangle.fill"
        case "high", "high risk":
            return "exclamationmark.octagon.fill"
        case "critical", "critical risk", "imminent":
            return "xmark.shield.fill"
        default:
            return "shield.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: icon)
                    .font(.caption)
            }
            
            Text(level)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 12) {
        RiskBadge(level: "Low Risk")
        RiskBadge(level: "Medium Risk")
        RiskBadge(level: "High Risk")
        RiskBadge(level: "Critical Risk")
    }
    .padding()
}
