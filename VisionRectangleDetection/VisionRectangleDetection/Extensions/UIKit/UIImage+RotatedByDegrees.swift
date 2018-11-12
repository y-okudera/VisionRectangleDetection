//
//  UIImage+RotatedByDegrees.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/13.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit

extension UIImage {
    func imageRotatedByDegrees(degrees: CGFloat) -> UIImage? {
        
        // Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBoxFrame = CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height
        )
        let rotatedViewBox = UIView(frame: rotatedViewBoxFrame)
        let transform = CGAffineTransform(rotationAngle: degrees * .pi / 180)
        rotatedViewBox.transform = transform
        let rotatedSize = rotatedViewBox.frame.size
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        guard let bitmap = UIGraphicsGetCurrentContext(), let cgImage = cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        // Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        // Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        
        let newFrame = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        bitmap.draw(cgImage, in: newFrame)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
