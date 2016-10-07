//
//  InupiaqKeyboard.swift
//
//  Created by Grant Magdanz on 9/24/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

import UIKit

class InupiaqKeyboard: KeyboardViewController {
    
    private let VOWELS = "aąäą̈a̱eęëę̈iįïoǫųüǫuųüų̈ʉu̱"
    
    let takeDebugScreenshot: Bool = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        UserDefaults.standard
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func keyPressed(_ key: Key) {
        let textDocumentProxy = self.textDocumentProxy
        let keyOutput = key.outputForCase(self.shiftState.uppercase())
        
        if key.type == .Character || key.type == .SpecialCharacter {
            // Type the character, unless the character is an accent and the letter before is not a vowel.
            if let context = textDocumentProxy.documentContextBeforeInput {
                let lastLetter = String(context[context.index(before: context.endIndex)]).lowercased()
                if key.isAccent() && VOWELS.range(of: lastLetter) == nil {
                    return
                }
            }
        }
        textDocumentProxy.insertText(keyOutput)
    }
    
    // This gets called when a long-hold key pop-up gets pressed
    override func hideExpandView(_ notification: Notification) {
        if (notification as NSNotification).userInfo != nil {
            let title = (notification as NSNotification).userInfo!["text"] as! String
            
            let key = Key(.Character)
            key.setLetter(title)
            
            self.keyPressed(key)
            
            self.setCapsIfNeeded()
        }
        viewLongPopUp.isHidden = true
    }
    
    override func setupKeys() {
        super.setupKeys()
        
        if takeDebugScreenshot {
            if self.layout == nil {
                return
            }
            
            for page in keyboard.pages {
                for rowKeys in page.rows {
                    for key in rowKeys {
                        if let keyView = self.layout!.viewForKey(key) {
                            keyView.addTarget(self, action: "takeScreenshotDelay", for: .touchDown)
                        }
                    }
                }
            }
        }
    }
    
    override func createBanner() -> ExtraView? {
        return Banner(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
    }
}
