//
//  ViewController.swift
//  GitDiff
//
//  Created by Jonathan Brower on 6/21/17.
//  Copyright © 2017 Jonathan Brower. All rights reserved.
//

import UIKit

class differencesViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var negTextView: UITextView!
    @IBOutlet weak var posTextView: UITextView!
        
    var negStr = String()
    var posStr = String()
    var navTitle = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        negTextView.delegate = self
        posTextView.delegate = self
        negTextView.text = negStr
        posTextView.text = posStr
        self.navigationItem.title = navTitle
        negTextView.layer.borderColor = UIColor.red.cgColor
        negTextView.layer.borderWidth = 1.5;
        posTextView.layer.borderColor = UIColor.green.cgColor
        posTextView.layer.borderWidth = 1.5;
    }
    
    //To sure you start at the top
    override func viewDidLayoutSubviews() {
        negTextView.contentOffset = CGPoint.zero
        posTextView.contentOffset = CGPoint.zero
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

