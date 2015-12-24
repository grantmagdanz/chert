//
//  KeyboardModel.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import Foundation

var counter = 0

enum ShiftState {
    case Disabled
    case Enabled
    case Locked
    
    func uppercase() -> Bool {
        switch self {
        case Disabled:
            return false
        case Enabled:
            return true
        case Locked:
            return true
        }
    }
}

class Keyboard {
    var pages: [Page]
    
    init() {
        self.pages = []
    }
    
    func addKey(key: Key, row: Int, page: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }
        
        self.pages[page].addKey(key, row: row)
    }
}

class Page {
    var rows: [[Key]]
    
    init() {
        self.rows = []
    }
    
    func addKey(key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }

        self.rows[row].append(key)
    }
}

class Key: Hashable {
    enum KeyType: String {
        case Character = "Character"
        case SpecialCharacter = "SpecialCharacter"
        case Shift = "Shift"
        case Backspace = "Backspace"
        case LetterChange = "ABC"
        case NumberChange = "123"
        case SpecialCharacterChange = "#+="
        case KeyboardChange = "KeyboardChange"
        case Period = "Period"
        case Space = "Space"
        case Return = "Return"
        case Settings = "Settings"
        case Other = "Other"
    }
    
    var type: KeyType
    var uppercaseKeyCap: String?
    var lowercaseKeyCap: String?
    var uppercaseOutput: String?
    var lowercaseOutput: String?
    var extraCharacters: [String] = []
    var uppercaseExtraCharacters: [String] = []
    var toMode: Int? //if the key is a mode button, this indicates which page it links to
    
    var isCharacter: Bool {
        get {
            switch self.type {
            case
            .Character,
            .SpecialCharacter,
            .Period:
                return true
            default:
                return false
            }
        }
    }
    
    var isSpecial: Bool {
        get {
            switch self.type {
            case .Shift:
                return true
            case .Backspace:
                return true
            case .LetterChange:
                return true
            case .NumberChange:
                return true
            case .SpecialCharacterChange:
                return true
            case .KeyboardChange:
                return true
            case .Return:
                return true
            case .Settings:
                return true
            default:
                return false
            }
        }
    }
    
    var hasOutput: Bool {
        get {
            return (self.uppercaseOutput != nil) || (self.lowercaseOutput != nil)
        }
    }
    
    // TODO: this is kind of a hack
    var hashValue: Int
    
    init(_ type: KeyType) {
        self.type = type
        self.hashValue = counter
        counter += 1
    }
    
    convenience init(_ key: Key) {
        self.init(key.type)
        
        self.uppercaseKeyCap = key.uppercaseKeyCap
        self.lowercaseKeyCap = key.lowercaseKeyCap
        self.uppercaseOutput = key.uppercaseOutput
        self.lowercaseOutput = key.lowercaseOutput
        self.toMode = key.toMode
    }
    
    func setExtraLetters(letters: [String]) {
        for letter in letters {
            self.extraCharacters.append((letter as NSString).lowercaseString)
            self.uppercaseExtraCharacters.append((letter as NSString).uppercaseString)
        }
    }
    
    func setLetter(letter: String) {
        self.lowercaseOutput = (letter as NSString).lowercaseString
        self.uppercaseOutput = (letter as NSString).uppercaseString
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }
    
    func outputForCase(uppercase: Bool) -> String {
        if uppercase {
            if self.uppercaseOutput != nil {
                return self.uppercaseOutput!
            }
            else if self.lowercaseOutput != nil {
                return self.lowercaseOutput!
            }
            else {
                return ""
            }
        }
        else {
            if self.lowercaseOutput != nil {
                return self.lowercaseOutput!
            }
            else if self.uppercaseOutput != nil {
                return self.uppercaseOutput!
            }
            else {
                return ""
            }
        }
    }
    
    func keyCapForCase(uppercase: Bool) -> String {
        if uppercase {
            if self.uppercaseKeyCap != nil {
                return self.uppercaseKeyCap!
            }
            else if self.lowercaseKeyCap != nil {
                return self.lowercaseKeyCap!
            }
            else {
                return ""
            }
        }
        else {
            if self.lowercaseKeyCap != nil {
                return self.lowercaseKeyCap!
            }
            else if self.uppercaseKeyCap != nil {
                return self.uppercaseKeyCap!
            }
            else {
                return ""
            }
        }
    }
}

func ==(lhs: Key, rhs: Key) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
