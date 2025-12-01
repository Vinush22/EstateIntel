//
//  TenantCommunicationService.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import NaturalLanguage

/// AI service for assisting with tenant communications
class TenantCommunicationService {
    
    struct MessageAnalysis {
        let sentiment: Sentiment
        let sentimentScore: Double // -1 to 1
        let urgency: UrgencyCategory
        let detectedTopics: [String]
        let suggestedReply: String
        let requiresAttention: Bool
    }
    
    enum Sentiment: String {
        case positive = "Positive"
        case neutral = "Neutral"
        case negative = "Negative"
        
        var emoji: String {
            switch self {
            case .positive: return "😊"
            case .neutral: return "😐"
            case .negative: return "😟"
            }
        }
    }
    
    enum UrgencyCategory: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
    
    /// Analyzes a tenant message and generates insights
    func analyzeMessage(_ message: String) -> MessageAnalysis {
        let sentiment = analyzeSentiment(message)
        let urgency = detectUrgency(message)
        let topics = detectTopics(message)
        let reply = generateReply(message: message, sentiment: sentiment.0, topics: topics)
        let needsAttention = sentiment.1 < -0.3 || urgency == .high
        
        return MessageAnalysis(
            sentiment: sentiment.0,
            sentimentScore: sentiment.1,
            urgency: urgency,
            detectedTopics: topics,
            suggestedReply: reply,
            requiresAttention: needsAttention
        )
    }
    
    /// Summarizes a conversation thread
    func summarizeConversation(_ messages: [String]) -> String {
        if messages.isEmpty {
            return "No messages to summarize"
        }
        
        // Extract key topics from all messages
        var allTopics: [String] = []
        var issueCount = 0
        var resolvedCount = 0
        
        for message in messages {
            let topics = detectTopics(message)
            allTopics.append(contentsOf: topics)
            
            if message.lowercased().contains("problem") || message.lowercased().contains("issue") {
                issueCount += 1
            }
            if message.lowercased().contains("resolved") || message.lowercased().contains("fixed") || message.lowercased().contains("resolved") {
                resolvedCount += 1
            }
        }
        
        let uniqueTopics = Array(Set(allTopics)).prefix(3)
        let topicStr = uniqueTopics.joined(separator: ", ")
        
        var summary = "**Conversation Summary:**\n\n"
        summary += "- **Messages:** \(messages.count)\n"
        summary += "- **Main Topics:** \(topicStr)\n"
        summary += "- **Issues Raised:** \(issueCount)\n"
        summary += "- **Issues Resolved:** \(resolvedCount)\n"
        
        // Determine conversation status
        if resolvedCount >= issueCount && issueCount > 0 {
            summary += "- **Status:** ✅ All issues appear resolved\n"
        } else if issueCount > resolvedCount {
            summary += "- **Status:** ⚠️ Some issues still open\n"
        } else {
            summary += "- **Status:** Ongoing communication\n"
        }
        
        return summary
    }
    
    private func analyzeSentiment(_ text: String) -> (Sentiment, Double) {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        var score: Double = 0.0
        if let sentimentValue = sentiment?.rawValue,
           let doubleValue = Double(sentimentValue) {
            score = doubleValue
        } else {
            // Fallback to keyword-based sentiment
            score = keywordBasedSentiment(text)
        }
        
        let category: Sentiment
        if score > 0.2 {
            category = .positive
        } else if score < -0.2 {
            category = .negative
        } else {
            category = .neutral
        }
        
        return (category, score)
    }
    
    private func keywordBasedSentiment(_ text: String) -> Double {
        let lowercased = text.lowercased()
        
        let positiveWords = ["thank", "great", "excellent", "appreciate", "wonderful", "happy", "satisfied", "love"]
        let negativeWords = ["problem", "issue", "broken", "frustrated", "angry", "disappointed", "terrible", "awful", "bad"]
        
        var positiveCount = 0
        var negativeCount = 0
        
        for word in positiveWords {
            if lowercased.contains(word) {
                positiveCount += 1
            }
        }
        
        for word in negativeWords {
            if lowercased.contains(word) {
                negativeCount += 1
            }
        }
        
        let totalWords = Double(positiveCount + negativeCount)
        if totalWords == 0 { return 0.0 }
        
        return (Double(positiveCount) - Double(negativeCount)) / totalWords
    }
    
    private func detectUrgency(_ text: String) -> UrgencyCategory {
        let lowercased = text.lowercased()
        
        let highUrgencyKeywords = ["urgent", "emergency", "immediately", "asap", "right away", "critical", "dangerous"]
        if highUrgencyKeywords.contains(where: { lowercased.contains($0) }) {
            return .high
        }
        
        let mediumUrgencyKeywords = ["soon", "quickly", "problem", "issue", "not working", "broken"]
        if mediumUrgencyKeywords.contains(where: { lowercased.contains($0) }) {
            return .medium
        }
        
        return .low
    }
    
    private func detectTopics(_ text: String) -> [String] {
        let lowercased = text.lowercased()
        var topics: [String] = []
        
        let topicKeywords: [String: [String]] = [
            "Maintenance": ["repair", "fix", "broken", "maintenance", "issue"],
            "Payment": ["rent", "payment", "deposit", "fee", "charge"],
            "Lease": ["lease", "contract", "agreement", "renewal"],
            "Noise": ["noise", "loud", "quiet", "neighbor"],
            "Utilities": ["water", "electric", "gas", "heat", "ac"],
            "Access": ["key", "lock", "access", "entry"],
            "Amenities": ["pool", "gym", "parking", "amenity"],
            "Move": ["move in", "move out", "moving"]
        ]
        
        for (topic, keywords) in topicKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                topics.append(topic)
            }
        }
        
        return topics.isEmpty ? ["General Inquiry"] : topics
    }
    
    private func generateReply(message: String, sentiment: Sentiment, topics: [String]) -> String {
        let primaryTopic = topics.first ?? "General Inquiry"
        
        // Start with appropriate greeting based on sentiment
        var reply = ""
        
        switch sentiment {
        case .positive:
            reply = "Thank you for reaching out! "
        case .neutral:
            reply = "Hello! Thank you for contacting us. "
        case .negative:
            reply = "We sincerely apologize for any inconvenience. "
        }
        
        // Add topic-specific response
        switch primaryTopic {
        case "Maintenance":
            reply += "We've received your maintenance request and understand the importance of addressing this promptly. Our team will review this and assign a technician to resolve the issue. You'll receive an update within 24 hours with a scheduled service time."
            
        case "Payment":
            reply += "Regarding your payment inquiry, we'd be happy to assist. Our office hours are Monday-Friday, 9 AM to 5 PM. You can also access your payment history and make payments through our tenant portal."
            
        case "Lease":
            reply += "Thank you for your lease inquiry. We'll review your request and respond with the necessary information within 1-2 business days. If you have any specific questions, feel free to include them and we'll address them comprehensively."
            
        case "Noise":
            reply += "We take noise complaints seriously and will follow up on this matter. We'll contact the relevant parties to address the situation. Please document any additional incidents with dates and times."
            
        case "Utilities":
            reply += "We'll look into the utility issue you've reported. In the meantime, if this is an emergency (such as no heat or water), please call our emergency line at (555) 999-0000."
            
        default:
            reply += "We've received your message and will respond to your inquiry within 24 hours. If this is urgent, please don't hesitate to call our office at (555) 123-4567."
        }
        
        reply += "\n\nBest regards,\nProperty Management Team"
        
        return reply
    }
}
