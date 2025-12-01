//
//  TenantManagementView.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI
import CoreData

struct TenantManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tenant.firstName, ascending: true)])
    private var tenants: FetchedResults<Tenant>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tenants, id: \.id) { tenant in
                    NavigationLink(destination: TenantDetailView(tenant: tenant)) {
                        TenantRowView(tenant: tenant)
                    }
                }
            }
            .navigationTitle("Tenants")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: TenantScreeningView()) {
                        Label("Screen Applicant", systemImage: "person.badge.plus")
                    }
                }
            }
        }
    }
}

struct TenantRowView: View {
    @ObservedObject var tenant: Tenant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(tenant.fullName)
                    .font(.headline)
                
                Spacer()
                
                if tenant.reliabilityScore > 0 {
                    Text("\(Int(tenant.reliabilityScore))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(scoreColor(tenant.reliabilityScore))
                }
            }
            
            if let unit = tenant.unit {
                Text("Unit \(unit.unitNumber ?? "N/A")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                if tenant.satisfactionScore > 0 {
                    Label("\(Int(tenant.satisfactionScore))%", systemImage: "face.smiling")
                        .font(.caption2)
                        .foregroundColor(scoreColor(tenant.satisfactionScore))
                }
                
                if tenant.moveOutProbability > 0.5 {
                    Label("High Risk", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 75 {
            return .green
        } else if score >= 50 {
            return .orange
        } else {
            return .red
        }
    }
}

struct TenantDetailView: View {
    @ObservedObject var tenant: Tenant
    @State private var satisfactionAnalysis: SatisfactionPredictionService.SatisfactionAnalysis?
    
    private let satisfactionService = SatisfactionPredictionService()
    
    var body: some View {
        List {
            Section("Tenant Information") {
                LabeledRow(label: "Name", value: tenant.fullName)
                LabeledRow(label: "Email", value: tenant.email ?? "N/A")
                LabeledRow(label: "Phone", value: tenant.phone ?? "N/A")
                if let unit = tenant.unit {
                    LabeledRow(label: "Unit", value: unit.unitNumber ?? "N/A")
                }
            }
            
            Section("AI Scores") {
                HStack {
                    Text("Reliability Score")
                    Spacer()
                    Text("\(Int(tenant.reliabilityScore))%")
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(tenant.reliabilityScore))
                }
                
                HStack {
                    Text("Satisfaction Score")
                    Spacer()
                    Text("\(Int(tenant.satisfactionScore))%")
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(tenant.satisfactionScore))
                }
                
                HStack {
                    Text("Move-Out Risk")
                    Spacer()
                    Text("\(Int(tenant.moveOutProbability * 100))%")
                        .fontWeight(.bold)
                        .foregroundColor(tenant.moveOutProbability > 0.6 ? .red : .green)
                }
            }
            
            if let analysis = satisfactionAnalysis {
                Section("Satisfaction Analysis") {
                    ForEach(analysis.satisfactionFactors.prefix(3), id: \.category) { factor in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(factor.category)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(factor.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !analysis.interventionSuggestions.isEmpty {
                    Section("Recommended Actions") {
                        ForEach(analysis.interventionSuggestions.prefix(2), id: \.action) { intervention in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(intervention.action)
                                        .font(.footnote)
                                    Spacer()
                                    Text(intervention.priority.rawValue)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                Text(intervention.expectedImpact)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tenant Details")
        .onAppear {
            satisfactionAnalysis = satisfactionService.predictSatisfaction(
                for: tenant,
                context: tenant.managedObjectContext!
            )
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 75 {
            return .green
        } else if score >= 50 {
            return .orange
        } else {
            return .red
        }
    }
}

struct TenantScreeningView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Tenant Screening")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Upload applicant documents and run AI-powered screening analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Feature overview
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(icon: "doc.text.magnifyingglass", title: "Document Analysis", description: "OCR extraction and fraud detection")
                    FeatureItem(icon: "chart.bar", title: "Reliability Scoring", description: "Multi-factor tenant evaluation")
                    FeatureItem(icon: "person.2.badge.gearshape", title: "Applicant Comparison", description: "Side-by-side ranking")
                }
                .padding()
            }
        }
        .navigationTitle("Screen Applicant")
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    TenantManagementView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
