//
//  RectanglesDrawer.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/13.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit
import Vision

struct RectanglesDrawer {
    
    // Rectangles are Red.
    static func draw(rectangles: [VNRectangleObservation],
                     onImageView imageView: UIImageView,
                     color: UIColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)) {
        CATransaction.begin()
        rectangles.forEach {
            let rectBox = boundingBox(
                forRegionOfInterest: $0.boundingBox,
                withinImageBounds: imageView.layer.bounds
            )
            let rectLayer = shapeLayer(color: color, frame: rectBox)
            
            // Add to pathLayer on top of image.
            imageView.layer.addSublayer(rectLayer)
        }
        CATransaction.commit()
    }
    
    private static func boundingBox(forRegionOfInterest: CGRect,
                                    withinImageBounds bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        // Begin with input rect.
        var rect = forRegionOfInterest
        
        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.origin.x
        rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y
        
        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight
        
        return rect
    }
    
    private static func shapeLayer(color: UIColor, frame: CGRect) -> CAShapeLayer {
        // Create a new layer.
        let layer = CAShapeLayer()
        
        // Configure layer's appearance.
        layer.fillColor = nil // No fill to show boxed object
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.borderWidth = 2
        
        // Vary the line color according to input.
        layer.borderColor = color.cgColor
        
        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true
        
        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)
        
        return layer
    }
}
