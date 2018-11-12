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
    
    private let capturePhotoOutput = AVCapturePhotoOutput()
    private var session = AVCaptureSession()
    private var vnRequests = [VNRequest]()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startLiveVideo()
        capturePhotoOutputSetting()
        startRectanglesDetection()
        view.addSubview(cameraButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.layer.sublayers?.first?.frame = imageView.bounds
    }
    
    // MARK: - IBActions
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    /// CaptureSession開始
    private func startLiveVideo() {
        session.sessionPreset = .photo
        let captureDevice = AVCaptureDevice.default(for: .video)
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice!)
            let deviceOutput = AVCaptureVideoDataOutput()
            
            let key = kCVPixelBufferPixelFormatTypeKey as String
            deviceOutput.videoSettings = [key: Int(kCVPixelFormatType_32BGRA)]
            deviceOutput.setSampleBufferDelegate(self, queue: .global())
            
            session.addInput(deviceInput)
            session.addOutput(deviceOutput)
            
            let imageLayer = AVCaptureVideoPreviewLayer(session: session)
            imageLayer.frame = imageView.bounds
            imageView.layer.addSublayer(imageLayer)
            session.startRunning()
        } catch {
            print(error)
        }
    }
    
    /// AVCapturePhotoOutputの設定
    private func capturePhotoOutputSetting() {
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        session.addOutput(capturePhotoOutput)
    }
    
    /// 矩形検知開始
    private func startRectanglesDetection() {
        let request = VNDetectRectanglesRequest(completionHandler: self.detectObjectHandler)
        request.maximumObservations = 8
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.3
        
        self.vnRequests = [request]
    }
    
    // 矩形検知時のハンドラ
    private func detectObjectHandler(request: VNRequest, error: Error?) {
        guard let req = request.results else {
            print("no result")
            return
        }
        let result = req.map { $0 as? VNRectangleObservation }
        
        DispatchQueue.main.async {
            if result.isEmpty {
                self.cameraButton.setTitle("Looking", for: .normal)
                self.cameraButton.setTitleColor(.lightGray, for: .normal)
                self.cameraButton.isEnabled = false
            } else {
                self.cameraButton.setTitle("Capture", for: .normal)
                self.cameraButton.setTitleColor(.blue, for: .normal)
                self.cameraButton.isEnabled = true
            }
            self.imageView.layer.sublayers?.removeSubrange(1...)
            RectanglesDrawer.draw(
                rectangles: result as! [VNRectangleObservation],
                onImageView: self.imageView
            )
            self.imageView.layer.setNeedsDisplay()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CardReaderViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let imageData = photo.fileDataRepresentation()
        guard let data = imageData, let photo = UIImage(data: data) else {
            return
        }
        let vc = CardViewController.make(image: photo)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CardReaderViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions = [VNImageOption: Any]()
        
        if let cameraIntrinsicData = CMGetAttachment(
            sampleBuffer,
            key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
            attachmentModeOut: nil
            ) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: requestOptions
        )
        do {
            try imageRequestHandler.perform(vnRequests)
        } catch {
            print(error)
        }
    }
}

// MARK: - ViewControllerInstantiatable
extension CardReaderViewController: ViewControllerInstantiatable {}
