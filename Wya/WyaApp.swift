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
            ContentView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    CloudKitLocationManager.shared.acceptShare(from: url) { _ in }
                }
        }
    }
}
