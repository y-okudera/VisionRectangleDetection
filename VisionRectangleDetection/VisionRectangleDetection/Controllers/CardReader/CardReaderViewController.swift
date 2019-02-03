//
//  CardReaderViewController.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/12.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

final class CardReaderViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var cameraButton: UIButton!
    
    private var cardShootingHelper = CardShootingHelper()
    private var lastUpdateDate: Date?
    var activityIndicator = UIActivityIndicatorView()
    
    // MARK: - Life cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let sublayers = imageView.layer.sublayers {
            sublayers.forEach {
                $0.removeFromSuperlayer()
            }
        }
        cardShootingHelper = CardShootingHelper()
        cardShootingHelper.delegate = self
        cardShootingHelper.startLiveVideo()
        cardShootingHelper.capturePhotoOutputSetting()
        cardShootingHelper.startRectanglesDetection()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.layer.sublayers?.first?.frame = imageView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageView.layer.sublayers?.removeSubrange(1...)
        cardShootingHelper.stopLiveVideo()
    }
}

// MARK: - IBActions
extension CardReaderViewController {
    @IBAction private func capturePhoto(_ sender: UIButton) {
        cameraButton.isEnabled = false
        cardShootingHelper.clearCorrectedImageArray()
        cardShootingHelper.captureImage()
        imageView.layer.sublayers?.removeSubrange(1...)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.cameraButton.isEnabled = true
        }
        showIndicator()
    }
}

// MARK: - private function
extension CardReaderViewController {
    private func transitionToCardViewController(images: [UIImage]) {
        let cardViewController = CardViewController.instance(images: images)
        navigationController?.pushViewController(cardViewController, animated: true)
    }
}

// MARK: - ViewControllerInstantiatable
extension CardReaderViewController: ViewControllerInstantiatable {}

// MARK: - IndicatorPresenter
extension CardReaderViewController: IndicatorPresenter {}

// MARK: - CardShootingDelegate
extension CardReaderViewController: CardShootingDelegate {
    
    /// CaptureSession開始直前を通知
    func willStartCaptureSession(captureVideoPreviewLayer: AVCaptureVideoPreviewLayer) {
        captureVideoPreviewLayer.frame = imageView.bounds
        imageView.layer.addSublayer(captureVideoPreviewLayer)
    }
    
    /// 矩形検知を通知
    func detectObjectHandler(rectangleObservations: [VNRectangleObservation]) {
        print("矩形検知")
        
        if let lastUpdateDate = self.lastUpdateDate {
            let now = Date()
            let threshold = lastUpdateDate.addingTimeInterval(1.0)
            if threshold > now {
                print("1.0sec以内は更新しない")
                return
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.cameraButton.isHidden = rectangleObservations.isEmpty
            weakSelf.imageView.layer.sublayers?.removeSubrange(1...)
            CirclesDrawer.draw(rectangles: rectangleObservations, onImageView: weakSelf.imageView)
            weakSelf.lastUpdateDate = Date()
        }
    }
    
    /// 撮影完了を通知
    func didFinishCapture(imageArray: [UIImage]) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.hideIndicator()
            weakSelf.transitionToCardViewController(images: imageArray)
        }
    }
}
