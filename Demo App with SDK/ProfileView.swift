//
//  ProfileView.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 20/09/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import FRAuth
import SwiftyJSON

var userData: JSON = JSON("")
var appData: JSON = JSON("")
var cookieName: String = ""


class ProfileView: UIViewController {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var mScrollView: UIScrollView!
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated:true)
    }
    
    
    func addLabel(x:Int, y:Int, textColor: UIColor, backgroundColor:UIColor = .clear, size:Int, text:String, font:String = "Helvetica-Light") -> UILabel{
        let label = UILabel()
        label.frame.origin.y = CGFloat(y)
        label.frame.origin.x = CGFloat(x)
        label.textAlignment = .left
        label.textColor = textColor
        label.backgroundColor = backgroundColor
        label.font = UIFont(name:font, size: CGFloat(size))
        label.text = text
        label.sizeToFit()
        return label
    }
    
    
    func addCard(y:Int, icon:String, iconFont:String = "FontAwesome5FreeSolid", title:String, subtitle:String, caret:Bool = true) -> UIView {
        let cardView = UIView()
        cardView.frame = CGRect(x: 0, y: y, width: Int(self.view.frame.width), height: 80)
        cardView.backgroundColor = .white
        let icon = addLabel(x: 35, y: 15, textColor: primaryColor
                            , size: 20, text: icon, font:"FontAwesome5FreeSolid")
        icon.center.x = 45
        cardView.addSubview(icon)
        let titleLabel = addLabel(x: 65, y: 15, textColor: .black, size: 18, text: title)
        titleLabel.frame.size.width = self.view.frame.width - 100
        cardView.addSubview(titleLabel)
        let subTitleLabel = addLabel(x: 25, y: 45, textColor: .darkGray, size: 14, text: subtitle)
        subTitleLabel.numberOfLines = 0
        subTitleLabel.lineBreakMode = .byWordWrapping
        subTitleLabel.frame.size.width = self.view.frame.width - 70
        subTitleLabel.sizeToFit()
        cardView.frame.size.height = (subTitleLabel.frame.height + 60)
        cardView.addSubview(subTitleLabel)
        if (caret) {
            let caretLabel = addLabel(x: Int(self.view.frame.width - 30), y: 35, textColor: .lightGray, size: 14, text: "\u{f054}", font:"FontAwesome5FreeSolid")
            cardView.addSubview(caretLabel)
        }
        return cardView
    }
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (FRUser.currentUser != nil) {
            FRUser.currentUser!.getUserInfo { (userInfo, error) in
                
                let handleAuthorisedApps: (Data?) -> Void = { data  in
                    print("Got authorised app data: \(data?.debugDescription)")
                    appData = try! JSON(data: data!)
                    self.updateDisplay()
                }
                
                
                let handleUserData: (Data?) -> Void = { data in
                    print("Got user info")
                    userData = try! JSON(data: data!)
                    
                    let requestUrl = "https://\(tenantName)/am/json/realms/root/realms/alpha/users/\(userInfo!.sub!)/oauth2/applications?_queryFilter=true"
                    let cookie = "\(cookieName)=\(FRSession.currentSession?.sessionToken?.value ?? "")"
                    restCall(requestUrl: requestUrl, cookie:cookie, completionHandler: handleAuthorisedApps, failureHandler: {
                        print("Failed to get authorised apps")
                        self.updateDisplay()
                    })
                }
                
                let handleAMServerInfo: (Data?) -> Void = { data in
                    var json = try! JSON(data: data!)
                    cookieName = json["cookieName"].stringValue
                    print("Got AM serverinfo info: \(cookieName)")
                    
                    let requestUrl = "https://\(tenantName)/openidm/managed/alpha_user/\(userInfo!.sub!)"
                    restCall(requestUrl: requestUrl, completionHandler: handleUserData, failureHandler: {
                        print("Failed to get user info")
                        self.updateDisplay()
                    })
                }

                let requestUrl = "https://\(tenantName)/am/json/serverinfo/*"
                restCall(requestUrl: requestUrl, completionHandler: handleAMServerInfo, failureHandler: {
                    print("Failed to get AM server info")
                })
            }
        } else {
            self.updateDisplay()
        }
    }
        
        
        
        
    func updateDisplay() {
        if (userData["givenName"].stringValue != "") {
            fullName.text = "\(userData["givenName"]) \(userData["sn"])"
        } else {
            fullName.text = "Unknown User"
        }
        
        profilePicture.layer.borderColor = primaryColor.cgColor
        profilePicture.layer.borderWidth = 2
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.cornerRadius = 40
        profilePicture.image = UIImage(named: "face")

        _ = mScrollView.subviews.map { $0.removeFromSuperview() }

        var py = 1
        
        // eMail Address
        var emailAddr = "What's your email address?"
        if (userData["mail"].stringValue != "") { emailAddr = userData["mail"].stringValue }
        var card = addCard(y:py, icon:"\u{f0e0}", title: emailAddr, subtitle:"Your email address has been updated and verified.")
        card.tag = 0
        mScrollView.addSubview(card)
        py = Int(card.frame.maxY) + 20


        // Phone Number
        var phoneNumber = "What's your mobile number?"
        if (userData["telephoneNumber"].stringValue != "") { phoneNumber = userData["telephoneNumber"].stringValue }
        card = addCard(y:py, icon:"\u{f3cd}", title:phoneNumber, subtitle:"Please keep us updated with your mobile phone number. We can use this to contact you, and sometimes also as a strong authentication factor.")
        card.tag = 1
        mScrollView.addSubview(card)
        py = Int(card.frame.maxY) + 20
        
        
        
        // Postal Address
        var address = "What's your address?"
        if (userData["postalAddress"].stringValue != "") { address = userData["postalAddress"].stringValue }
        card = addCard(y:py, icon:"\u{f3c5}", title:address, subtitle:"Please let us know of any changes in personal circumstances including your home address.")
        card.tag = 2
        mScrollView.addSubview(card)
        py = Int(card.frame.maxY) + 20
        
        
        
        // Marketing Consent
        card = addCard(y:py, icon:"\u{f086}", title:"Preferences", subtitle:"Please let us know your preferences so we can contact your about new offers, products, and updates.")
        card.tag = 3
        
        card.frame.size.height = card.frame.size.height + 80
        var toggle = UISwitch()
        toggle.center.y = card.frame.size.height - 60
        toggle.center.x = 55
        toggle.isOn = userData["preferences"]["updates"].boolValue
        toggle.onTintColor = primaryColor
        card.addSubview(toggle)
        var prefLabel = addLabel(x: Int(toggle.frame.maxX) + 10, y: 0, textColor: .darkGray, size: 14, text: "Send me news and updates")
        prefLabel.center.y = toggle.center.y
        card.addSubview(prefLabel)

        card.frame.size.height = card.frame.size.height + 40
        toggle = UISwitch()
        toggle.center.y = card.frame.size.height - 60
        toggle.center.x = 55
        toggle.isOn = userData["preferences"]["marketing"].boolValue
        toggle.onTintColor = primaryColor
        card.addSubview(toggle)
        prefLabel = addLabel(x: Int(toggle.frame.maxX) + 10, y: 0, textColor: .darkGray, size: 14, text: "Send me special offers and services")
        prefLabel.center.y = toggle.center.y
        card.addSubview(prefLabel)
        
        mScrollView.addSubview(card)
        py = Int(card.frame.maxY) + 20
 
        // Authorised Apps
        card = addCard(y:py, icon:"\u{f6e2}", title:"Authorised Apps", subtitle:"Applications you have given access to your personal information.")
        card.tag = 4
        
        for app in appData["result"].arrayValue {
            print("APP: \(app["name"])")
            card.frame.size.height = card.frame.size.height + 30

            let icon = addLabel(x: 45, y: Int(card.frame.size.height) - 30, textColor: primaryColor
                                , size: 20, text: "\u{f3cd}", font:"FontAwesome5FreeSolid")
            card.addSubview(icon)
            let appName = app["name"].stringValue != "" ? app["name"].stringValue : app["_id"].stringValue
            prefLabel = addLabel(x: 65, y: Int(card.frame.size.height) - 30, textColor: .darkGray, size: 16, text: appName)
            card.addSubview(prefLabel)
        }
        
        mScrollView.addSubview(card)
        py = Int(card.frame.maxY) + 20
        
        
        // Password Reset
        card = addCard(y:py, icon:"\u{f084}", title:"Password Set", subtitle:"Click here if you wish to update your password. Remember to keep you credentials safe and contact us if you'd like to learn more about avoiding fraud.")
        card.tag = 5
        mScrollView.addSubview(card)
        py = Int(card.frame.maxY) + 20
        
        mScrollView.contentSize = CGSize(width: CGFloat(view!.bounds.size.width), height: CGFloat(py))

    }
}


func restCall(requestUrl:String, cookie:String = "", completionHandler: @escaping (_ data:Data?)->Void, failureHandler: @escaping ()->Void) {
    let tokenRequest = NSMutableURLRequest(url: URL(string: requestUrl)!)
    tokenRequest.httpMethod = "GET"
    
    if (cookie != "") {
        tokenRequest.addValue(cookie, forHTTPHeaderField: "Cookie")
    }
    
    urlSession.dataTask(with: tokenRequest as URLRequest, completionHandler: {
        data, response, error in
        
        // A client-side error occured
        if error != nil {
            print("Failed to send request: \(String(describing: error?.localizedDescription))!")
        }
        
        let responseCode = (response as! HTTPURLResponse).statusCode
        let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        print("RESPONSE CODE: \(responseCode)")
        print("RESPONSE DATA: \(responseData)")
        
        if (responseCode == 200) {
            let dataFromString = responseData!.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
            
            DispatchQueue.main.async(execute: {
                completionHandler(dataFromString)
            })
        } else {
            DispatchQueue.main.async(execute: {
                failureHandler()
            })
        }
    }).resume()
}
