//
//  DiagnosticView.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 20/09/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FRUI


class DiagnosticView: UIViewController {

    @IBOutlet weak var diagnosticView: UITextView!
    @IBOutlet weak var oauthButton: FRButton!
    @IBOutlet weak var oidcButton: FRButton!
    @IBOutlet weak var doneButton: FRButton!
    @IBOutlet weak var deviceButton: FRButton!
    
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        diagnosticView.layer.borderWidth = 1
        diagnosticView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        oauthButton.backgroundColor = secondaryColor
        oidcButton.backgroundColor = secondaryColor
        deviceButton.backgroundColor = secondaryColor
        doneButton.backgroundColor = primaryColor
        
        oauthButton(self)
    }
    
    
    @IBAction func oauthButton(_ sender: Any) {
        let keyAttr = [NSAttributedString.Key.foregroundColor: secondaryColor, .font:UIFont.boldSystemFont(ofSize: 14)] as [NSAttributedString.Key : Any]
        let valueAttributes = [NSAttributedString.Key.foregroundColor: primaryColor, .font:UIFont.systemFont(ofSize: 14)]

        var claimStr = NSMutableAttributedString(string: "token_type: ", attributes: keyAttr)
        claimStr.append(NSMutableAttributedString(string: "\(tokens?.tokenType ?? "")\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "scope: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(tokens?.scope ?? "")\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "expires: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(tokens?.expiration)\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "access_token: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(tokens?.value ?? "")\n", attributes: valueAttributes))
 
        claimStr.append(NSMutableAttributedString(string: "refresh_token: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(tokens?.refreshToken ?? "")\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "id_token: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(tokens?.idToken ?? "")\n", attributes: valueAttributes))

        diagnosticView.attributedText = claimStr

    }
    
    
    @IBAction func oidcButton(_ sender: Any) {
        let keyAttr = [NSAttributedString.Key.foregroundColor: secondaryColor, .font:UIFont.boldSystemFont(ofSize: 14)] as [NSAttributedString.Key : Any]
        let valueAttributes = [NSAttributedString.Key.foregroundColor: primaryColor, .font:UIFont.systemFont(ofSize: 14)]

        let claims = decode(jwtToken: tokens?.idToken ?? "")
        var claimStr = NSMutableAttributedString(string: "{\n")
        
        claims.forEach {
            claimStr.append(NSMutableAttributedString(string: "\t\($0): ", attributes: keyAttr))
            claimStr.append(NSMutableAttributedString(string: "\($1)\n", attributes: valueAttributes))
        }
        claimStr.append(NSMutableAttributedString(string: "}"))
        diagnosticView.attributedText = claimStr
    }
    
    
    @IBAction func deviceButton(_ sender: Any) {
        let keyAttr = [NSAttributedString.Key.foregroundColor: secondaryColor, .font:UIFont.boldSystemFont(ofSize: 14)] as [NSAttributedString.Key : Any]
        let valueAttributes = [NSAttributedString.Key.foregroundColor: primaryColor, .font:UIFont.systemFont(ofSize: 14)]

        var claimStr = NSMutableAttributedString(string: "{\n")
        
        deviceInfo.forEach {
            claimStr.append(NSMutableAttributedString(string: "\t\($0): ", attributes: keyAttr))
            claimStr.append(NSMutableAttributedString(string: "\($1)\n", attributes: valueAttributes))
        }
        claimStr.append(NSMutableAttributedString(string: "}"))
        
        diagnosticView.attributedText = claimStr
    }
    
    
    @IBAction func doneButton(_ sender: Any) {
    }

}
