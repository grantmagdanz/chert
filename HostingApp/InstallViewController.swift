//
//  InstallViewController.swift
//  InupiaqKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Updated by Grant Magdanz on 9/24/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

import UIKit

class InstallViewController: UIViewController {
    @IBOutlet var instructionView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        instructionView.scrollEnabled = false
        
        
        /* NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidHide"), name: UIKeyboardDidHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidChangeFrame:"), name: UIKeyboardDidChangeFrameNotification, object: nil)
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func dismiss() {
        for view in self.view.subviews {
            if let inputView = view as? UITextField {
                inputView.resignFirstResponder()
            }
        }
    }
    
    /* func keyboardWillShow() {
        // intentionally empty
    }
    
    func keyboardDidHide() {
        // intentionally empty
    }
    
    func keyboardDidChangeFrame(notification: NSNotification) {
        // intentionally empty
    }*/
}

