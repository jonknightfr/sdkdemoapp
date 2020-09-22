//
//  ViewController.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 15/03/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit

import FRAuth
import FRUI
import FRAuthenticator

import SwiftyJSON
import SwiftKeychainWrapper

// GLOBALS
var tokens: AccessToken? = nil
var deviceInfo:[String:Any] = [:]
var urlSession: URLSession = URLSession.shared
let primaryColor:UIColor = #colorLiteral(red: 1, green: 0.609141767, blue: 0.1960352063, alpha: 1)
let secondaryColor:UIColor = #colorLiteral(red: 0.2252391875, green: 0.3142598569, blue: 0.8514382243, alpha: 1)
var tenantName:String = ""

class ViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginWebButton: UIButton!
    @IBOutlet weak var pushRegistrationButton: UIButton!
    @IBOutlet weak var tenantLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "FRAuthConfig", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
            if let hostname = nsDictionary?["forgerock_url"] {
                let hostURL = URL(string: hostname as! String)
                tenantLabel.text = hostURL?.host
                tenantName = hostURL?.host ?? ""
            }
        }
        
        
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [
                NSAttributedString.Key.font : UIFont(name: "FontAwesome5FreeSolid", size: 24)!,
                NSAttributedString.Key.foregroundColor : UIColor.darkGray,
            ], for: .normal)
        
        
        // QR button
        pushRegistrationButton.layer.cornerRadius = 20
        pushRegistrationButton.layer.borderColor = secondaryColor.cgColor
        pushRegistrationButton.layer.borderWidth = 2
        pushRegistrationButton.titleLabel!.font = UIFont(name:"FontAwesome5FreeSolid", size: 20)
        pushRegistrationButton.setTitle("\u{f029}", for: .normal)
        pushRegistrationButton.backgroundColor = primaryColor
    }

        
    @IBAction func login(_ sender: UIButton) {
                
        // Comment out the following 2 lines to use FR SDK
        //self.performSegue(withIdentifier: "showMainView", sender: nil)
        //return
        
        FRAClient.start()
        
        guard let _ = FRAClient.shared else {
            print("FRAuthenticator SDK is not initialized")
            return
        }
    
        //enables FR SDK
        do {
            try FRAuth.start()
            print("FRAuth SDK started using \(FRAuth.configPlistFileName).plist.")
            FRLog.setLogLevel(.all)
            FRUI.shared.primaryColor = primaryColor
            FRUI.shared.secondaryColor = secondaryColor
            FRUI.shared.logoImage = UIImage(named: "FRlogo.png")
        }
        catch {
            print(String(describing: error))
        }
        
        //collect device data
        FRDeviceCollector.shared.collect { (result) in
            deviceInfo = result
        }
        
        // logs off user if already logged in
        let user = FRUser.currentUser
        if ((user) != nil) {
            user!.logout()
        }
        
        // handles all OAuth
        if (sender.tag == 0) {
            FRUser.authenticateWithUI(self, completion: { (token: AccessToken?, error) in
                if (error == nil) {
                    self.loginCompleted(token: token!)
                } else {
                    print("Login error: \(error.debugDescription)")
                }
            })
        } else {
            FRUser.registerWithUI(self, completion: { (token: AccessToken?, error) in
                if (error == nil) {
                    self.loginCompleted(token: token!)
                } else {
                    print("Login error: \(error.debugDescription)")
                }
            })
        }
        
        
    }
    
    
    func loginCompleted(token: AccessToken) {
        print("Login Success")
        
        tokens = (FRUser.currentUser?.token)!
        
        FRUser.currentUser!.getUserInfo { (userInfo, error) in
            self.setupTokenManagementPolicy(uid: userInfo!.sub!)
        }
        
        //KeychainWrapper.standard.set(accessToken, forKey: "accessToken")
        //KeychainWrapper.standard.set(oidcToken, forKey: "oidcToken")
        
        let seconds = 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.performSegue(withIdentifier: "showMainView", sender: nil)
        }
        
    }
    

    
    func setupTokenManagementPolicy(uid:String) {
        
        URLProtocol.registerClass(FRURLProtocol.self)
        
        //let policy = TokenManagementPolicy(validatingURL: [URL(string: "http://openig.example.com:9999/products.php")!], delegate: self)
        let policy = TokenManagementPolicy(validatingURL: [URL(string:"https://\(tenantName)/openidm/managed/alpha_user/\(uid)")!])
        
        FRURLProtocol.tokenManagementPolicy = policy
        
        // Configure FRURLProtocol for HTTP client
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        urlSession = URLSession(configuration: config)
    }
    
}



