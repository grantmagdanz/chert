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
    case disabled
    case enabled
    case locked
    
    func uppercase() -> Bool {
        switch self {
        case .disabled:
            return false
        case .enabled:
            return true
        case .locked:
            return true
        }
    }
}

class Keyboard {
    let PLACEHOLDER = "___"
    var pages: [Page]
    
    init() {
        self.pages = []
    }
    
    func addKey(_ key: Key, row: Int, page: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }
        
        self.pages[page].addKey(key, row: row)
    }
    
    func placeKey(_ key: Key, row: Int, page: Int, col: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }
        
        self.pages[page].placeKey(key, row: row, col: col)
    }
    
    // removes all instances PLACEHOLDER in the keyboard
    func removePlaceHolder() {
        for page in self.pages {
            for (i, row) in page.rows.enumerated() {
                for key in row {
                    if key.outputForCase(false) == PLACEHOLDER {
                        page.rows[i] = row.filter({$0.outputForCase(false) != PLACEHOLDER})
                    }
                }
            }
        }
    }
    
    func getKey(_ outputForKey: String) -> Key? {
        for page in self.pages {
            for row in page.rows {
                for key in row {
                    if key.outputForCase(false) == outputForKey.lowercased() {
                        return key
                    }
                }
            }
        }
        return nil
    }
    
    func getLongHoldKeys() -> Set<String> {
        var keys = Set<String>()
        for page in self.pages {
            for row in page.rows {
                for key in row {
                    if key.isLongHold() {
                        keys.insert(key.outputForCase(false))
                    }
                }
            }
        }
        return keys
    }
}

class Page {
    var rows: [[Key]]
    
    init() {
        self.rows = []
    }
    
    func addKey(_ key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }

        self.rows[row].append(key)
    }
    
    
    func placeKey(_ key: Key, row: Int, col: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }
        
        self.rows[row].insert(key, at: col)
    }
}

class Key: Hashable {
    static let LINGIT_SLASHED_O = "∅"
    
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
    
    func setExtraCharacters(_ letters: [String]) {
        self.extraCharacters = []
        self.uppercaseExtraCharacters = []
        for letter in letters {
            self.extraCharacters.append((letter as NSString).lowercased)
            self.uppercaseExtraCharacters.append((letter as NSString).uppercased)
        }
    }
    
    // appends extra letters to key, doesn't include duplicates
    func appendExtraCharacters(_ letters: [String]) {
        for var letter in letters {
            letter = convertAccents(letter)
            if (!self.extraCharacters.contains(letter.lowercased())) {
                self.extraCharacters.append((letter as NSString).lowercased)
                self.uppercaseExtraCharacters.append((letter as NSString).uppercased)
            }
        }
    }
    
    func getExtraCharacters() -> [String] {
        return self.extraCharacters;
    }
    
    func hasExtraCharacters() -> Bool {
        return getExtraCharacters().count > 0
    }
    
    func setLetter(_ input: String) {
        let letter = convertAccents(input)
        self.lowercaseOutput = (letter as NSString).lowercased
        self.uppercaseOutput = (letter as NSString).uppercased
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }
    
    fileprivate func convertAccents(_ input: String) -> String {
        var letter = input
        if input.uppercased() == "ACUTE" {
            letter = "\u{0301}"
        } else if input.uppercased() == "CIRCUMFLEX" {
            letter = "\u{0302}"
        } else if input.uppercased() == "GRAVE" {
            letter = "\u{0300}"
        } else if input.uppercased() == "CARON" {
            letter = "\u{030C}"
        } else if input.uppercased() == "DOUBLE_ACUTE" {
            letter = "\u{030B}"
        }
        return letter
    }
    
    func isAccent() -> Bool {
        return self.uppercaseOutput == "\u{0301}" ||
            self.uppercaseOutput == "\u{0302}" ||
            self.uppercaseOutput == "\u{0300}" ||
            self.uppercaseOutput == "\u{030C}" ||
            self.uppercaseOutput == "\u{030B}"
    }
    
    func isLongHold() -> Bool {
        return self.extraCharacters.count > 1
    }
    
    func outputForCase(_ uppercase: Bool) -> String {
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
    
    func keyCapForCase(_ uppercase: Bool) -> String {
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
