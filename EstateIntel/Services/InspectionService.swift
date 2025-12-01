//
//  InspectionService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import Vision
import UIKit
import PDFKit

/// AI service for processing move-in/move-out inspections with computer vision
class InspectionService {
    
    struct InspectionResult {
        let inspectionId: UUID
        let detectedDamages: [DamageDetection]
        let overallCondition: ConditionRating
        let estimatedRepairCost: Double
        let comparisonReport: ComparisonReport?
    }
    
    struct DamageDetection {
        let room: String
        let damageType: DamageType
        let severity: Severity
        let location: String
        let confidence: Double
        let imageReference: String?
        
        enum DamageType: String, CaseIterable {
            case wallDamage = "Wall Damage"
            case floorDamage = "Floor Damage"
            case ceilingDamage = "Ceiling Damage"
            case stain = "Stain"
            case crack = "Crack"
            case missingFixture = "Missing Fixture"
            case brokenAppliance = "Broken Appliance"
            case other = "Other"
        }
        
        enum Severity: String {
            case minor = "Minor"
            case moderate = "Moderate"
            case major = "Major"
            
            var repairCost: Double {
                switch self {
                case .minor: return 50
                case .moderate: return 150
                case .major: return 500
                }
            }
        }
    }
    
    enum ConditionRating: String {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var score: Int {
            switch self {
            case .excellent: return 4
            case .good: return 3
            case .fair: return 2
            case .poor: return 1
            }
        }
    }
    
    struct ComparisonReport {
        let changesFound: Int
        let newDamages: [DamageDetection]
        let restoredItems: [String]
        let damageResponsibility: String // Tenant/Normal Wear
    }
    
    /// Analyzes inspection images using computer vision for damage detection
    func analyzeInspection(images: [UIImage], roomLabels: [String]) async -> InspectionResult {
        var allDamages: [DamageDetection] = []
        
        for (index, image) in images.enumerated() {
            let room = index < roomLabels.count ? roomLabels[index] : "Room \(index + 1)"
            let damages = await detectDamageInImage(image, room: room)
            allDamages.append(contentsOf: damages)
        }
        
        // Calculate overall condition
        let condition = calculateCondition(damages: allDamages)
        
        // Estimate repair costs
        let totalCost = allDamages.reduce(0) { $0 + $1.severity.repairCost }
        
        return InspectionResult(
            inspectionId: UUID(),
            detectedDamages: allDamages,
            overallCondition: condition,
            estimatedRepairCost: totalCost,
            comparisonReport: nil
        )
    }
    
    /// Compares move-in and move-out inspections to identify new damages
    func compareInspections(moveIn: InspectionResult, moveOut: InspectionResult) -> ComparisonReport {
        // Find damages that appear in move-out but not move-in
        let newDamages = moveOut.detectedDamages.filter { outDamage in
            !moveIn.detectedDamages.contains { inDamage in
                inDamage.room == outDamage.room && inDamage.damageType == outDamage.damageType
            }
        }
        
        // Find damages that were in move-in but fixed by move-out
        let restoredItems = moveIn.detectedDamages.filter { inDamage in
            !moveOut.detectedDamages.contains { outDamage in
                outDamage.room == inDamage.room && outDamage.damageType == inDamage.damageType
            }
        }.map { "\($0.damageType.rawValue) in \($0.room)" }
        
        // Determine responsibility
        let responsibility: String
        if newDamages.isEmpty {
            responsibility = "No new damages - security deposit should be returned in full"
        } else if newDamages.allSatisfy({ $0.severity == .minor }) {
            responsibility = "Minor wear and tear - typically normal rental use"
        } else {
            responsibility = "Tenant responsibility - damages exceed normal wear and tear"
        }
        
        return ComparisonReport(
            changesFound: newDamages.count + restoredItems.count,
            newDamages: newDamages,
            restoredItems: restoredItems,
            damageResponsibility: responsibility
        )
    }
    
    /// Generates a PDF report of the inspection
    func generatePDFReport(inspection: InspectionResult, images: [UIImage], unitNumber: String) -> PDFDocument {
        let pdfMetaData = [
            kCGPDFContextCreator: "EstateIntel",
            kCGPDFContextTitle: "Inspection Report - Unit \(unitNumber)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Title
            let title = "Inspection Report - Unit \(unitNumber)"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateStr = "Date: \(dateFormatter.string(from: Date()))"
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            dateStr.draw(at: CGPoint(x: 50, y: 90), withAttributes: textAttributes)
            
            // Overall condition
            let conditionStr = "Overall Condition: \(inspection.overallCondition.rawValue)"
            conditionStr.draw(at: CGPoint(x: 50, y: 110), withAttributes: textAttributes)
            
            // Damages found
            var yPosition: CGFloat = 150
            let damageTitle = "Damages Detected (\(inspection.detectedDamages.count)):"
            let boldAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14)]
            damageTitle.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttrs)
            yPosition += 30
            
            for (index, damage) in inspection.detectedDamages.prefix(10).enumerated() {
                let damageStr = "\(index + 1). \(damage.room): \(damage.damageType.rawValue) - \(damage.severity.rawValue)"
                damageStr.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: textAttributes)
                yPosition += 20
            }
            
            // Total cost
            yPosition += 20
            let costStr = "Estimated Repair Cost: $\(String(format: "%.2f", inspection.estimatedRepairCost))"
            let costAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14)]
            costStr.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: costAttrs)
        }
        
        return PDFDocument(data: data) ?? PDFDocument()
    }
    
    private func detectDamageInImage(_ image: UIImage, room: String) async -> [DamageDetection] {
        // In production, this would use a trained CoreML model for damage detection
        // For now, simulate damage detection
        
        // Simulated damage detection results
        let shouldDetectDamage = Bool.random()
        
        guard shouldDetectDamage else {
            return []
        }
        
        let damageTypes = DamageDetection.DamageType.allCases
        let randomDamage = damageTypes.randomElement() ?? .other
        
        return [
            DamageDetection(
                room: room,
                damageType: randomDamage,
                severity: Bool.random() ? .minor : .moderate,
                location: "Detected in image analysis",
                confidence: Double.random(in: 0.65...0.95),
                imageReference: "image_\(UUID().uuidString).jpg"
            )
        ]
    }
    
    private func calculateCondition(damages: [DamageDetection]) -> ConditionRating {
        if damages.isEmpty {
            return .excellent
        }
        
        let severeCases = damages.filter { $0.severity == .major }.count
        let moderateDamages = damages.filter { $0.severity == .moderate }.count
        
        if severeCases > 2 || damages.count > 10 {
            return .poor
        } else if severeCases > 0 || moderateDamages > 3 {
            return .fair
        } else if damages.count > 5 {
            return .fair
        } else if damages.count > 0 {
            return .good
        } else {
            return .excellent
        }
    }
}
