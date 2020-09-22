//
//  MainView.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 21/09/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import FRAuth
import SwiftyJSON
import MapKit
import CoreLocation
import NotificationBannerSwift
import EasyNotificationBadge

class MainView: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var profileTabButton: UIBarButtonItem!
    @IBOutlet weak var diagTabButton: UIBarButtonItem!
    @IBOutlet weak var quitTabButton: UIBarButtonItem!
    
    @IBAction func close(_ sender: Any) {
        let user = FRUser.currentUser
        if ((user) != nil) {
            user!.logout()
        }
        tokens = nil
        deviceInfo = [:]
        
        self.dismiss(animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileTabButton.title = "\u{f007}"
        diagTabButton.title = "\u{f05a}"
        quitTabButton.title = "\u{f2f5}"

        if (FRUser.currentUser != nil) {
            FRUser.currentUser!.getUserInfo { (userInfo, error) in
                
                let handleUserData: (Data?) -> Void = { [self] data in
                    print("Got user info")
                    userData = try! JSON(data: data!)
                    
                    let banner = FloatingNotificationBanner(title:"Hi \(userData["givenName"])", subtitle:"You have 2 new messages waiting for you.", style:.success)
                    banner.show(cornerRadius: 10, shadowBlurRadius: 15)
                    
                    
                    var badgeAppearance = BadgeAppearance()
                    badgeAppearance.allowShadow = true
                    profileTabButton.badge(text: "2", appearance: badgeAppearance)
                    
                    
                    self.titleLabel.text = "Welcome Back \(userData["givenName"])!"
                    
                    if (deviceInfo["location"] != nil) {
                        
                        let coords = deviceInfo["location"] as! [String : Double]
                        let lat = (coords["latitude"] ?? 0) as Double
                        let lon = (coords["longitude"] ?? 0) as Double
                        
                        let loc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        let accuracy = 2000
                        let region = MKCoordinateRegion.init(center: loc, latitudinalMeters: CLLocationDistance(accuracy), longitudinalMeters: CLLocationDistance(accuracy))
                        self.mapView!.setRegion(region, animated: true)
                        
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = loc
                        annotation.title = "\(userData["givenName"])"
                        self.mapView!.addAnnotation(annotation)
                    }
                }
                
                var nsDictionary: NSDictionary?
                if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
                    nsDictionary = NSDictionary(contentsOfFile: path)
                }
                
                let requestUrl = "https://\(tenantName)/openidm/managed/alpha_user/\(userInfo!.sub!)"
                restCall(requestUrl: requestUrl, completionHandler: handleUserData, failureHandler: {
                    print("Failed to get user info")
                })
            }
        }
    }
    
}
