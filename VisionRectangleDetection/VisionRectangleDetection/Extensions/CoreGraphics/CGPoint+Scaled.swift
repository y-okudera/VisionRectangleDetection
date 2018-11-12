//
//  CGPoint+Scaled.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/13.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
