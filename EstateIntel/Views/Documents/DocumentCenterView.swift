//
//  DocumentCenterView.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI
import VisionKit

struct DocumentCenterView: View {
    @State private var showingScanner = false
    @State private var scannedImage: UIImage?
    @State private var extractionResult: DocumentScannerService.ExtractionResult?
    @State private var isProcessing = false
    
    private let scannerService = DocumentScannerService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Scanner Button
                    Button(action: { showingScanner = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            Text("Scan New Document")
                                .font(.headline)
                            
                            Text("Automatically extract lease data with AI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    // Processing Indicator
                    if isProcessing {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Processing document...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Extraction Results
                    if let result = extractionResult {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Extraction Results")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Confidence Score
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Extraction Confidence"
                                    Spacer()
                                    Text("\(Int(result.confidence * 100))%")
                                        .fontWeight(.bold)
                                        .foregroundColor(result.confidence > 0.7 ? .green : .orange)
                                }
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Extracted Data
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Extracted Information")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                if let tenantName = result.structuredData.tenantName {
                                    DataField(label: "Tenant Name", value: tenantName)
                                }
                                
                                if let address = result.structuredData.propertyAddress {
                                    DataField(label: "Property Address", value: address)
                                }
                                
                                if let rent = result.structuredData.monthlyRent {
                                    DataField(label: "Monthly Rent", value: "$\(Int(rent))")
                                }
                                
                                if let startDate = result.structuredData.leaseStartDate {
                                    DataField(label: "Lease Start", value: startDate.formatted(date: .long, time: .omitted))
                                }
                                
                                if let endDate = result.structuredData.leaseEndDate {
                                    DataField(label: "Lease End", value: endDate.formatted(date: .long, time: .omitted))
                                }
                            }
                            
                            // Validation Issues
                            if !result.validationIssues.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Validation Issues")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal)
                                    
                                    ForEach(result.validationIssues, id: \.field) { issue in
                                        HStack {
                                            Image(systemName: issue.severity == .error ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                                                .foregroundColor(issue.severity == .error ? .red : .orange)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(issue.field)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                Text(issue.issue)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color.cardBackground)
                                        .cornerRadius(8)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Document Center")
            .sheet(isPresented: $showingScanner) {
                DocumentScannerWrapper { image in
                    scannedImage = image
                    processDocument(image)
                }
            }
        }
    }
    
    private func processDocument(_ image: UIImage) {
        isProcessing = true
        Task {
            let result = await scannerService.scanDocument(image)
            await MainActor.run {
                extractionResult = result
                isProcessing = false
            }
        }
    }
}

struct DataField: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct DocumentScannerWrapper: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: (UIImage) -> Void
        
        init(completion: @escaping (UIImage) -> Void) {
            self.completion = completion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                controller.dismiss(animated: true)
                return
            }
            
            let image = scan.imageOfPage(at: 0)
            completion(image)
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scanner error: \(error.localizedDescription)")
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    DocumentCenterView()
}
