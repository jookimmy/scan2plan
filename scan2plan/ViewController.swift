//
//  ViewController.swift
//  BlinkCam
//
//  Created by Jackie Oh on 7/5/17.
//  Copyright © 2017 Jackie Oh. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import Photos

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var captureSession: AVCaptureSession!
    var photoOutput = AVCapturePhotoOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    //MARK: Outlets
    @IBOutlet weak var cameraView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myBounds = self.view.bounds
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        //Ask permission to camera
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        let devices = discoverySession.devices
        let device = devices.first
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) in
            if granted {
                print("granted")
                //Set up session
                if let input = try? AVCaptureDeviceInput(device: device!) {
                    print("yeah")
                    if (self.captureSession.canAddInput(input)) {
                        self.captureSession.addInput(input)
                        print("yeah2")
                        if (self.captureSession.canAddOutput(self.photoOutput)) {
                            print("yeah3")
                            self.captureSession.addOutput(self.photoOutput)
                            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                            self.previewLayer.frame = myBounds
                            self.cameraView.layer.addSublayer(self.previewLayer)
                            self.captureSession.startRunning()
                            print("Session is running")
                        }
                    }
                }
                
            }
            else {
                print("Goodbye")
            }
        })
        
        
    }
    
     override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        previewLayer.frame = previewLayer.bounds
     }
 
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func takePhoto(_ sender: UIButton) {
        var arr = Array<Any>()
        if #available(iOS 11.0, *) {
            arr = photoOutput.availablePhotoPixelFormatTypes
            print(arr)
        } else {
            // Fallback on earlier versions
        }
        print([kCVPixelBufferPixelFormatTypeKey : arr[0]])
        
        //creates capture photosettings object
        let cameraPhotoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String : arr[0]])
        
        //take photo
        photoOutput.capturePhoto(with: cameraPhotoSettings, delegate: self)
    }
    
    // switch from selfie to back camera
    @IBAction func switchCameraOrientation(_ sender: UIButton) {
    }
    
    @IBAction func importFromCameraRoll(_ sender: UIButton) {
    }
    
    @IBAction func useFlash(_ sender: UIButton) {
    }
    
    // AVCapturePhotoCaptureDelegate stuff
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        print("hell ya")
        PHPhotoLibrary.shared().performChanges( {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: PHAssetResourceType.photo, data: photo.fileDataRepresentation()!, options: nil)
        }, completionHandler: nil)
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        
        guard error == nil else {
            print("Error in capture process: \(String(describing: error))")
            return
        }
    }
}
