//
//  PersonDetailView.swift
//  Wya
//
//  Created by Petter Staveland on 12/06/2025.
//
import SwiftUI

// MARK: - Person Detail View
struct PersonDetailView: View {
    let person: Person
    @State private var showingLocationHistory = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(person.color.color)
                            .frame(width: 100, height: 100)
                        
                        Text(person.emoji)
                            .font(.system(size: 60))
                    }
                    
                    VStack(spacing: 4) {
                        Text(person.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(person.relationship)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                // Status Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("Current Location")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("San Francisco, CA")
                            .font(.headline)
                        Text("Updated \(timeAgoString(from: person.lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Spacer()
                        
                        Label("Battery 87%", systemImage: "battery.75")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                
                // Quick Actions
                VStack(spacing: 12) {
                    Button(action: {}) {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Label("Call", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: {}) {
                            Label("Message", systemImage: "message.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                // Location History
                Button(action: { showingLocationHistory = true }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View Location History")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60)) minutes ago"
        } else {
            return "\(Int(interval / 3600)) hours ago"
        }
    }
}
