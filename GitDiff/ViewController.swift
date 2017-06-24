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
        
    var navTitle = String()
    var negStr = String()
    var posStr = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        negTextView.delegate = self
        posTextView.delegate = self
        let negArray = negStr.components(separatedBy: CharacterSet.newlines)
        let posArray = posStr.components(separatedBy: CharacterSet.newlines)
        negTextView.text = negStr
        posTextView.text = posStr
        let negAttributedText = NSMutableAttributedString.init(string: negStr)
        let posAttributedText = NSMutableAttributedString.init(string: posStr)
        
        for n in 0...negArray.count-1 {
            if negArray[n].range(of: "     -") != nil {
                let range = (negStr as NSString).range(of: negArray[n])
                negAttributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.red , range: range)
            }
        }
        negTextView.attributedText = negAttributedText
        for n in 0...posArray.count-1 {
            if posArray[n].range(of: "     +") != nil {
                let range = (posStr as NSString).range(of: posArray[n])
                posAttributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.green , range: range)
            }
        }
        posTextView.attributedText = posAttributedText
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

class inputViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var ownerTextField: UITextField!
    @IBOutlet weak var repoTextField: UITextField!
    @IBOutlet weak var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ownerTextField.delegate = self
        repoTextField.delegate = self
        ownerTextField.tag = 1
        repoTextField.tag = 2
        goButton.addTarget(self, action: #selector(self.goButtonTapped(_:)), for: .touchDown)
        self.navigationItem.title = "GitDiff"

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 1 {
            textField.resignFirstResponder()
            repoTextField.becomeFirstResponder()
        } else if textField.tag == 2 {
            goButtonTapped(goButton)
        }
        textField.resignFirstResponder()
        return true
    }
    
    func goButtonTapped(_ button: UIButton) {
        self.performSegue(withIdentifier: "inputToPullRequests", sender: goButton)
    }
    
    //Handle segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "inputToPullRequests") {
            let controller = (segue.destination as! pullRequestTableViewController)
            controller.prTitleArray = [String]()
            controller.prDescriptionArray = [String]()
            controller.prDiffUrlArray = [String]()
            controller.owner = ownerTextField.text!
            controller.repo = repoTextField.text!
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }

}

