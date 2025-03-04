//
//  AppDelegate.swift
//  PlutoSDKTestApp
//
//  Created by Andrew Jenkins on 12/17/24.
//

import UIKit
import PlutoSwiftSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Keep a reference to our log interceptor
    private var logInterceptor: LogInterceptor?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Create and start log interceptor
        setupLogInterceptor()

        return true
    }

    private func setupLogInterceptor() {
        // Create a log interceptor with a callback
        logInterceptor = LogInterceptor { logMessage in
            // Simply print the intercepted logs to the console
            // In a real app, you might want to save them or display them in the UI
            print("📱 Intercepted: \(logMessage)", terminator: "")
        }

        // Start redirecting logs
        logInterceptor?.redirectLogs()

        // Generate some test logs
        print("Log interceptor is now running!")
        print("This log message should be intercepted.")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Stop intercepting logs
        logInterceptor?.stopRedirecting()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

