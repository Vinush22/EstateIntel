//
//  MainTabView.swift
//  EstateIntel
//
//  Created on 12/1/24.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Dashboard/Overview
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            // Predictive Maintenance
            PredictiveMaintenanceView()
                .tabItem {
                    Label("Maintenance", systemImage: "wrench.and.screwdriver.fill")
                }
            
            // Tenant Screening & Communication
            TenantManagementView()
                .tabItem {
                    Label("Tenants", systemImage: "person.3.fill")
                }
            
            // Documents & Scanning
            DocumentCenterView()
                .tabItem {
                    Label("Documents", systemImage: "doc.text.fill")
                }
            
            // Analytics & Insights
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
