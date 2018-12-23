//
//  ViewController.swift
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


class ViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var photoOutput = AVCapturePhotoOutput()
    var device: AVCaptureDevice!
    let cameraPhotoSettings = AVCapturePhotoSettings()
    
    var flashMode = AVCaptureDevice.FlashMode.off
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    internal var previewView: UIView?
    internal var gestureView: UIView?
    internal var focusTapGestureRecognizer: UITapGestureRecognizer?
    internal var focusView: FocusIndicatorView?
    
    // Mobile Vision stuff
    private lazy var vision = Vision.vision()
    private lazy var textRecognizer = vision.onDeviceTextRecognizer()
    
    // objects to pass to Preview VC
    var imageTaken: UIImage!
    var visionText: VisionText!
    
    //MARK: Outlets
    @IBOutlet weak var topToolBarView: UIView!
    @IBOutlet weak var bottomToolBar: UIView!
    @IBOutlet weak var cameraRollButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var capturePhotoButton: UIButton!
    
    var backCamera = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bounds:CGRect = self.view.layer.bounds
        self.previewView = UIView(frame: bounds)
        
        self.focusView = FocusIndicatorView(frame: .zero)
        
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
//        print(discoverySession.)
        
        let devices = discoverySession.devices
        self.device = devices.first
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) in
            if granted {
                print("granted")
                //Set up session
                if let input = try? AVCaptureDeviceInput(device: self.device!) {
                    print("valid input")
                    if (self.captureSession.canAddInput(input)) {
                        self.captureSession.addInput(input)
                        print("added input")
                        if (self.captureSession.canAddOutput(self.photoOutput)) {
                            print("added output")
                            self.captureSession.addOutput(self.photoOutput)
                            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                            self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                            // This UI Stuff needs to run on the main thread
                            DispatchQueue.main.async {
                                self.previewLayer?.frame = bounds
                                self.previewLayer?.position = CGPoint(x: bounds.midX, y: bounds.height * 0.477)
                                self.previewView?.frame = self.previewLayer.bounds
                                self.previewView?.layer.addSublayer(self.previewLayer)
                            }
                            self.captureSession.startRunning()
                            print("Session is running")
                        }
                    }
                }
                
            }
            else {
                print("Access to camera denied")
            }
        })
        
        self.captureSession.commitConfiguration()
        
        // gestures
        self.gestureView = UIView(frame: (self.previewView?.bounds)!)
        if let gestureView = self.gestureView {
            gestureView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            gestureView.backgroundColor = .clear
//            gestureView.bounds = (self.previewView?.bounds)!
            self.previewView!.addSubview(gestureView)
            
            self.focusTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleFocusTapGestureRecognizer(_:)))
            if let focusTapGestureRecognizer = self.focusTapGestureRecognizer {
                focusTapGestureRecognizer.delegate = self
                focusTapGestureRecognizer.numberOfTapsRequired = 1
                gestureView.addGestureRecognizer(focusTapGestureRecognizer)
            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds:CGRect = self.view.layer.bounds
        let backgroundColor = UIColor(hex: "33383e")
        
        self.topToolBarView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height * 0.1)
        self.topToolBarView.backgroundColor = backgroundColor
        
        self.bottomToolBar.frame = CGRect(x: 0, y: bounds.height * 0.85, width: bounds.width, height: bounds.height * 0.15)
        self.bottomToolBar.backgroundColor = backgroundColor
        
        if let topToolBarView = self.topToolBarView {
            print("here")
            self.flipCameraButton.frame = CGRect(x: bounds.width/10, y: bounds.height/20, width: bounds.width/13, height: bounds.width/13)
            self.flipCameraButton.center = CGPoint(x: topToolBarView.bounds.width/10, y: topToolBarView.bounds.height*0.55)
            topToolBarView.addSubview(flipCameraButton)
            
            self.flashButton.frame = CGRect(x: (bounds.width*9)/10, y: bounds.height/20, width: bounds.width/13, height: bounds.width/13)
            self.flashButton.center = CGPoint(x: topToolBarView.bounds.width*9/10, y: topToolBarView.bounds.height*0.55)
            topToolBarView.addSubview(flashButton)
        }
        
        if let bottomToolBar = self.bottomToolBar {
            print("here")
            self.capturePhotoButton.frame = CGRect(x: bounds.width/2 - bounds.width/12, y: bottomToolBar.bounds.height/2 - bounds.width/12, width: bounds.width/6, height: bounds.width/6)
            bottomToolBar.addSubview(capturePhotoButton)
            
            self.cameraRollButton.frame = CGRect(x: bounds.width/12, y: bottomToolBar.bounds.height/2 - bounds.width/20, width: bounds.width/10, height: bounds.width/10)
            bottomToolBar.addSubview(cameraRollButton)
        }
        self.view?.addSubview(self.topToolBarView)
        self.view?.addSubview(self.bottomToolBar)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    @IBAction func takePhoto(_ sender: UIButton) {
        var arr = Array<Any>()
        if #available(iOS 11.0, *) {
            arr = photoOutput.availablePhotoPixelFormatTypes
            print(arr)
        } else {
            // Fallback on earlier versions
        }
        print([kCVPixelBufferPixelFormatTypeKey : arr[0]])
        print(cameraPhotoSettings)
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
    
    // Implement later
    @IBAction func useFlash(_ sender: UIButton) {
        if self.flashMode == .on {
            self.flashMode = .off
            self.cameraPhotoSettings.flashMode = .off
            self.flashButton.setImage(UIImage(named: "FlashOff"), for: UIControl.State.normal)
            
        }
            
        else {
            self.flashMode = .on
            self.cameraPhotoSettings.flashMode = .on
            self.flashButton.setImage(UIImage(named: "FlashOn"), for: UIControl.State.normal)
        }
    }
    
    // upload from camera roll
    @IBAction func upload(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true)
        {
        }
    }
    
    // Allows user to tap any point on the screen to focus the camera
    public func focusAtAdjustedPointOfInterest(adjustedPoint: CGPoint) {
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                let focusMode = device.focusMode
                device.focusPointOfInterest = adjustedPoint
                device.focusMode = focusMode
                print("focusing")
            }
            
            device.unlockForConfiguration()
        }
        catch {
            print("focusAtAdjustedPointOfInterest failed to lock device for configuration")
        }
    }
    
    // Text Recognition
    
    // runs the text recognition model on given image
    func runTextRecognition(with image: UIImage) {
        print("here")
        // creates a vision image from the passed uiimage
        let visionImage = VisionImage(image: image)
        textRecognizer.process(visionImage) { features, error in
            self.processResult(from: features, error: error, image: image)
        }
    }
    
    // handles the result of text recognition
    func processResult(from text: VisionText?, error: Error?, image: UIImage) {
        guard error == nil, let text = text else {
            // no text detected
            let alert = UIAlertController(title: "No Text Detected", message: "Please try again.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(alert: UIAlertAction!) in print("Didn't work")}))
            self.present(alert, animated: true)
            
            print("oops")
            return
        }
        print("got here")
        self.visionText = text
        print(text.text)
        self.imageTaken = image
        self.performSegue(withIdentifier: "photoTaken", sender: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if segue.identifier == "photoTaken" {
            let previewVC = segue.destination as! PreviewViewController
            // Pass the selected object to the new view controller.
            previewVC.capturedPhoto = self.imageTaken
            previewVC.visionText = self.visionText
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let orientation = image.imageOrientation
            var rotated = image.rotate(radians: -.pi/2)!
            
//            if orientation == .right {
//                rotated = image.rotate(radians: .pi/2)!
//                print("right")
//            } else if orientation == .left {
//                rotated = image.rotate(radians: -.pi/2)!
//                print("left")
//            } else if orientation == .down {
//                rotated = image.rotate(radians: .pi)!
//                print("down")
//            }
            
            self.runTextRecognition(with: image)
        } else {
            print("error")
        }
        self.dismiss(animated: false, completion: nil)
    }
    
}

// MARK: - UIGestureRecognizerDelegate

extension ViewController: UIGestureRecognizerDelegate {
    @objc internal func handleFocusTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: self.previewView)
        
        if let focusView = self.focusView {
            var focusFrame = focusView.frame
            focusFrame.origin.x = CGFloat((tapPoint.x - (focusFrame.size.width * 0.5)).rounded())
            focusFrame.origin.y = CGFloat((tapPoint.y - (focusFrame.size.height * 0.5)).rounded())
            focusView.frame = focusFrame
            
            self.previewView?.addSubview(focusView)
            focusView.startAnimation()
            print("focusing here")
            
            // stops animation after 0.4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                focusView.stopAnimation()
            }
        }
        
        let adjustedPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
        self.focusAtAdjustedPointOfInterest(adjustedPoint: adjustedPoint)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        print("photo taken")
        
        /*
         // save to camera roll
         PHPhotoLibrary.shared().performChanges( {
         let creationRequest = PHAssetCreationRequest.forAsset()
         creationRequest.addResource(with: PHAssetResourceType.photo, data: photo.fileDataRepresentation()!, options: nil)
         }, completionHandler: nil)
         */
        
        let cgImage = photo.cgImageRepresentation()!.takeUnretainedValue()
        let testImage = UIImage(cgImage: cgImage, scale: 1, orientation: UIImage.Orientation.up)
        // assumes that image orientation is .right (might need to fix this later)
        let rotated = testImage.rotate(radians: .pi/2)
        
        self.runTextRecognition(with: rotated!)
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

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
