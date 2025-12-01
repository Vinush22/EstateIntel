//
//  PredictiveMaintenanceView.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI
import CoreData

struct PredictiveMaintenanceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.name, ascending: true)])
    private var properties: FetchedResults<Property>
    
    @State private var selectedProperty: Property?
    @State private var predictions: [PredictiveMaintenanceService.MaintenancePrediction] = []
    
    private let maintenanceService = PredictiveMaintenanceService()
    
    var body: some View {
        NavigationView {
            List {
                // Property Selector
                Section("Select Property") {
                    Picker("Property", selection: $selectedProperty) {
                        Text("No Selection").tag(Property?.none)
                        ForEach(properties, id: \.id) { property in
                            Text(property.name ?? "Unknown").tag(property as Property?)
                        }
                    }
                    .onChange(of: selectedProperty) { newValue in
                        if let property = newValue {
                            loadPredictions(for: property)
                        }
                    }
                }
                
                // Predictions
                if predictions.isEmpty {
                    Section {
                        Text("Select a property to view maintenance predictions")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                } else {
                    Section("Predicted Failures") {
                        ForEach(predictions) { prediction in
                            PredictionRow(prediction: prediction)
                        }
                    }
                }
            }
            .navigationTitle("Predictive Maintenance")
        }
    }
    
    private func loadPredictions(for property: Property) {
        predictions = maintenanceService.analyzeMaintenance(for: property, context: viewContext)
    }
}

struct PredictionRow: View {
    let prediction: PredictiveMaintenanceService.MaintenancePrediction
    
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(prediction.equipmentType)
                        .font(.headline)
                    
                    Spacer()
                    
                    RiskBadge(level: prediction.severity.rawValue)
                }
                
                HStack {
                    Label(prediction.equipmentID, systemImage: "gear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(prediction.predictedFailureDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Est. Cost: $\(Int(prediction.estimatedCost))")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Confidence: \(Int(prediction.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingDetail) {
            PredictionDetailView(prediction: prediction)
        }
    }
}

struct PredictionDetailView: View {
    let prediction: PredictiveMaintenanceService.MaintenancePrediction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Equipment") {
                    LabeledRow(label: "Type", value: prediction.equipmentType)
                    LabeledRow(label: "ID", value: prediction.equipmentID)
                }
                
                Section("Prediction") {
                    HStack {
                        Text("Severity")
                        Spacer()
                        RiskBadge(level: prediction.severity.rawValue)
                    }
                    
                    LabeledRow(label: "Predicted Failure", value: prediction.predictedFailureDate.formatted(date: .long, time: .omitted))
                    LabeledRow(label: "Confidence", value: "\(Int(prediction.confidence * 100))%")
                    LabeledRow(label: "Estimated Cost", value: "$\(Int(prediction.estimatedCost))")
                }
                
                Section("Risk Factors") {
                    ForEach(prediction.riskFactors, id: \.self) { factor in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(factor)
                                .font(.footnote)
                        }
                    }
                }
                
                Section("Recommendation") {
                    Text(prediction.recommendedAction)
                        .font(.body)
                }
            }
            .navigationTitle("Prediction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LabeledRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    PredictiveMaintenanceView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
