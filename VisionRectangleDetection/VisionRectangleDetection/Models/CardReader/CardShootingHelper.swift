//
//  CardShootingHelper.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2019/02/03.
//  Copyright © 2019 Yuki Okudera. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

protocol CardShootingDelegate: class {
    
    /// CaptureSession開始直前を通知
    func willStartCaptureSession(captureVideoPreviewLayer: AVCaptureVideoPreviewLayer)
    
    /// 矩形検知を通知
    func detectObjectHandler(rectangleObservations: [VNRectangleObservation])
    
    /// 撮影完了を通知
    func didFinishCapture(imageArray: [UIImage])
}

final class CardShootingHelper: NSObject {
    
    weak var delegate: CardShootingDelegate?
    private var capturePhotoOutput: AVCapturePhotoOutput?
    private var session: AVCaptureSession?
    private var vnRequests = [VNRequest]()
    private var correctedImageArray = [UIImage]()
    private var maximumObservations = 6
    
    private var captureDevice: AVCaptureDevice?
    
    init(maximumObservations: Int = 6) {
        self.maximumObservations = maximumObservations
    }
}

extension CardShootingHelper {
    
    /// 矩形認識して切り出した画像の配列をクリアする
    func clearCorrectedImageArray() {
        correctedImageArray = []
    }
    
    /// CaptureSession開始
    func startLiveVideo() {
        session = AVCaptureSession()
        
        guard let session = self.session else {
            return
        }
        
        session.sessionPreset = .photo
        captureDevice = AVCaptureDevice.default(for: .video)
        guard let captureDevice = self.captureDevice else {
            print("[E] captureDevice is nil.")
            return
        }
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            let deviceOutput = AVCaptureVideoDataOutput()
            
            let key = kCVPixelBufferPixelFormatTypeKey as String
            deviceOutput.videoSettings = [key: Int(kCVPixelFormatType_32BGRA)]
            deviceOutput.setSampleBufferDelegate(self, queue: .global())
            
            session.addInput(deviceInput)
            session.addOutput(deviceOutput)
            
            let imageLayer = AVCaptureVideoPreviewLayer(session: session)
            imageLayer.videoGravity = .resizeAspectFill
            delegate?.willStartCaptureSession(captureVideoPreviewLayer: imageLayer)
            session.startRunning()
        } catch {
            print("[E] \(error)")
        }
    }
    
    func stopLiveVideo() {
        
        guard let session = self.session else {
            return
        }
        
        session.stopRunning()
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        self.session = nil
        capturePhotoOutput = nil
        captureDevice = nil
    }
    
    /// AVCapturePhotoOutputの設定
    func capturePhotoOutputSetting() {
        capturePhotoOutput = AVCapturePhotoOutput()
        guard let capturePhotoOutput = self.capturePhotoOutput else {
            return
        }
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        session?.addOutput(capturePhotoOutput)
    }
    
    /// 矩形検知開始
    func startRectanglesDetection() {
        let request = VNDetectRectanglesRequest(completionHandler: self.detectObjectHandler)
        request.maximumObservations = self.maximumObservations
        request.minimumAspectRatio = 0.1
        request.minimumSize = 0.2
        self.vnRequests = [request]
    }
    
    // 矩形検知時のハンドラ
    private func detectObjectHandler(request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("[E] VNRequest result is nil.")
            return
        }
        let rectangleObservations = results.compactMap { $0 as? VNRectangleObservation }
        delegate?.detectObjectHandler(rectangleObservations: rectangleObservations)
    }
    
    /// 撮影する
    func captureImage() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        capturePhotoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CardShootingHelper {
    
    /// 矩形認識要求
    private func requestDetectRectangles(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let request = VNDetectRectanglesRequest { request, error in
            self.handler(request: request, error: error, cgImage: cgImage)
        }
        request.maximumObservations = self.maximumObservations
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.3
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("[E] VNImageRequestHandler error.", error)
            }
        }
    }
    
    private func handler(request: VNRequest, error: Error?, cgImage: CGImage) {
        
        if let error = error {
            print("[E] Failed to detect.", error)
            return
        }
        
        request.results?.forEach { [weak self] in
            
            guard let weakSelf = self else {
                return
            }
            guard let observation = $0 as? VNRectangleObservation else {
                return
            }
            let ciImage = weakSelf.extractPerspectiveRect(observation, from: cgImage)
            
            DispatchQueue.main.sync {
                if let observedImage = UIImage.fromCIImage(ciImage: ciImage),
                    let rotatedImage = observedImage.imageRotatedByDegrees(degrees: 90.0) {
                    weakSelf.correctedImageArray.append(rotatedImage)
                }
            }
        }
        
        // 通知する
        delegate?.didFinishCapture(imageArray: correctedImageArray)
    }
    
    func extractPerspectiveRect(_ observation: VNRectangleObservation, from cgImage: CGImage) -> CIImage {
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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CardShootingHelper: AVCaptureVideoDataOutputSampleBufferDelegate {
    
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
            print("[E] VNImageRequestHandler error.", error)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CardShootingHelper: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        guard let data = imageData, let image = UIImage(data: data) else {
            return
        }
        requestDetectRectangles(image: image)
    }
}
