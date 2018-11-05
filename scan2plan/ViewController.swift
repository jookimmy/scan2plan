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
import Firebase
import FirebaseMLVision


class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var captureSession: AVCaptureSession!
    var photoOutput = AVCapturePhotoOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    internal var previewView: UIView?
    
    // Mobile Vision stuff
    private lazy var vision = Vision.vision()
    private lazy var textRecognizer = vision.onDeviceTextRecognizer()
    
    //MARK: Outlets
    @IBOutlet weak var cameraRollButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var capturePhotoButton: UIButton!
    
    var backCamera = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bounds:CGRect = self.view.layer.bounds
        
        self.previewView = UIView(frame: bounds)
        
        if let previewView = self.previewView {
            self.view.addSubview(previewView)
            self.previewView?.sendSubviewToBack(self.view)
        } else {
            print("previewView not added")
        }
        
        // setup vision stuff
        vision = Vision.vision()

        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
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
                            self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                            self.previewLayer?.bounds = bounds
                            self.previewLayer?.position = CGPoint(x: bounds.midX, y: bounds.midY)
                            self.previewView?.layer.addSublayer(self.previewLayer)
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
            // ends changes
            captureSession.commitConfiguration()
        }
    }
    
    @IBAction func importFromCameraRoll(_ sender: UIButton) {
    }
    
    // temporary test button
    @IBAction func useFlash(_ sender: UIButton) {
        let uiimage = UIImage(named: "testImage")
        
        self.runTextRecognition(with: uiimage!)
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
        
//        let cgImage = photo.cgImageRepresentation()!.takeUnretainedValue()
//        print(kCGImagePropertyOrientation as String)
//        let orientation = photo.metadata[kCGImagePropertyOrientation as String] as! NSNumber
////        let uiOrientation = UIImage.Orientation(rawValue: orientation.intValue)!
//        let image = UIImage(cgImage: cgImage, scale: 1, orientation: UIImage.Orientation.up)
//        print(image.imageOrientation)
        
        let testImage = UIImage(data: photo.fileDataRepresentation()!)
        
        self.runTextRecognition(with: testImage!)
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        
        guard error == nil else {
            print("Error in capture process: \(String(describing: error))")
            return
        }
    }
    
    func runTextRecognition(with image: UIImage) {
        let visionImage = VisionImage(image: image)
        textRecognizer.process(visionImage) { features, error in
            self.processResult(from: features, error: error)
        }
    }
    
    func processResult(from text: VisionText?, error: Error?) {
        guard error == nil, let text = text else {
            print("oops")
            return
        }
        
//        for block in text.blocks {
//            print(block.text)
//        }
        
        print(text.text)
        
        let defaultAction = UIAlertAction(title: "Agree",
                                          style: .default) { (action) in
                                            // Respond to user selection of the action.
        }
        let okayAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            // Respond to user selection of the action
        }
        
        let alert = UIAlertController(title: "Detected text", message: text.text, preferredStyle: .alert)
        alert.addAction(okayAction)
        alert.addAction(defaultAction)
        print(alert)
        
        self.present(alert, animated: true) {
            // alert was presented
        }
    }
}
