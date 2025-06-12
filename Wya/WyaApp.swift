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
                    .onOpenURL { url in
                        CloudKitLocationManager.shared.acceptShare(from: url) { _ in }
                    }
            } else {
                SignInView()
                    .environmentObject(session)
            }
        }
    }
}
