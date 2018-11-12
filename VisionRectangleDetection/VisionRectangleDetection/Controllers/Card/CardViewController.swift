//
//  CardViewController.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/12.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit
import Vision

final class CardViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!
    private var image: UIImage!
    private var correctedImageArray = [UIImage]()
    
    // MARK: - Factory
    
    class func make(image: UIImage) -> CardViewController {
        
        let storyboard = UIStoryboard(name: className, bundle: Bundle(for: self))
        let vc = storyboard.instantiateViewController(withIdentifier: className)
        guard let cardViewController = vc as? CardViewController else {
            fatalError("CardViewController is nil.")
        }
        cardViewController.image = image
        return cardViewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CardCell.register(collectionView: collectionView)
        setupVision()
    }
}

// MARK: - Vision functions
extension CardViewController {
    
    private func setupVision() {
        guard let cgImage = image.cgImage else { return }
        let request = VNDetectRectanglesRequest { request, error in
            self.handler(request: request, error: error, cgImage: cgImage)
        }
        request.maximumObservations = 8
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.3
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch let reqErr {
                print("Request error", reqErr)
            }
        }
    }
    
    private func handler(request: VNRequest, error: Error?, cgImage: CGImage) {
        
        if let error = error {
            print("Failed to detect", error)
            return
        }
        print("Result", request.results?.count ?? "")
        
        request.results?.forEach {
            guard let observation = $0 as? VNRectangleObservation else { return }
            print ("observation", observation)
            let ciImage = self.extractPerspectiveRect(observation, from: cgImage)
            
            DispatchQueue.main.sync {
                if let observedImage = UIImage.fromCIImage(ciImage: ciImage),
                    let rotatedImage = observedImage.imageRotatedByDegrees(degrees: 90.0) {
                    self.correctedImageArray.append(rotatedImage)
                }
            }
        }
        
        DispatchQueue.main.sync {
            self.collectionView.reloadData()
        }
    }
    
    func extractPerspectiveRect(_ observation: VNRectangleObservation,
                                from cgImage: CGImage) -> CIImage {
        // get the pixel buffer into Core Image
        let ciImage = CIImage(cgImage: cgImage)
        
        // convert corners from normalized image coordinates to pixel coordinates
        let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
        let topRight = observation.topRight.scaled(to: ciImage.extent.size)
        let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)
        print(topLeft, topRight, bottomLeft, bottomRight)
        
        // pass those to the filter to extract/rectify the image
        return ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight),
            ]
        )
    }
}

// MARK: - UICollectionViewDataSource
extension CardViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return correctedImageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCell.identifier,
                                                      for: indexPath) as! CardCell
        cell.imageView.image = correctedImageArray[indexPath.item]
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CardViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let height = width * 3 / 4
        return CGSize(width: width, height: height)
    }
}
