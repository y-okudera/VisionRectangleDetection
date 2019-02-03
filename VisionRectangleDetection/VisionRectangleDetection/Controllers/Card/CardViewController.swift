//
//  CardViewController.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2018/11/12.
//  Copyright © 2018 Yuki Okudera. All rights reserved.
//

import UIKit
import Vision

final class CardViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!
    private var image: UIImage!
    private var correctedImageArray = [UIImage]()
    
    // MARK: - Factory
    
    class func instance(images: [UIImage]) -> CardViewController {
        
        let storyboard = UIStoryboard(name: className, bundle: Bundle(for: self))
        let vc = storyboard.instantiateViewController(withIdentifier: className)
        guard let cardViewController = vc as? CardViewController else {
            fatalError("CardViewController is nil.")
        }
        cardViewController.correctedImageArray = images
        return cardViewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CardCell.register(collectionView: collectionView)
    }
}

// MARK: - UICollectionViewDataSource
extension CardViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return correctedImageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCell.identifier,
                                                      for: indexPath) as! CardCell
        cell.imageView.image = correctedImageArray[indexPath.item]
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CardViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let height = width * 3 / 4
        return CGSize(width: width, height: height)
    }
}
