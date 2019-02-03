//
//  RectanglesDrawer.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/13.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit
import Vision

struct CirclesDrawer {
    
    // Draw circles.
    static func draw(rectangles: [VNRectangleObservation],
                     onImageView imageView: UIImageView,
                     color: UIColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)) {
        if rectangles.isEmpty {
            return
        }
        CATransaction.begin()
        rectangles.forEach {
            let rectBox = boundingBox(forRegionOfInterest: $0.boundingBox, withinImageBounds: imageView.layer.bounds)
            let circleLayer = shapeLayer(color: color, frame: rectBox)
            
            // Add to pathLayer on top of image.
            imageView.layer.addSublayer(circleLayer)
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
        
        // Change the size to make it square.
        let diff = abs(rect.size.height - rect.size.width)
        if rect.size.width > rect.size.height {
            rect.size.height = rect.size.width
            rect.origin.y = rect.origin.y + (diff / 2)
        } else {
            rect.size.width = rect.size.height
            rect.origin.x = rect.origin.x - (diff / 2)
        }
        
        return rect
    }
    
    private static func shapeLayer(color: UIColor, frame: CGRect) -> CAShapeLayer {
        // Create a new layer.
        let layer = CAShapeLayer()
        
        // Configure layer's appearance.
        layer.fillColor = nil // No fill to show boxed object
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.borderWidth = 3.0
        
        // Vary the line color according to input.
        layer.borderColor = color.cgColor
        
        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true
        
        // Corner radius
        let cornerRadius = frame.width > frame.height ? frame.width / 2 : frame.height / 2
        layer.cornerRadius = cornerRadius
        
        // Add CAAnimationGroup.
        layer.add(contentsScaleAnimationGroup(toRect: layer.frame), forKey: "contentsScaleAnimationGroup")
        
        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)
        return layer
    }
    
    /// Animation
    private static func contentsScaleAnimationGroup(toRect: CGRect) -> CAAnimationGroup {
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 10.0
        scaleAnimation.toValue = 0.8
        
        let positionAnimation = CABasicAnimation(keyPath: "position")
        positionAnimation.duration = 10.0
        positionAnimation.toValue = NSValue(cgPoint: .init(x: toRect.width, y: toRect.height))
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, positionAnimation]
        animationGroup.repeatCount = .infinity
        animationGroup.autoreverses = true
        return animationGroup
    }
}
