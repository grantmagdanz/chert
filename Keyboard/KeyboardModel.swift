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
    let PLACEHOLDER = "___"
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
    
    func placeKey(key: Key, row: Int, page: Int, col: Int) {
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
            for (i, row) in page.rows.enumerate() {
                for key in row {
                    if key.outputForCase(false) == PLACEHOLDER {
                        page.rows[i] = row.filter({$0.outputForCase(false) != PLACEHOLDER})
                    }
                }
            }
        }
    }
    
    func getKey(outputForKey: String) -> Key? {
        for page in self.pages {
            for row in page.rows {
                for key in row {
                    if key.outputForCase(false) == outputForKey.lowercaseString {
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
    
    func addKey(key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }

        self.rows[row].append(key)
    }
    
    
    func placeKey(key: Key, row: Int, col: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }
        
        self.rows[row].insert(key, atIndex: col)
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
    
    func setExtraCharacters(letters: [String]) {
        self.extraCharacters = []
        self.uppercaseExtraCharacters = []
        for letter in letters {
            self.extraCharacters.append((letter as NSString).lowercaseString)
            self.uppercaseExtraCharacters.append((letter as NSString).uppercaseString)
        }
    }
    
    // appends extra letters to key, doesn't include duplicates
    func appendExtraCharacters(letters: [String]) {
        for var letter in letters {
            letter = convertAccents(letter)
            if (!self.extraCharacters.contains(letter.lowercaseString)) {
                self.extraCharacters.append((letter as NSString).lowercaseString)
                self.uppercaseExtraCharacters.append((letter as NSString).uppercaseString)
            }
        }
    }
    
    func getExtraCharacters() -> [String] {
        return self.extraCharacters;
    }
    
    func hasExtraCharacters() -> Bool {
        return getExtraCharacters().count > 0
    }
    
    func setLetter(input: String) {
        let letter = convertAccents(input)
        self.lowercaseOutput = (letter as NSString).lowercaseString
        self.uppercaseOutput = (letter as NSString).uppercaseString
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }
    
    private func convertAccents(input: String) -> String {
        var letter = input
        if input.uppercaseString == "ACUTE" {
            letter = "\u{0301}"
        } else if input.uppercaseString == "CIRCUMFLEX" {
            letter = "\u{0302}"
        } else if input.uppercaseString == "GRAVE" {
            letter = "\u{0300}"
        } else if input.uppercaseString == "CARON" {
            letter = "\u{030C}"
        }
        return letter
    }
    
    func isLongHold() -> Bool {
        return self.extraCharacters.count > 1
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
