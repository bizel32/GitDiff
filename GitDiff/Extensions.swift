//
//  Extensions.swift
//  GitDiff
//
//  Created by Jonathan Brower on 6/23/17.
//  Copyright © 2017 Jonathan Brower. All rights reserved.
//

import Foundation
import UIKit

var loadingAlert = UIAlertController()
var loadingIndicator = UIImageView()
var alertOnVC = UIViewController()
var alertShowing = Bool()

extension UIImageView {
    func rotate(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2.0)
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        
        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = delegate as? CAAnimationDelegate
        }
        self.layer.add(rotateAnimation, forKey: nil)
    }
}

extension UIViewController {
    func showLoading(viewCon: UIViewController) {
        loadingIndicator = UIImageView(image: UIImage(named: "LogoNoBG")!)
        loadingIndicator.frame = CGRect(x: 10, y: 5, width: 50, height: 50)
        loadingAlert = UIAlertController(title: nil, message: "Loading...", preferredStyle: .alert)
        loadingAlert.view.addSubview(loadingIndicator)
        viewCon.present(loadingAlert, animated: true, completion: showLoadingCompletion)
        alertOnVC = viewCon
    }
    
    func dismissLoading() {
        while !alertShowing {
            //Waiting for alert to to hit completion function to prevent undismissable loadAlert
        }
        loadingAlert.dismiss(animated: true, completion: nil)
        alertShowing = false
    }
    
    private func showLoadingCompletion() {
        loadingIndicator.rotate()
        alertShowing = true
    }
}
