//
//  AlertsView.swift
//  Wya
//
//  Created by Petter Staveland on 12/06/2025.
//
import SwiftUI
// MARK: - Alerts View
struct AlertsView: View {
    @EnvironmentObject var viewModel: WyaViewModel
    @State private var showingAddAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.locationAlerts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Location Alerts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Set up alerts to get notified when your people arrive or leave specific locations")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                        
                        Button(action: { showingAddAlert = true }) {
                            Label("Create Alert", systemImage: "plus.circle.fill")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.locationAlerts) { alert in
                            AlertRow(alert: alert)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Location Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAlert = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// MARK: - Alert Row
struct AlertRow: View {
    let alert: LocationAlert
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: alert.alertType == .arrival ? "arrow.down.circle.fill" :
                    alert.alertType == .departure ? "arrow.up.circle.fill" : "arrow.up.arrow.down.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.name)
                    .font(.headline)
                
                Text("\(alert.alertType.rawValue) Alert")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(alert.members.count) person(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(true))
                .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
