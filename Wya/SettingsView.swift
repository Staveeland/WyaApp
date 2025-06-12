//
//  Untitled.swift
//  Wya
//
//  Created by Petter Staveland on 12/06/2025.
//
import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var locationSharing = true
    @State private var batteryOptimization = false
    @State private var darkMode = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("John Doe")
                                .font(.headline)
                            Text("john.doe@icloud.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: {}) {
                        Label("Manage Apple ID", systemImage: "chevron.right")
                            .foregroundColor(.primary)
                    }
                }
                
                Section("Privacy") {
                    Toggle("Location Sharing", isOn: $locationSharing)
                    Toggle("Notifications", isOn: $notificationsEnabled)
                    
                    Button(action: {}) {
                        Label("Location Permissions", systemImage: "location.fill")
                            .foregroundColor(.primary)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Dark Mode", isOn: $darkMode)
                    Toggle("Battery Optimization", isOn: $batteryOptimization)
                    
                    HStack {
                        Text("Update Frequency")
                        Spacer()
                        Text("5 minutes")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {}) {
                        Text("Terms of Service")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {}) {
                        Text("Privacy Policy")
                            .foregroundColor(.primary)
                    }
                }
                
                Section {
                    Button(action: {}) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
