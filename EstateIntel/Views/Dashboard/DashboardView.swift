//
//  DashboardView.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.name, ascending: true)],
        animation: .default)
    private var properties: FetchedResults<Property>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Est atate Intel")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("AI-Powered Property Management")
                            .font(.subheadline)
                            .foreground Color(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        AIInsightCard(
                            title: "Properties",
                            value: "\(properties.count)",
                            color: .primaryBlue,
                            icon: "building.2.fill"
                        )
                        
                        AIInsightCard(
                            title: "Occupancy Rate",
                            subtitle: "Across all properties",
                            value: "94%",
                            trend: .up,
                            color: .accentGreen,
                            icon: "person.3.fill"
                        )
                        
                        AIInsightCard(
                            title: "Maintenance Alerts",
                            subtitle: "Requires attention",
                            value: "3",
                            color: .orange,
                            icon: "exclamationmark.triangle.fill"
                        )
                        
                        AIInsightCard(
                            title: "Satisfaction",
                            subtitle: "Average tenant score",
                            value: "82%",
                            trend: .up,
                            color: .green,
                            icon: "face.smiling.fill"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickActionButton(
                                    title: "Scan Document",
                                    icon: "doc.viewfinder",
                                    color: .blue
                                )
                                
                                QuickActionButton(
                                    title: "Screen Applicant",
                                    icon: "person.badge.shield.checkmark",
                                    color: .green
                                )
                                
                                QuickActionButton(
                                    title: "Inspection",
                                    icon: "camera.fill",
                                    color: .purple
                                )
                                
                                QuickActionButton(
                                    title: "Energy Report",
                                    icon: "leaf.fill",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Alerts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Alerts & Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        AlertCard(
                            title: "High Vacancy Risk",
                            message: "Unit 304 - Tenant move-out probability: 78%",
                            category: "Vacancy",
                            severity: .high
                        )
                        
                        AlertCard(
                            title: "Maintenance Prediction",
                            message: "HVAC System - Predicted failure in 12 days",
                            category: "Maintenance",
                            severity: .critical
                        )
                        
                        AlertCard(
                            title: "Pricing Opportunity",
                            message: "Unit 201 - Can increase rent by $150/month",
                            category: "Pricing",
                            severity: .low
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                    }
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .cornerRadius(12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(width: 90)
    }
}

struct AlertCard: View {
    let title: String
    let message: String
    let category: String
    let severity: RiskLevel
    
    enum RiskLevel {
        case low, medium, high, critical
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(severity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severity.color.opacity(0.2))
                    .cornerRadius(6)
                
                Spacer()
                
                Text("2h ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
