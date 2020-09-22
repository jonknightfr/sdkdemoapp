//
//  AppDelegate.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 15/03/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import CoreLocation
import FRAuthenticator

var snsDeviceID:String = ""


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()

    
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings {
            settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FRALog.setLogLevel(.all)
        
        locationManager.requestWhenInUseAuthorization()

        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
        application.registerForRemoteNotifications()
        
        getNotificationSettings()
        
        return true
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        snsDeviceID = tokenParts.joined()
        print("Device SNS: \(snsDeviceID)")
        print("Device UDID: \(UIDevice.current.identifierForVendor!.uuidString)")

        
        FRAPushHandler.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Upon receiving an error from APNs, notify Authenticator module to properly update the status
        FRAPushHandler.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("INCOMING NOTIFICATION")
        
        // Once received remote notification, handle it with FRAPushHandler to get PushNotification object
        // If RemoteNotification does not contain expected payload structured returned from AM, Authenticator module does not return PushNotification object
        if let notification = FRAPushHandler.shared.application(application, didReceiveRemoteNotification: userInfo) {
            // With PushNotification object, you can either accept or deny
            notification.accept(onSuccess: {
                print("Accepted Push")
            }) { (error) in
                print("Denied Push")
            }
        }
    }
    
}


func base64UrlDecode(url: String) -> Data? {
    var base64 = url
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}


func decode(jwtToken jwt: String) -> [String: Any] {
    if (jwt != "") {
        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    } else {
        return [:]
    }
}


func decodeJWTPart(_ value: String) -> [String: Any]? {
    guard let bodyData = base64UrlDecode(url: value),
        let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
            return nil
    }
    
    return payload
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        print("INCOMING MESSAGE")
        completionHandler()
        
        /*
        if let aps = userInfo["aps"] as? [String: AnyObject] {
            
            let data = aps["data"] as! String
            let messageId = aps["messageId"] as! String
            
            if (response.actionIdentifier == "ACCEPT_ACTION") {
                FRPushUtils().responseToAuthNotification(deny: false, dataJWT: data, messageId: messageId, completionHandler: {
                    completionHandler()
                })
            } else if (response.actionIdentifier == "DECLINE_ACTION") {
                FRPushUtils().responseToAuthNotification(deny: true, dataJWT: data, messageId: messageId, completionHandler: {
                    completionHandler()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    let alert = TransactionAlert(title: "Alert", completionHandler:{
                        completionHandler()
                    })
                    alert.HandleNotification(aps: aps)
                    alert.show(animated: true)
                });
            }
            
        } else {
            completionHandler()
        }
        */
    }
}
