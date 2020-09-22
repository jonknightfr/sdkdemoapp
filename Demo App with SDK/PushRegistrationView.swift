//
//  PushRegistrationViewController.swift
//  ForgeBank
//
//  Created by Jon Knight on 29/04/2019.
//  Copyright © 2019 Identity Hipsters. All rights reserved.
//

import UIKit
import AVFoundation
import FRAuthenticator


@available(iOS 10.2, *)
class PushRegistrationView: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var statusLabel: UILabel?
    var qrCodeFrameView:UIView?
    
    override func viewDidLoad() {
        print("PushRegistrationView: viewDidLoad")
        super.viewDidLoad()
    
        FRAClient.start()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        let rect = UIView()
        rect.frame = CGRect(x: 0, y: Int(view.frame.height)-170, width: Int(view.frame.width), height: 170)
        rect.backgroundColor = #colorLiteral(red: 0.006400917657, green: 0.5541562438, blue: 0.5104221702, alpha: 1)
        view.addSubview(rect)
        view.bringSubviewToFront(rect)
        
        
        statusLabel = UILabel()
        statusLabel!.frame.origin.y = rect.frame.origin.y + 10
        statusLabel!.textAlignment = .center
        statusLabel!.textColor = UIColor.white
        statusLabel!.font = UIFont(name:"Helvetica-Light", size: 24)
        statusLabel!.text = "Scan the QR code"
        statusLabel!.sizeToFit()
        statusLabel!.center.x = CGFloat(view.center.x)
        view.addSubview(statusLabel!)
        
        
        let button = UIButton()
        button.frame = CGRect(x: Int(view.frame.width) / 2 - 30, y: Int(statusLabel!.frame.origin.y) + 30, width: 60, height: 60)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 30
        button.backgroundColor = #colorLiteral(red: 0.2099915743, green: 0.6485186219, blue: 0.6132951975, alpha: 1)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont(name: "FontAwesome5FreeSolid", size:28)!
        button.setTitle("\u{f057}", for: .normal)
        button.addTarget(self, action: #selector(cancelled), for: .touchUpInside)
        view.addSubview(button)
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 4
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
        
        captureSession.startRunning()
    }
    
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    @objc func cancelled() {
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    
    func success() {
        print("success")
        DispatchQueue.main.async(execute: {
            self.statusLabel!.text = "Success!"
        });
    }
    
    
    func failure() {
        print("failure")
        DispatchQueue.main.async(execute: {
            self.statusLabel!.text = "Failed to register!"
        });
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            let barCodeObject = previewLayer.transformedMetadataObject(for: metadataObject)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            statusLabel!.text = "Registering ..."
            //FRPushUtils().registerWithQRCode(code: stringValue, snsDeviceID: snsDeviceID, successHandler: success, failureHandler: failure)
            
            
            
            
            guard let url = URL(string: stringValue) else {
                print("Invalid QR Code: QR Code data is not in URL format.")
                return
            }
            
            
            guard let fraClient = FRAClient.shared else {
                print("FRAuthenticator SDK is not initialized")
                failure()
                return
            }
            
             print("CODE \(stringValue)")
            
            
            let accounts:[Account] = fraClient.getAllAccounts()
            for each in accounts {
                print(each.accountName)
                fraClient.removeAccount(account: each)
            }
            
            fraClient.createMechanismFromUri(uri: url, onSuccess: { (mechanism) in
                self.success()
             }, onError: { (error) in
                print("FAILED TO REGISTER: \(error.localizedDescription)")
                self.failure()
             })
             

        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}
