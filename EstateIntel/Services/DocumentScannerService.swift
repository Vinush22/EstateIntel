//
//  DocumentScannerService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import Vision
import UIKit

/// AI service for scanning and extracting data from lease documents
class DocumentScannerService {
    
    struct ExtractionResult {
        let success: Bool
        let extractedText: String
        let structuredData: LeaseData
        let confidence: Double
        let validationIssues: [ValidationIssue]
    }
    
    struct LeaseData: Codable {
        var tenantName: String?
        var landlordName: String?
        var propertyAddress: String?
        var leaseStartDate: Date?
        var leaseEndDate: Date?
        var monthlyRent: Double?
        var securityDeposit: Double?
        var leaseTerm: Int? // months
        var signatureDetected: Bool
        var additionalTerms: [String]
    }
    
    struct ValidationIssue {
        let field: String
        let issue: String
        let severity: Severity
        
        enum Severity: String {
            case warning = "Warning"
            case error = "Error"
        }
    }
    
    /// Performs OCR on document image and extracts structured lease data
    func scanDocument(_ image: UIImage) async -> ExtractionResult {
        // Perform OCR using Vision framework
        let ocrText = await performOCR(on: image)
        
        // Extract structured data from OCR text
        let leaseData = extractLeaseData(from: ocrText)
        
        // Validate extracted data
        let validationIssues = validateData(leaseData)
        
        // Calculate overall confidence
        let confidence = calculateConfidence(leaseData: leaseData, textLength: ocrText.count)
        
        return ExtractionResult(
            success: ocrText.count > 50, // Minimum text threshold
            extractedText: ocrText,
            structuredData: leaseData,
            confidence: confidence,
            validationIssues: validationIssues
        )
    }
    
    private func performOCR(on image: UIImage) async -> String {
        guard let cgImage = image.cgImage else {
            return ""
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        var recognizedText = ""
        
        do {
            try requestHandler.perform([request])
            
            if let observations = request.results {
                recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
            }
        } catch {
            print("OCR Error: \(error.localizedDescription)")
        }
        
        return recognizedText
    }
    
    private func extractLeaseData(from text: String) -> LeaseData {
        var leaseData = LeaseData(additionalTerms: [])
        
        // Extract tenant name - look for patterns like "Tenant: Name" or "Lessee: Name"
        if let tenantRange = text.range(of: #"(?:Tenant|Lessee|Renter):\s*([A-Za-z\s]+)"#, options: .regularExpression) {
            let match = String(text[tenantRange])
            leaseData.tenantName = match.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract landlord name
        if let landlordRange = text.range(of: #"(?:Landlord|Lessor|Owner):\s*([A-Za-z\s]+)"#, options: .regularExpression) {
            let match = String(text[landlordRange])
            leaseData.landlordName = match.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract property address
        if let addressRange = text.range(of: #"(?:Property|Address|Unit):\s*([0-9A-Za-z\s,]+)"#, options: .regularExpression) {
            let match = String(text[addressRange])
            leaseData.propertyAddress = match.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract rent amount - look for money patterns
        if let rentRange = text.range(of: #"\$\s*([0-9,]+(?:\.[0-9]{2})?)"#, options: .regularExpression) {
            let match = String(text[rentRange])
            let amountStr = match.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
            leaseData.monthlyRent = Double(amountStr)
        }
        
        // Extract dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dates = extractDates(from: text, formatter: dateFormatter)
        if dates.count >= 2 {
            leaseData.leaseStartDate = dates[0]
            leaseData.leaseEndDate = dates[1]
            
            // Calculate lease term in months
            if let start = dates[0], let end = dates[1] {
                let months = Calendar.current.dateComponents([.month], from: start, to: end).month
                leaseData.leaseTerm = months
            }
        }
        
        // Check for signature
        leaseData.signatureDetected = text.lowercased().contains("signature") || text.lowercased().contains("signed")
        
        // Extract security deposit
        if text.lowercased().contains("security deposit") {
            // Look for dollar amount near "security deposit"
            if let depositRange = text.range(of: #"security deposit[:\s]*\$\s*([0-9,]+(?:\.[0-9]{2})?)"#, options: [.regularExpression, .caseInsensitive]) {
                let match = String(text[depositRange])
                let amountStr = match.components(separatedBy: "$").last?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
                leaseData.securityDeposit = Double(amountStr ?? "0")
            }
        }
        
        return leaseData
    }
    
    private func extractDates(from text: String, formatter: DateFormatter) -> [Date] {
        var dates: [Date] = []
        
        // Common date patterns
        let datePatterns = [
            #"\d{2}/\d{2}/\d{4}"#,  // MM/DD/YYYY
            #"\d{1,2}-\d{1,2}-\d{4}"#,  // M-D-YYYY
            #"[A-Za-z]+\s+\d{1,2},\s+\d{4}"#  // Month DD, YYYY
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let dateStr = String(text[range])
                        if let date = formatter.date(from: dateStr) {
                            dates.append(date)
                        }
                    }
                }
            }
        }
        
        return dates.sorted()
    }
    
    private func validateData(_ data: LeaseData) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check for missing required fields
        if data.tenantName == nil || data.tenantName?.isEmpty == true {
            issues.append(ValidationIssue(field: "Tenant Name", issue: "Tenant name not found", severity: .error))
        }
        
        if data.monthlyRent == nil || data.monthlyRent == 0 {
            issues.append(ValidationIssue(field: "Monthly Rent", issue: "Rent amount not detected", severity: .error))
        }
        
        if data.leaseStartDate == nil {
            issues.append(ValidationIssue(field: "Start Date", issue: "Lease start date not found", severity: .error))
        }
        
        if data.leaseEndDate == nil {
            issues.append(ValidationIssue(field: "End Date", issue: "Lease end date not found", severity: .warning))
        }
        
        if !data.signatureDetected {
            issues.append(ValidationIssue(field: "Signature", issue: "No signature detected", severity: .warning))
        }
        
        // Check for data consistency
        if let start = data.leaseStartDate, let end = data.leaseEndDate, end <= start {
            issues.append(ValidationIssue(field: "Dates", issue: "End date must be after start date", severity: .error))
        }
        
        if let rent = data.monthlyRent, rent < 100 || rent > 50000 {
            issues.append(ValidationIssue(field: "Rent", issue: "Rent amount seems unusual", severity: .warning))
        }
        
        return issues
    }
    
    private func calculateConfidence(leaseData: LeaseData, textLength: Int) -> Double {
        var score = 0.0
        let maxScore = 7.0
        
        // Award points for extracted fields
        if leaseData.tenantName != nil { score += 1.0 }
        if leaseData.monthlyRent != nil { score += 1.0 }
        if leaseData.leaseStartDate != nil { score += 1.0 }
        if leaseData.leaseEndDate != nil { score += 1.0 }
        if leaseData.propertyAddress != nil { score += 1.0 }
        if leaseData.signatureDetected { score += 1.0 }
        if textLength > 200 { score += 1.0 } // Sufficient text extracted
        
        return score / maxScore
    }
}
