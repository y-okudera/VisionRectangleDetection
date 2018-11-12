//
//  NSObject+ClassName.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/11.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import Foundation

extension NSObject {
    
    /// クラス名を取得する
    static var className: String {
        return String(describing: self)
    }
    
    /// クラス名を取得する
    var className: String {
        return String(describing: type(of: self))
    }
}
