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

import SwiftyJSON
import SwiftKeychainWrapper
import LocalAuthentication


class ViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var loginWebButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var diagnosticData: UITextView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var accessToken: String = ""
    var oidcToken: String = ""
    var deviceInfo:[String:Any] = [:]
    var inputs:[String:UIView] = [:]
    var node:Node?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

        diagnosticData.layer.borderWidth = 1
        diagnosticData.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        nextButton.addTarget(self, action: #selector(continueAuth), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(start), for: .touchUpInside)

    }

    
    
    @objc func start() {
        self.loginButton.isHidden = false
        self.loginWebButton.isHidden = false
        self.logoutButton.isHidden = true
        self.scrollView.isHidden = true
        self.nextButton.isHidden = true
        self.cancelButton.isHidden = true
        self.view.subviews.forEach({
            if ($0.tag == -1) {
                $0.removeFromSuperview()
            }
        })
    }
    
    
    
    
    @IBAction func login(_ sender: Any) {
        print("Login start")
        
        do {
            try FRAuth.start()
            print("FRAuth SDK started using \(FRAuth.configPlistFileName).plist.")
            FRLog.setLogLevel(.all)
            FRUI.shared.primaryColor = #colorLiteral(red: 0.943256557, green: 0.4099977612, blue: 0, alpha: 1)
            FRUI.shared.secondaryColor = #colorLiteral(red: 0.01646898687, green: 0.1649038792, blue: 0.4707612991, alpha: 1)
            FRUI.shared.logoImage = UIImage(named: "FRlogo.png")
        }
        catch {
            print(String(describing: error))
        }
        
        FRDeviceCollector.shared.collect { (result) in
            self.deviceInfo = result
        }
        
        
        let user = FRUser.currentUser
        if ((user) != nil) {
            user!.logout()
        }
        
        FRUser.authenticateWithUI(self, completion: { (token: AccessToken?, error) in
            self.loginCompleted(token: token!)
        })
    }
    
    
    
    func loginCompleted(token: AccessToken) {
        print("Login Success")
        self.loginButton.isHidden = true
        self.loginWebButton.isHidden = true
        self.logoutButton.isHidden = false
        self.scrollView.isHidden = false
        self.nextButton.isHidden = true
        self.cancelButton.isHidden = true
        self.view.subviews.forEach({
            if ($0.tag == -1) {
                $0.removeFromSuperview()
            }
        })
        
        self.accessToken = (FRUser.currentUser?.token.debugDescription)!
        self.oidcToken = (FRUser.currentUser?.token!.idToken)!
        self.diagnosticData.text = self.accessToken
        KeychainWrapper.standard.set(self.accessToken, forKey: "accessToken")
        KeychainWrapper.standard.set(self.oidcToken, forKey: "oidcToken")
    }
    
    
    
    @IBAction func logout(_ sender: Any) {
        let user = FRUser.currentUser
        if ((user) != nil) {
            user!.logout()
        }
        accessToken = ""
        oidcToken = ""
        deviceInfo = [:]
        
        self.loginButton.isHidden = false
        self.loginWebButton.isHidden = false
        self.logoutButton.isHidden = true
        self.scrollView.isHidden = true
    }
    
    
    @IBAction func showOAuth(_ sender: Any) {
        if (accessToken == "") {
            localAuthenticate {
                self.accessToken = KeychainWrapper.standard.string(forKey: "accessToken")!
                self.oidcToken = KeychainWrapper.standard.string(forKey: "oidcToken")!
                self.diagnosticData.text = self.accessToken
            }
        } else {
            self.diagnosticData.text = accessToken
        }
    }
    
    
    @IBAction func showOIDC(_ sender: Any) {
        let claims = decode(jwtToken: self.oidcToken)
        var claimsStr = "{\n"
        claims.forEach { claimsStr += "\t\($0): \($1)\n" }
         self.diagnosticData.text = claimsStr + "}"
    }
    
    @IBAction func showDevice(_ sender: Any) {
        var deviceString = "{\n"
        deviceInfo.forEach { deviceString += "\t\($0): \($1)\n" }
        self.diagnosticData.text = deviceString + "}"
    }
    
    
    
    @IBAction func nonUILogin(_ sender: Any) {
        
        self.loginButton.isHidden = true
        self.loginWebButton.isHidden = true
        
        // Start SDK
        do {
            FRLog.setLogLevel(.all)
            
            try FRAuth.start()
            NSLog("FRAuth SDK started using \(FRAuth.configPlistFileName).plist.")
            FRUI.shared.primaryColor = #colorLiteral(red: 0.943256557, green: 0.4099977612, blue: 0, alpha: 1)
            FRUI.shared.secondaryColor = #colorLiteral(red: 0.01646898687, green: 0.1649038792, blue: 0.4707612991, alpha: 1)
        }
        catch {
            NSLog(String("FRAuth error: \(error)"))
        }
        
        
        FRDeviceCollector.shared.collect { (result) in
            self.deviceInfo = result

            if let user = FRUser.currentUser {
                user.logout()
            }
            
            FRUser.login { (user, node, error) in
                DispatchQueue.main.async(execute: {
                    self.handleNode(user: user, node: node, error: error)
                });
            }
        }
    }
    
    
    
    func handleNode(user: FRUser?, node: Node?, error: Error?) {
        if (user != nil) {
            loginCompleted(token: user!.token!)
        } else if (error != nil) {
            let alert = UIAlertController(title: "Login Error", message: "Sorry, login failed.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { action in self.start() }))
            self.present(alert, animated: true)
            print(error.debugDescription)
        } else {
            self.node = node
            
            // Clear screen
            var py:CGFloat = 200
            self.inputs.removeAll()
            self.view.subviews.forEach({
                if ($0.tag == -1) {
                    $0.removeFromSuperview()
                }
            })
            
            for callback in node!.callbacks {
                
                if callback is NameCallback, let nameCallback = callback as? NameCallback {
                    if (nameCallback.prompt! == "__NATIVE_DEVICE__") {
                        nameCallback.value = JSON(deviceInfo).rawString(.utf8, options: [])
                        continueAuth()
                    } else {
                        let textInput = self.addText(py:py, text:nameCallback.prompt!)
                        textInput.tag = -1
                        self.view.addSubview(textInput)
                        self.inputs[nameCallback.inputName!] = textInput
                        py += 60
                        
                    }
                }
                else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                    let textInput = self.addText(py:py, text:passwordCallback.prompt!)
                    textInput.isSecureTextEntry = true
                    self.view.addSubview(textInput)
                    self.inputs[passwordCallback.inputName!] = textInput
                    textInput.tag = -1
                    py += 60
                }
            }
            
            
            if (inputs.count > 0) {
                nextButton.isHidden = false
                cancelButton.isHidden = false
                DispatchQueue.main.async(execute: {
                    self.nextButton.frame.origin.y = py + 50
                    self.cancelButton.frame.origin.y = py + 50
                });
            }
        }
    }
    
    
    @objc func continueAuth() {
        nextButton.isHidden = true
        cancelButton.isHidden = true
        for callback in self.node!.callbacks {
            
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                if ((nameCallback.prompt != "__NATIVE_DEVICE__") && (nameCallback.prompt != "__NATIVE_AUTHENTICATE__")) {
                    nameCallback.value = (inputs[nameCallback.inputName!] as! UITextField).text!
                }
            } else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.value = (inputs[passwordCallback.inputName!] as! UITextField).text!
            }
        }
        self.node!.next{(user: FRUser?, node, error) in
            DispatchQueue.main.async(execute: {
                self.handleNode(user: user, node: node, error: error)
            });
        }
    }
    
    
    func addText(py:CGFloat, text:String) -> FRTextField {
        let textInput = FRTextField()
        textInput.normalColor = FRUI.shared.primaryColor
        textInput.frame.origin.y = py+10
        textInput.frame.size.width = view!.bounds.size.width - 80
        textInput.frame.size.height = 40
        textInput.textColor = FRUI.shared.secondaryColor
        textInput.attributedPlaceholder = NSAttributedString(string: text,
                                                             attributes: [NSAttributedString.Key.foregroundColor: FRUI.shared.secondaryColor])
        textInput.center.x = view!.bounds.width / 2
        return textInput
    }
    
    
    
    func updateTokens(data:Data) {
        let json = try! JSON(data: data)
        if (json["access_token"].exists()) {
            DispatchQueue.main.async(execute: {
                self.loginButton.isHidden = true
                self.loginWebButton.isHidden = true
                self.logoutButton.isHidden = false
                self.scrollView.isHidden = false
                
                self.accessToken = json.debugDescription
                self.oidcToken = json["id_token"].stringValue
                KeychainWrapper.standard.set(self.accessToken, forKey: "accessToken")
                KeychainWrapper.standard.set(self.oidcToken, forKey: "oidcToken")
                self.diagnosticData.text = self.accessToken
            })
        }
    }

    
    @objc func appMovedToBackground() {
        print("App moved to background.")
        diagnosticData.text = ""
        accessToken = ""
        oidcToken = ""
        deviceInfo = [:]
    }

    
    func localAuthenticate(completionHandler:@escaping ()->Void) {
        let authorization = LAContext()
        let authPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
    
        var authorizationError: NSError?
        if (authorization.canEvaluatePolicy(authPolicy, error: &authorizationError)) {
            // if device is touch id capable do something here
            authorization.evaluatePolicy(authPolicy, localizedReason: "Touch the fingerprint sensor to login", reply: {(success,error) in
                if (success) {
                    DispatchQueue.main.async(execute: {
                        completionHandler()
                    });
                } else {
                    print(error!.localizedDescription)
                }
            })
        } else {
            // add alert
            print("Not Touch ID Capable")

        }
    }
    
}



