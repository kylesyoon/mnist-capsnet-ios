//
//  ViewController.swift
//  MNIST-Client
//
//  Created by Yoon, Kyle on 4/13/18.
//  Copyright © 2018 Yoon, Kyle. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {
    var lastPoint = CGPoint.zero
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        self.lastPoint = touch.location(in: self.tempImageView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self.tempImageView)
        self.drawLineFrom(fromPoint: self.lastPoint, toPoint: currentPoint)
        
        self.lastPoint = currentPoint
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        // 1
        UIGraphicsBeginImageContext(self.tempImageView.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        self.tempImageView.image?.draw(in: self.tempImageView.bounds)
        
        // 2
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        
        // 3
        context.setLineCap(.round)
        context.setLineWidth(10.0)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setBlendMode(.normal)
        
        // 4
        context.strokePath()
        
        // 5
        self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        self.tempImageView.alpha = 1.0
        UIGraphicsEndImageContext()
    }
    
    @IBAction func didTapSend(_ sender: Any) {
        guard let imageData = UIImageJPEGRepresentation(self.tempImageView.image!, 0.2) else { return }
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData, withName: "predict_image", fileName: "number.jpg", mimeType: "image/jpg")
        },
                         to: "http://127.0.0.1:8000/capsnet/predict/",
                         encodingCompletion: { result in
                            switch result {
                            case .success(let upload, _, _):
                                upload.uploadProgress(closure: { progress in
                                    print("PROGRESS: \(progress.fractionCompleted)")
                                })
                                
                                upload.responseJSON(completionHandler: { response in
                                    guard
                                        let json = response.result.value as? [String: Int],
                                        let prediction = json["prediction"] else { return }
                                    self.predictionLabel.text = "\(prediction)"
                                })
                            case .failure(let error):
                                print(error)
                            }
        })
    }
    
    @IBAction func didTapClear(_ sender: Any) {
        self.tempImageView.image = nil
        self.predictionLabel.text = nil
    }
}

