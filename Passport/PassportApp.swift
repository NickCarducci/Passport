//
//  PassportApp.swift
//  Passport
//
//  Created by Nicholas Carducci on 9/7/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

@main
struct PassportApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("application is starting up. ApplicationDelegate didFinishLaunchingWithOptions.")
        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Yay! Got a device token 🥳 \(deviceToken)")

        Auth.auth().setAPNSToken(deviceToken, type: .unknown)//.sandbox
        //Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
    }
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if Auth.auth().canHandleNotification(notification) {
            print("Can handle notifications")
            completionHandler(.noData)
            return
        }
    }
    /*func application(_ application: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

      if Auth.auth().canHandle(url) {
          print("Can handle url")
          return true
      }
      return false
    }*/
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(
          name: "Default Configuration",
          sessionRole: connectingSceneSession.role
        )
          /*let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
          sceneConfig.delegateClass = SceneDelegate.self
          return sceneConfig*/
      }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
      guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
      if let incomingURL = userActivity.webpageURL {
          let _ = incomingURL.absoluteString
      }
    }
    // Implementing this delegate method is needed when swizzling is disabled.
    // Without it, reCAPTCHA's login view controller will not dismiss.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for urlContext in URLContexts {
          let url = urlContext.url
          let _ = Auth.auth().canHandle(url)
        }
    // URL not auth related; it should be handled separately.
    }
}
