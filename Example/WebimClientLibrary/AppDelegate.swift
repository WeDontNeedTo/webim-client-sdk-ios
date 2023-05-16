//
//  AppDelegate.swift
//  WebimClientLibrary_Example
//
//  Created by Nikita Lazarev-Zubov on 01.00.2017.
//  Copyright © 2017 Webim. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Firebase
import UIKit
import WebimClientLibrary
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties
    var window: UIWindow?
    static var shared: AppDelegate!
    lazy var isApplicationConnected: Bool = false
    
    private var notificationUserInfo: [AnyHashable: Any]?
    
    // MARK: - Methods
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.shared = self
        WMKeychainWrapper.standard.setAppGroupName(userDefaults: UserDefaults(suiteName: "group.WebimClient.Share") ?? UserDefaults.standard, keychainAccessGroup: Bundle.main.infoDictionary!["keychainAppIdentifier"] as! String)
        UNUserNotificationCenter.current().delegate = self
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCustomValue(Settings.shared.accountName, forKey: "AccountName")
        // Remote notifications configuration
        let notificationTypes: UNAuthorizationOptions = [.alert,
                                                         .badge,
                                                         .sound]
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        UNUserNotificationCenter.current().requestAuthorization(options: notificationTypes) { (granted, error) in
            if granted {
                // application.registerUserNotificationSettings(remoteNotificationSettings)
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                    application.applicationIconBadgeNumber = 0
                }
            } else {
                print(error ?? "Error with remote notification")
            }
        }

        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        WMKeychainWrapper.standard.setString(deviceToken, forKey: WMKeychainWrapper.deviceTokenKey)
        
        print("Device token: \(deviceToken)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print(userInfo)
    }

    static func checkMainThread() {
        if !Thread.isMainThread {
#if DEBUG
            fatalError("Not main thread error")
#else
            print("Not main thread error")
#endif
        }
    }

    private func openChatFromNotification(_ notificationUserInfo: [AnyHashable: Any]) {
        // WEBIM: Remote notification handling.
        if Webim.isWebim(remoteNotification: notificationUserInfo) {
            _ = Webim.parse(remoteNotification: notificationUserInfo)
            // Handle Webim remote notification.
            
            guard !isChatIsTopViewController() else { return }

            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
                guard let startViewController = navigationController.viewControllers.first as? WMStartViewController else { return }
                startViewController.startChat()
            }
        } else {
            // Handle another type of remote notification.
        }
    }

    private func isChatIsTopViewController() -> Bool {
        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController else { return false }
        return navigationController.viewControllers.last?.isChatViewController == true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        notificationUserInfo = notification.request.content.userInfo

        guard !isChatIsTopViewController() else {
            completionHandler([])
            return
        }

        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        if let notificationUserInfo = notificationUserInfo {
            openChatFromNotification(notificationUserInfo)
        }
        
        completionHandler()
    }
}
