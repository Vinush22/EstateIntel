//
//  EstateIntelApp.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI

@main
struct EstateIntelApp: App {
    // Initialize the CoreData stack
    let persistenceController = PersistenceController.shared
    
    // State for push notification permissions
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .onAppear {
                    // Request notification permissions on app launch
                    notificationManager.requestPermission()
                }
        }
    }
}
