//
//  UIImage+FromCIImage.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/13.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit

extension UIImage {
    static func fromCIImage(ciImage: CIImage) -> UIImage? {
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
