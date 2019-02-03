//
//  IndicatorPresenter.swift
//  VisionRectangleDetection
//
//  Created by YukiOkudera on 2019/02/03.
//  Copyright © 2019 Yuki Okudera. All rights reserved.
//

import UIKit

protocol IndicatorPresenter {
    /// インジケータ
    var activityIndicator: UIActivityIndicatorView { get }
    /// インジケータを表示する
    func showIndicator()
    /// インジケータを非表示にする
    func hideIndicator()
}
extension IndicatorPresenter where Self: UIViewController {
    
    func showIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.activityIndicator.style = .whiteLarge
            weakSelf.activityIndicator.color = #colorLiteral(red: 0.2722781003, green: 0.2722781003, blue: 0.2722781003, alpha: 1)
            weakSelf.activityIndicator.frame = CGRect(
                x: 0,
                y: 0,
                width: weakSelf.view.bounds.size.width * 0.1,
                height: weakSelf.view.bounds.size.width * 0.1
            )
            weakSelf.activityIndicator.center = CGPoint(
                x: weakSelf.view.bounds.size.width / 2,
                y: weakSelf.view.bounds.height / 2
            )
            weakSelf.view.addSubview(weakSelf.activityIndicator)
            weakSelf.activityIndicator.startAnimating()
        }
    }
    
    func hideIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.activityIndicator.stopAnimating()
            weakSelf.activityIndicator.removeFromSuperview()
        }
    }
}
