//
//  AboutViewController.swift
//  SnapBoard
//
//  Created by Grant Magdanz on 10/10/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidHide"), name: UIKeyboardDidHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidChangeFrame:"), name: UIKeyboardDidChangeFrameNotification, object: nil)
        */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

