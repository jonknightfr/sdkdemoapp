//
//  SceneDelegate.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 15/03/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            // Handle URL
            let baseUrl = url.absoluteString.components(separatedBy: "?")[0]
            
            if baseUrl.lowercased() == "forgebank://oidc_callback" {
                
                // Close the SFSafariViewController
                window!.rootViewController?.presentedViewController?.dismiss(animated: true , completion: nil)
                
                var returnDictionary = [String: String]()
                let queryParams = url.absoluteString.components(separatedBy: "?")[1]
                for queryParam in (queryParams.components(separatedBy: "&")) {
                    //print("Parsing query parameter: \(queryParam)")
                    var queryElement = queryParam.components(separatedBy: "=")
                    returnDictionary[queryElement[0]] = queryElement[1]
                }
                if (returnDictionary["code"] != nil) {
                    getAccessToken(returnDictionary["code"]!, completionHandler: { data in
                        let view = self.window!.rootViewController as! ViewController
                        view.updateTokens(data:data)
                    })
                }
            }
        }
    }
    
    
    func getAccessToken(_ code:String, completionHandler:@escaping (_ data:Data)->Void) {
        let defaults = UserDefaults.standard
        let authnUrl = "https://jonk.emea-poc.frk8s.net/am/oauth2/access_token"
        
        let tokenRequest = NSMutableURLRequest(url: URL(string: authnUrl)!)
        tokenRequest.httpMethod = "POST"
        
        tokenRequest.httpBody = ("grant_type=authorization_code&redirect_uri=forgebank://oidc_callback&code=\(code)").data(using: String.Encoding.utf8)
        
        tokenRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        
        let PasswordString = "mobileapp:Frdp-2010"
        let PasswordData = PasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = PasswordData!.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
        
        tokenRequest.addValue("Basic \(base64EncodedCredential)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: tokenRequest as URLRequest, completionHandler: {
            data, response, error in
            
            // A client-side error occured
            if error != nil {
                print("Failed to send authentication request: \(String(describing: error?.localizedDescription))!")
            }
            
            let responseCode = (response as! HTTPURLResponse).statusCode
            let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            
            if (responseCode == 200) {
                let dataFromString = responseData!.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
                completionHandler(dataFromString!)

            }
        }).resume()
    }
    
    
    
    
}

