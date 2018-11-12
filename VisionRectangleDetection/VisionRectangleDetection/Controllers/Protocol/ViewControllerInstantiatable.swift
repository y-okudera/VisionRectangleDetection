//
//  ViewControllerInstantiatable.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/11.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit

// MARK: - ViewControllerInstantiatable
protocol ViewControllerInstantiatable where Self: UIViewController {}

extension ViewControllerInstantiatable {
    
    static func instantiate(bundle: Bundle? = Bundle(for: Self.self)) -> Self {
        
        let storyboardName = String(describing: self)
        
        guard let vc = UIStoryboard(name: storyboardName, bundle: bundle)
            .instantiateInitialViewController() as? Self else {
                fatalError("vc is nil. Storyboard Name: \(storyboardName)")
        }
        return vc
    }
    
    static func instantiateWithIdentifier(_ identifier: String = String(describing: Self.self),
                                          bundle: Bundle? = Bundle(for: Self.self)) -> Self {
        
        let storyboardName = String(describing: self)
        
        guard let vc = UIStoryboard(name: storyboardName, bundle: bundle)
            .instantiateViewController(withIdentifier: identifier) as? Self else {
                fatalError("vc is nil. Name: \(storyboardName), Identifier: \(identifier)")
        }
        return vc
    }
}
