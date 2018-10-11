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
    
    // Properties
    var captureSession: AVCaptureSession!
    var photoOutput = AVCapturePhotoOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    // view that will contain our camera
    internal var previewView: UIView?
    
    var backCamera = true
    
    //MARK: Outlets
    @IBOutlet weak var cameraRollButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var capturePhotoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bounds:CGRect = self.view.layer.bounds
        
        self.previewView = UIView(frame: bounds)
        
        // this runs only if previewView isn't nil, needed because we defined previewView as optional
        if let previewView = self.previewView {
            self.view.addSubview(previewView)
            self.previewView?.sendSubviewToBack(self.view)
        } else {
            print("previewView not added")
        }
        
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        //Ask permission to camera
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        let devices = discoverySession.devices
        let device = devices.first
        
        // makes sure that user has given permission for app to access the camera, if not, requests access in form of popup (this is handled in info.plist)
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) in
            if granted {
                print("granted")
                //Set up session
                if let input = try? AVCaptureDeviceInput(device: device!) {
                    print("input found")
                    if (self.captureSession.canAddInput(input)) {
                        self.captureSession.addInput(input)
                        print("added input")
                        if (self.captureSession.canAddOutput(self.photoOutput)) {
                            print("added output")
                            self.captureSession.addOutput(self.photoOutput)
                            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                            // makes it so that camera fills up screen
                            self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                            self.previewLayer?.bounds = bounds
                            self.previewLayer?.position = CGPoint(x: bounds.midX, y: bounds.midY)
                            // adds the preview layer to preview view (which will later be added to view)
                            self.previewView?.layer.addSublayer(self.previewLayer)
                            // starts the captureSession! :)
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
        captureSession.commitConfiguration()
        
        // setup UI, location of buttons
        
        // lower buttons
        self.capturePhotoButton.frame = CGRect(x: bounds.width/2 - bounds.width/12, y: (bounds.height * 8.5)/10, width: bounds.width/6, height: bounds.width/6)
        self.view.addSubview(capturePhotoButton)
        
        self.flipCameraButton.frame = CGRect(x: bounds.width/5 - bounds.width/20, y: (bounds.height * 8.5)/10, width: bounds.width/10, height: bounds.width/10)
        self.view.addSubview(flipCameraButton)
        
        self.flashButton.frame = CGRect(x: (bounds.width*4)/5 - bounds.width/20, y: (bounds.height * 8.5)/10, width: bounds.width/10, height: bounds.width/10)
        self.view.addSubview(flashButton)
        
        // upper buttons
        
        self.profileButton.frame = CGRect(x: bounds.width/12, y: (bounds.height)/12, width: bounds.width/9, height: bounds.width/9)
        self.view.addSubview(profileButton)
        
        self.cameraRollButton.frame = CGRect(x: (bounds.width*11)/12 - bounds.width/18, y: (bounds.height)/12, width: bounds.width/9, height: bounds.width/9)
        self.view.addSubview(cameraRollButton)
    }
    
     override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        previewLayer.frame = self.view.bounds
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
        
        // checks which camera the app is currently using (front or back)
        if self.backCamera {
            // we're currently using the back camera, so we want to switch to the front
            // begins changing the capture session
            captureSession.beginConfiguration()
            // removes previous captureSession inputs
            for input in captureSession!.inputs {
                captureSession!.removeInput(input)
            }
            // creates new discoverySession
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front)
            
            // uses discovery session to find all devices that matched our preferences (front camera)
            let devices = discoverySession.devices
            
            // gets first device out of that list
            let device = devices.first
            
            // used device to (attempt to) create new AVCaptureDeviceInput
            if let input = try? AVCaptureDeviceInput(device: device!) {
                print("allowed new input")
                
                // made sure the captureSession can add a new input
                if (self.captureSession.canAddInput(input)) {
                    self.captureSession.addInput(input)
                    print("switched camera")
                    
                    // we're now using the front camera, so we set backCamera to false
                    self.backCamera = false
                }
            }
            // commits changes to captureSession
            captureSession.commitConfiguration()
        } else {
            
            // we're using the front camera
            captureSession.beginConfiguration()
            for input in captureSession!.inputs {
                captureSession!.removeInput(input)
            }
            
            // creates discoverySession that looks for back cameras
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: AVMediaType.video, position: .back)
            let devices = discoverySession.devices
            let device = devices.first
            if let input = try? AVCaptureDeviceInput(device: device!) {
                print("allowed new input")
                if (self.captureSession.canAddInput(input)) {
                    self.captureSession.addInput(input)
                    print("switched camera")
                    self.backCamera = true
                }
            }
            captureSession.commitConfiguration()
        }
        
    }
    
    // Shannon will implement
    @IBAction func importFromCameraRoll(_ sender: UIButton) {
    }
    
    // Fiza will implement
    @IBAction func useFlash(_ sender: UIButton) {
    }
    
    // AVCapturePhotoCaptureDelegate stuff
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        print("saved")
        
        // saves captured photo to camera roll
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
