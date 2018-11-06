//
//  PreviewViewController.swift
//  scan2plan
//
//  Created by Jackie Oh on 11/5/18.
//  Copyright © 2018 CS196Illinois. All rights reserved.
//

import UIKit
import Vision
import Firebase
import FirebaseMLVision

class PreviewViewController: UIViewController {
    
    var frameSublayer = CALayer()
    
    // Passed from camera vc
    var capturedPhoto: UIImage!
    var visionText: VisionText!
    
    // MARK: Outlets
    @IBOutlet weak var previewImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let bounds = self.view.bounds
        
        let widthHeightRatio = capturedPhoto.size.width/capturedPhoto.size.height
        let width = self.previewImage.frame.width
        let height = width / widthHeightRatio
        previewImage.frame.size = CGSize(width: width, height: height)
        
        previewImage.center = self.view.center
        
        // set image display to photo captured in previous vc
        self.previewImage.image = capturedPhoto // UIImage(named: "testImage")
        self.previewImage.layer.addSublayer(frameSublayer)
        
        guard let features = visionText, let image = capturedPhoto else {
            return
        }
        for block in features.blocks {
            for line in block.lines {
                for element in line.elements {
                    self.addFrameView(
                        featureFrame: element.frame,
                        imageSize: image.size,
                        viewFrame: self.previewImage.frame,
                        text: element.text
                    )
                }
            }
        }
        
        // alert containing detected text

        let okAlert = UIAlertAction(title: "OK", style: .default) { (action) in
            // move on to next vc with parsed event info
        }
        let retakeAlert = UIAlertAction(title: "Retake photo", style: .default) { (action) in
            // return to camera vc
        }
        
        print(visionText.text)
        
        // displays detected text in popup window
        let alert = UIAlertController(title: "Detected text", message: visionText.text, preferredStyle: .alert)
        alert.addAction(okAlert)
        alert.addAction(retakeAlert)

        self.present(alert, animated: true) {
            print("alert was presented")
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    // MARK: Image Drawing - from Google's codelab example
    
    /// Converts a feature frame to a frame UIView that is displayed over the image.
    ///
    /// - Parameters:
    ///   - featureFrame: The rect of the feature with the same scale as the original image.
    ///   - imageSize: The size of original image.
    ///   - viewRect: The view frame rect on the screen.
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect, text: String? = nil) {
        print("Frame: \(featureFrame).")
        
        let viewSize = viewFrame.size
        
        // Find resolution for the view and image
        let rView = viewSize.width / viewSize.height
        let rImage = imageSize.width / imageSize.height
        
        // Define scale based on comparing resolutions
        var scale: CGFloat
        if rView > rImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        // Calculate scaled feature frame size
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        // Calculate scaled feature frame top-left point
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        // Define a rect for scaled feature frame
        let featureRectScaled = CGRect(x: featurePointXScaled,
                                       y: featurePointYScaled,
                                       width: featureWidthScaled,
                                       height: featureHeightScaled)
        
        drawFrame(featureRectScaled, text: text)
    }
    
    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect, text: String? = nil) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = Constants.lineColor
        rectLayer.fillColor = Constants.fillColor
        rectLayer.lineWidth = Constants.lineWidth
        if let text = text {
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.fontSize = 12.0
            textLayer.foregroundColor = Constants.lineColor
            let center = CGPoint(x: rect.midX, y: rect.midY)
            textLayer.position = center
            textLayer.frame = rect
            textLayer.alignmentMode = CATextLayerAlignmentMode.center
            textLayer.contentsScale = UIScreen.main.scale
            frameSublayer.addSublayer(textLayer)
        }
        frameSublayer.addSublayer(rectLayer)
    }

}

// MARK: - Fileprivate

fileprivate enum Constants {
    static let lineWidth: CGFloat = 1.0
    static let lineColor = UIColor.red.cgColor
    static let fillColor = UIColor.clear.cgColor
}
