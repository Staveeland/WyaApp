//
//  WyaApp.swift
//  Wya
//
//  Created by Petter Staveland on 12/06/2025.
//

import SwiftUI
import UIKit


// MARK: - Main App
@main
struct WyaApp: App {
    @StateObject private var session = UserSession()
    @State private var inviteAlertMessage = ""
    @State private var showInviteAlert = false
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }

    var body: some Scene {
        WindowGroup {
            if session.isSignedIn {
                ContentView(session: session)
                    .environmentObject(session)
                    .preferredColorScheme(.dark)
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                        if let url = activity.webpageURL {
                            CloudKitLocationManager.shared.acceptShare(from: url) { success in
                                if success {
                                    inviteAlertMessage = "Invite accepted and connected!"
                                    print("🎉 Invite accepted and connected!")
                                } else {
                                    inviteAlertMessage = "Failed to accept invite."
                                    print("⚠️ Failed to accept invite.")
                                }
                                showInviteAlert = true
                            }
                        }
                    }
                    .alert(inviteAlertMessage, isPresented: $showInviteAlert) {
                        Button("OK", role: .cancel) {}
                    }
            } else {
                SignInView()
                    .environmentObject(session)
            }
        }
    }
}
