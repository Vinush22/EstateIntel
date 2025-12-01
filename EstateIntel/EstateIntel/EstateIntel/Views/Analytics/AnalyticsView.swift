//
//  AnalyticsView.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var selectedModule: AnalyticsModule = .vacancy
    
    enum AnalyticsModule: String, CaseIterable {
        case vacancy = "Vacancy Prediction"
        case energy = "Energy Optimization"
        case pricing = "Rent Pricing"
        case risk = "Risk & Fraud"
        case inspection = "Inspections"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Module Selector
                    Picker("Analytics Module", selection: $selectedModule) {
                        ForEach(AnalyticsModule.allCases, id: \.self) { module in
                            Text(module.rawValue).tag(module)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Module Content
                    switch selectedModule {
                    case .vacancy:
                        VacancyAnalyticsView()
                    case .energy:
                        EnergyAnalyticsView()
                    case .pricing:
                        PricingAnalyticsView()
                    case .risk:
                        RiskAnalyticsView()
                    case .inspection:
                        InspectionAnalyticsView()
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

struct VacancyAnalyticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vacancy Forecasting")
                .font(.headline)
                .padding(.horizontal)
            
            // Summary Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AIInsightCard(
                    title: "Units at Risk",
                    value: "4",
                    color: .orange,
                    icon: "exclamationmark.triangle.fill"
                )
                
                AIInsightCard(
                    title: "Avg Vacancy Days",
                    value: "28",
                    trend: .down,
                    color: .green,
                    icon: "calendar"
                )
            }
            .padding(.horizontal)
            
            // Mock Units List
            VStack(alignment: .leading, spacing: 8) {
                Text("High Risk Units")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                VacancyUnitRow(unit: "Unit 304", probability: 78, daysUntil: 45)
                VacancyUnitRow(unit: "Unit 201", probability: 65, daysUntil: 60)
                VacancyUnitRow(unit: "Unit 512", probability: 58, daysUntil: 75)
            }
        }
    }
}

struct VacancyUnitRow: View {
    let unit: String
    let probability: Int
    let daysUntil: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(unit)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Est. \(daysUntil) days until vacancy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(probability)%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(probability > 70 ? .red : .orange)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct EnergyAnalyticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Energy Optimization")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AIInsightCard(
                    title: "Potential Savings",
                    value: "$420",
                    color: .green,
                    icon: "dollarsign.circle.fill"
                )
                
                AIInsightCard(
                    title: "Efficiency Score",
                    value: "72/100",
                    trend: .up,
                    color: .blue,
                    icon: "leaf.fill"
                )
            }
            .padding(.horizontal)
            
            // Anomalies
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected Anomalies")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                AnomalyCard(type: "Electricity", unit: "Unit 405", increase: 45)
                AnomalyCard(type: "Water", unit: "Unit 210", increase: 62)
            }
        }
    }
}

struct AnomalyCard: View {
    let type: String
    let unit: String
    let increase: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(increase)%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct PricingAnalyticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rent Optimization")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AIInsightCard(
                    title: "Revenue Potential",
                    value: "$2,400",
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                AIInsightCard(
                    title: "Market Position",
                    value: "Above Avg",
                    color: .blue,
                    icon: "building.2"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct RiskAnalyticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk & Fraud Detection")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AIInsightCard(
                    title: "High Risk Applications",
                    value: "2",
                    color: .red,
                    icon: "exclamationmark.shield.fill"
                )
                
                AIInsightCard(
                    title: "Fraud Detections",
                    value: "1",
                    color: .orange,
                    icon: "xmark.shield.fill"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct InspectionAnalyticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inspection Insights")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AIInsightCard(
                    title: "Inspections This Month",
                    value: "12",
                    color: .blue,
                    icon: "camera.fill"
                )
                
                AIInsightCard(
                    title: "Avg Damages Found",
                    value: "3.2",
                    color: .orange,
                    icon: "exclamationmark.triangle.fill"
                )
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    AnalyticsView()
}
