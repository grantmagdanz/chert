//
//  DefaultKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Updated by Grant Magdanz on 9/24/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

import Foundation

func buildKeyboard() -> Keyboard {
    let keyboard = defaultKeyboard()

    let defaults = UserDefaults.standard
    for language in Languages.getLanguages() {
        if defaults.bool(forKey: language) {
            // the user has selected this language, let's add it in!
            var keys: NSDictionary?
            if let path = Bundle.main.path(forResource: language, ofType: "plist") {
                keys = NSDictionary(contentsOfFile: path)
            }
            if let keyBindings = keys {
                for (char, extras) in keyBindings {
                    if let key = keyboard.getKey(char as! String) {
                        key.appendExtraCharacters(extras as! [String])
                    } else {
                        // this key does not exist on a normal keyboard, so we will add a new key
                        // Tlingit's square root symbol is an example of this.
                        let keyModel = makeKey(char as! String, special: false)
                        
                        if char as! String == "√" {
                            // place the key in between the ? key and ! key on the page with extra special characters
                            keyboard.placeKey(keyModel, row: 2, page: 2, col: keyboard.pages[1].rows[2].count - 3)
                        } else {
                            print("Char \(char) isn't on a normal keyboard and needs a place.")
                        }
                    }
                }
            }
        }
    }
    
    // If the placeholder isn't storing something, we want to get rid of it.
    if let placeholder = keyboard.getKey(keyboard.PLACEHOLDER) {
        var extraChars = placeholder.getExtraCharacters()
        if extraChars.count > 1 {
            // it has something! Let's get rid of the PLACEHOLDER though, then set the key up.
            extraChars = extraChars.filter({$0 != keyboard.PLACEHOLDER})
            
            // In this app, the placeholder is being used for accents and they should be in a specific order.
            extraChars = extraChars.sorted {
                if $0 == "\u{0301}" { // accent acute should be first
                    return true
                } else if $0 == "\u{0300}" && $1 != "\u{0301}" { // followed by accent grave
                    return true
                } else if $0 == "\u{0302}" && $1 != "\u{0301}" && $1 != "\u{0300}" { // then circumflex
                    return true
                } else if $0 == "\u{030C}" && $1 != "\u{0302}" && $1 != "\u{0301}" && $1 != "\u{0300}" { // then caron
                    return true
                } else {
                    return false // and finally double acute
                }
            }
            
            
            placeholder.setLetter(extraChars[0])
            placeholder.setExtraCharacters(extraChars)
        } else {
            keyboard.removePlaceHolder()
        }
    }
    
    return keyboard
}

func defaultKeyboard() -> Keyboard {
    let defaultKeyboard = Keyboard()
    
    for pageNum in 0...2 {
        for rowNum in 0...3 {
            let row = NSLocalizedString("page\(pageNum)_row\(rowNum)", comment: "Row number\(rowNum) in page \(pageNum)").characters.split{$0 == " "}.map(String.init)
            for key in row {
                // split on commas to get extra characters for that key
                var charactersForKey = [key];
                if key.characters.count > 1 {
                    charactersForKey = key.characters.split{$0 == ","}.map(String.init)
                }
                let keyModel: Key
                if pageNum == 0 {
                    // the first page contains all the letters which are .Character Keys
                    keyModel = makeKey(charactersForKey[0], special: false)
                } else {
                    // all other characters on other pages are .SpecialCharacter Keys
                    keyModel = makeKey(charactersForKey[0], special: true)
                }
                
                keyModel.extraCharacters = charactersForKey
                defaultKeyboard.addKey(keyModel, row: rowNum, page: pageNum)
            }
        }
    }
    
    return defaultKeyboard
}

/* Given a value of a key, returns a Key object of the correct type.
 */
private func makeKey(_ value: String, special: Bool) -> Key {
    let keyType = Key.KeyType(rawValue: value)
    if keyType == nil {
        // This is not a special key (i.e. it types a character)
        let key: Key
        if !special {
            key = Key(.Character)
        } else {
            key = Key(.SpecialCharacter)
        }
        key.setLetter(value)
        return key
    }
    switch keyType! {
    case .LetterChange:
        let key = Key(.LetterChange)
        key.uppercaseKeyCap = NSLocalizedString("alphabet_change", comment: "The label of the button to switch to letters.")
        key.toMode = 0
        return key
    case .NumberChange:
       let key = Key(.NumberChange)
       key.uppercaseKeyCap = NSLocalizedString("number_change", comment: "The label of the button to switch to numbers and symbols.")
       key.toMode = 1
       return key;
    case .SpecialCharacterChange:
        let key = Key(.SpecialCharacterChange)
        key.uppercaseKeyCap = NSLocalizedString("symbol_change", comment: "The label of the button to switch to extra symbols.")
        key.toMode = 2
        return key
    case .Space:
        let key = Key(.Space)
        key.uppercaseKeyCap = NSLocalizedString("space", comment: "The label of the space button.")
        key.uppercaseOutput = " "
        key.lowercaseOutput = " "
        return key
    case .Return:
        let key = Key(.Return)
        key.uppercaseKeyCap = NSLocalizedString("return", comment: "The label of the return button")
        key.uppercaseOutput = "\n"
        key.lowercaseOutput = "\n"
        return key
    default:
        return Key(keyType!)
    }
}
