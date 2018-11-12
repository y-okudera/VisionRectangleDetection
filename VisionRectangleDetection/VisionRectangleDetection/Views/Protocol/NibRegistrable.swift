//
//  NibRegistrable.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/11.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit

protocol NibRegistrable {
    
    static var identifier: String { get }
    
    /// CollectionViewにNibを登録する
    ///
    /// - Parameter collectionView: 登録先のCollectionView
    static func register(collectionView: UICollectionView)
}

extension NibRegistrable where Self: UICollectionViewCell {
    
    static var identifier: String {
        return String(describing: self)
    }
    
    static func register(collectionView: UICollectionView) {
        collectionView.register(
            UINib(nibName: identifier, bundle: Bundle(for: self)),
            forCellWithReuseIdentifier: identifier
        )
    }
}
