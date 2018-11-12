//
//  CardCell.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/12.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit

final class CardCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

extension CardCell: NibRegistrable {}
