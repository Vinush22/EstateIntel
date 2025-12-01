//
//  NotificationManager.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    @Published var permissionGranted = false
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.permissionGranted = granted
            }
            
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Schedule a local notification for maintenance alerts
    func scheduleMaintenanceAlert(title: String, body: String, identifier: String, timeInterval: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MAINTENANCE_ALERT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule notification for high-risk tenant applications
    func scheduleRiskAlert(tenant: String, riskLevel: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ High Risk Application"
        content.body = "\(tenant) has been flagged as \(riskLevel) risk. Review immediately."
        content.sound = .defaultCritical
        content.categoryIdentifier = "RISK_ALERT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Cancel a specific notification
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Clear all pending notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
