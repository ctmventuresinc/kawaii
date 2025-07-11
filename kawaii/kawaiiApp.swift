//
//  kawaiiApp.swift
//  kawaii
//
//  Created by Los Mayers on 6/18/25.
//

import SwiftUI
import OneSignalFramework

@main
struct kawaiiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
       // Enable verbose logging for debugging (remove in production)
       OneSignal.Debug.setLogLevel(.LL_VERBOSE)     
       // Initialize with your OneSignal App ID
       OneSignal.initialize("dcbcd501-d44c-46ad-84ca-e7aca9c02a0c", withLaunchOptions: launchOptions)
       // Push notification permission will be requested after photo access is granted
      
       return true
    }
}
