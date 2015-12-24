//
//  DefaultKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Updated by Grant Magdanz on 9/24/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

import Foundation

func defaultKeyboard() -> Keyboard {
    let defaultKeyboard = Keyboard()
    
    for pageNum in 0...2 {
        for rowNum in 0...3 {
            let row = NSLocalizedString("page\(pageNum)_row\(rowNum)", comment: "Row number\(rowNum) in page \(pageNum)").characters.split{$0 == " "}.map(String.init)
            for key in row {
                let keyModel: Key
                if pageNum == 0 {
                    // the first page contains all the letters which are .Character Keys
                    keyModel = makeKey(key, special: false)
                } else {
                    // all other characters on other pages are .SpecialCharacter Keys
                    keyModel = makeKey(key, special: true)
                }
                defaultKeyboard.addKey(keyModel, row: rowNum, page: pageNum)
            }
        }
    }
    /*let topRow = NSLocalizedString("page0_row0", comment: "The top row of the keyboard.").characters.split{$0 == " "}.map(String.init)
    
    for key in topRow {
        let keyModel = makeKey(key);
        defaultKeyboard.addKey(keyModel, row: 0, page: 0)
    }
    
    let middleTopRow = NSLocalizedString("page0_row1", comment: "The second row of the keyboard.").characters.split{$0 == " "}.map(String.init)
    
    for key in middleTopRow {
        let keyModel = makeKey(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 0)
    }
    
    let keyModel = Key(.Shift)
    defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    
    let middleBottomRow = NSLocalizedString("page0_row2", comment: "The third row of the keybaord.").characters.split{$0 == " "}.map(String.init)
    
    for key in middleBottomRow {
        let keyModel = makeKey(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    }
    
    let bottomRow = NSLocalizedString("page0_row3", comment: "The bottom row of the keyboard.").characters.split{$0 == " "}.map(String.init)
    
    for key in bottomRow {
        let keyModel = makeKey(key)
        defaultKeyboard.addKey(keyModel, row: 3, page: 0)
    }
    let backspace = Key(.Backspace)
    defaultKeyboard.addKey(backspace, row: 2, page: 0)
    
    let keyModeChangeNumbers = Key(.ModeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
    
    let keyboardChange = Key(.KeyboardChange)
    defaultKeyboard.addKey(keyboardChange, row: 3, page: 0)
    
    let settings = Key(.Settings)
    defaultKeyboard.addKey(settings, row: 3, page: 0)
    
    let space = Key(.Space)
    space.uppercaseKeyCap = "space"
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    defaultKeyboard.addKey(space, row: 3, page: 0)
    
    let returnKey = Key(.Return)
    returnKey.uppercaseKeyCap = "return"
    returnKey.uppercaseOutput = "\u{200B}\n"
    returnKey.lowercaseOutput = "\u{200B}\n"
    defaultKeyboard.addKey(returnKey, row: 3, page: 0)
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    let keyModeChangeSpecialCharacters = Key(.SpecialCharacterChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'"] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 1)
    
    let keyModeChangeLetters = Key(.LetterChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(settings), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 1)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'"] {
        let keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    defaultKeyboard.addKey(Key(backspace), row: 2, page: 2)
    
    defaultKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(settings), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(space), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(returnKey), row: 3, page: 2)*/
    
    return defaultKeyboard
}

/* Given a value of a key, returns a Key object of the correct type.
 */
private func makeKey(let value: String, let special: Bool) -> Key {
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
        key.uppercaseOutput = "\u{200B}\n"
        key.lowercaseOutput = "\u{200B}\n"
        return key
    default:
        return Key(keyType!)
    }
}
