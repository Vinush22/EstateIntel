//
//  AIInsightCard.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI

/// Reusable card component for displaying AI-generated insights
struct AIInsightCard: View {
    let title: String
    let subtitle: String?
    let value: String
    let trend: TrendIndicator?
    let color: Color
    let icon: String
    
    enum TrendIndicator {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }
    
    init(title: String, subtitle: String? = nil, value: String, trend: TrendIndicator? = nil, color: Color = .blue, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.trend = trend
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        AIInsightCard(
            title: "Satisfaction Score",
            subtitle: "Based on 5 factors",
            value: "85%",
            trend: .up,
            color: .green,
            icon: "face.smiling.fill"
        )
        
        AIInsightCard(
            title: "Vacancy Risk",
            subtitle: "Next 90 days",
            value: "Low",
            trend: .down,
            color: .blue,
            icon: "building.2.fill"
        )
    }
    .padding()
}
